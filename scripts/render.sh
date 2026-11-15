#!/bin/sh
# Renders Casks/noido-snapshot.rb from one releases.atom file.
#
# usage: scripts/render.sh FEED SHADIR OUT
#
# FEED   a noido releases.atom, as GitHub serves it
# SHADIR a directory holding <asset>.sha256 for the two app bundles
# OUT    the cask to write; left alone when it already holds this or a
#        newer version, and never written when anything is missing
set -eu

feed=$1
shadir=$2
out=$3
here=$(cd "$(dirname "$0")/.." && pwd)
template="$here/Casks/noido-snapshot.rb.in"

die() {
    echo "render: $*" >&2
    exit 1
}

[ -f "$feed" ] || die "no feed at $feed"
[ -f "$template" ] || die "no template at $template"

# Highest stamp wins. Fixed-width stamps sort lexicographically, and one tag
# appears several times in its entry (id, href, title, body), so unique first.
tag=$(grep -o 'snapshot-[0-9]\{8\}-[0-9]\{4,6\}-[0-9a-f]\{8\}' "$feed" | sort -u | tail -1)
[ -n "$tag" ] || die "no snapshot tag in $feed"

stamp=${tag#snapshot-}
stamp=${stamp%-*}
commit=${tag##*-}

# The release body names the assets; nothing here constructs them, because
# the version inside the name carries the crate version.
url_of() {
    target=$1
    grep -o "https://github.com/[A-Za-z0-9._-]*/[A-Za-z0-9._-]*/releases/download/$tag/noido-$target-[^\"<>[:space:]]*\.app\.zip" "$feed" \
        | head -1
}

url_arm=$(url_of aarch64-apple-darwin)
url_intel=$(url_of x86_64-apple-darwin)
[ -n "$url_arm" ] || die "release $tag names no aarch64 app bundle"
[ -n "$url_intel" ] || die "release $tag names no x86_64 app bundle"

# `0.1.0+<commit>` from the asset name, so a workspace version bump flows
# through without editing anything here.
asset_version() {
    basename "$1" | sed "s|^noido-$2-||; s|\.app\.zip\$||"
}
version_prefix=$(asset_version "$url_arm" aarch64-apple-darwin)
version_prefix=${version_prefix%%+*}
[ -n "$version_prefix" ] || die "cannot read the version out of $url_arm"
version="$version_prefix+$stamp-$commit"

digest_of() {
    name=$(basename "$1")
    file="$shadir/$name.sha256"
    [ -f "$file" ] || die "no checksum at $file"
    digest=$(awk 'NR == 1 { print $1 }' "$file")
    case "$digest" in
        "" | *[!0-9a-fA-F]*) die "$file: not a sha256 digest: '$digest'" ;;
    esac
    [ ${#digest} -eq 64 ] || die "$file: not a sha256 digest: '$digest'"
    case "$(cat "$file")" in
        *"$name"*) ;;
        *) die "$file does not name $name" ;;
    esac
    echo "$digest"
}

sha_arm=$(digest_of "$url_arm")
sha_intel=$(digest_of "$url_intel")

# Write only when the candidate is newer than what OUT already carries. brew
# never downgrades, so a backwards step would stall `brew upgrade` silently.
candidate="$stamp-$commit"
if [ -f "$out" ]; then
    current=$(sed -n 's/^  version "\(.*\)"$/\1/p' "$out" | head -1)
    if [ -n "$current" ]; then
        current_key=${current#*+}
        newest=$(printf '%s\n%s\n' "$candidate" "$current_key" | sort | tail -1)
        # Equal counts as "no change": a re-run must not touch the file.
        if [ "$newest" = "$current_key" ]; then
            echo "no change: $out already has $current"
            exit 0
        fi
    fi
fi

tmp="$out.tmp.$$"
trap 'rm -f "$tmp"' EXIT INT TERM
sed -e "s|{{version}}|$version|g" \
    -e "s|{{url_arm}}|$url_arm|g" \
    -e "s|{{url_intel}}|$url_intel|g" \
    -e "s|{{sha_arm}}|$sha_arm|g" \
    -e "s|{{sha_intel}}|$sha_intel|g" \
    "$template" >"$tmp"
mv "$tmp" "$out"
echo "$out: $version"
