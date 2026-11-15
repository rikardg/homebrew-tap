#!/bin/sh
# Exercises scripts/render.sh against test/fixtures. No network, no brew.
# Run from anywhere: sh scripts/test.sh
set -eu

here=$(cd "$(dirname "$0")/.." && pwd)
render="$here/scripts/render.sh"
fixtures="$here/test/fixtures"
arm64=$(printf 'a%.0s' $(seq 1 64))
x86_64=$(printf 'b%.0s' $(seq 1 64))
tmp=$(mktemp -d "${TMPDIR:-/tmp}/render-test.XXXXXX")
trap 'rm -rf "$tmp"' EXIT INT TERM

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

# 1. Renders the newest snapshot, chosen by stamp and not by feed order.
out="$tmp/noido-snapshot.rb"
sh "$render" "$fixtures/feed.xml" "$fixtures" "$out" || fail "render exited non-zero"
grep -q 'cask "noido-snapshot" do' "$out" || fail "cask header"
grep -q 'version "0.1.0+20261114-213045-abc12345"' "$out" || fail "version line"
grep -q "url \"https://github.com/rikardg/noido/releases/download/snapshot-20261114-213045-abc12345/noido-aarch64-apple-darwin-0.1.0+abc12345.app.zip\"" "$out" \
    || fail "Apple Silicon url"
grep -q "url \"https://github.com/rikardg/noido/releases/download/snapshot-20261114-213045-abc12345/noido-x86_64-apple-darwin-0.1.0+abc12345.app.zip\"" "$out" \
    || fail "Intel url"
grep -q "sha256 \"$arm64\"" "$out" || fail "Apple Silicon digest"
grep -q "sha256 \"$x86_64\"" "$out" || fail "Intel digest"
grep -q 'app "noido.app"' "$out" || fail "app artifact"
grep -q 'binary "#{appdir}/noido.app/Contents/MacOS/noido"' "$out" || fail "binary artifact"
grep -q 'preflight_steps do' "$out" || fail "preflight block"
grep -q 'com.apple.quarantine' "$out" || fail "quarantine strip"
ruby -c "$out" >/dev/null || fail "rendered cask is not valid Ruby"
grep -q 'ffffffff' "$out" && fail "took the older entry"

# 2. A second run with the same release writes nothing.
before=$(cksum "$out")
sh "$render" "$fixtures/feed.xml" "$fixtures" "$out" >"$tmp/second.log" 2>&1 || fail "second run failed"
[ "$before" = "$(cksum "$out")" ] || fail "second run rewrote the file"
grep -qi 'no change' "$tmp/second.log" || fail "second run should say no change"

# 3. A release body without the bundles fails and writes nothing.
grep -v 'app\.zip' "$fixtures/feed.xml" >"$tmp/no-appzip.xml"
absent="$tmp/absent.rb"
if sh "$render" "$tmp/no-appzip.xml" "$fixtures" "$absent" >"$tmp/third.log" 2>&1; then
    fail "a body without .app.zip should fail"
fi
[ -e "$absent" ] && fail "a failed render must not write the cask"

# 4. A malformed digest fails and writes nothing.
badshas="$tmp/badshas"
mkdir -p "$badshas"
cp "$fixtures"/*.sha256 "$badshas/"
printf 'notadigest  %s\n' "noido-x86_64-apple-darwin-0.1.0+abc12345.app.zip" \
    >"$badshas/noido-x86_64-apple-darwin-0.1.0+abc12345.app.zip.sha256"
if sh "$render" "$fixtures/feed.xml" "$badshas" "$tmp/bad.rb" >"$tmp/fourth.log" 2>&1; then
    fail "a digest that is not 64 hex characters should fail"
fi
[ -e "$tmp/bad.rb" ] && fail "a failed render must not write the cask"

# 5. A minute-resolution tag — what the releases published before the
# seconds change carry — still renders.
sed 's/213045/2130/g' "$fixtures/feed.xml" >"$tmp/minute.xml"
minute="$tmp/minute.rb"
sh "$render" "$tmp/minute.xml" "$fixtures" "$minute" || fail "a minute-resolution tag failed"
grep -q 'version "0.1.0+20261114-2130-abc12345"' "$minute" || fail "minute-resolution version"

# 6. A template change reaches an unchanged release: same version, different
# content, so the cask is rewritten rather than left stale.
printf '\n# a stale line the renderer must replace\n' >>"$out"
sh "$render" "$fixtures/feed.xml" "$fixtures" "$out" >"$tmp/sixth.log" 2>&1 || fail "re-render after an edit failed"
grep -q 'a stale line' "$out" && fail "a stale line survived the re-render"

# 7. An older release must not walk a newer cask backwards: brew never
# downgrades, so writing it would stall `brew upgrade` until the next press.
newer="$tmp/newer.rb"
sh "$render" "$fixtures/feed.xml" "$fixtures" "$newer" >/dev/null
awk 'BEGIN{done=0} /^  version "/ && !done { print "  version \"0.1.0+20261201-000000-deadbeef\""; done=1; next } { print }' \
    "$newer" >"$newer.tmp"
mv "$newer.tmp" "$newer"
before=$(cksum "$newer")
sh "$render" "$fixtures/feed.xml" "$fixtures" "$newer" >"$tmp/seventh.log" 2>&1 || fail "a downgrade attempt should exit 0"
[ "$before" = "$(cksum "$newer")" ] || fail "a downgrade attempt rewrote the cask"
grep -qi 'newer' "$tmp/seventh.log" || fail "a downgrade attempt should say why it did nothing"

# 8. A cask whose version line is gone is a mistake to fix by hand, not to
# overwrite with whatever the feed says.
broken="$tmp/broken.rb"
sh "$render" "$fixtures/feed.xml" "$fixtures" "$broken" >/dev/null
grep -v '^  version "' "$broken" >"$broken.tmp"
mv "$broken.tmp" "$broken"
if sh "$render" "$fixtures/feed.xml" "$fixtures" "$broken" >"$tmp/eighth.log" 2>&1; then
    fail "a cask without a version line should stop the render"
fi

echo "all render tests passed"
