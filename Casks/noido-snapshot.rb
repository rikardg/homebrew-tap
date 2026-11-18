cask "noido-snapshot" do
  version "0.1.0+20261118-210439-87f33282"

  on_macos do
    on_arm do
      sha256 "92862d2bcaabbed787e8f42b899eadb8ee877de347e17e81fb00b7d570aa6c4e"
      url "https://github.com/rikardg/noido/releases/download/snapshot-20261118-210439-87f33282/noido-aarch64-apple-darwin-0.1.0+87f33282.app.zip"
    end

    on_intel do
      sha256 "95691867adb5119d15f5c14f9ed8eabd25a45c768956424da15011bfd804efe9"
      url "https://github.com/rikardg/noido/releases/download/snapshot-20261118-210439-87f33282/noido-x86_64-apple-darwin-0.1.0+87f33282.app.zip"
    end
  end

  name "noido"
  desc "PDF reader and note taker"
  homepage "https://github.com/rikardg/noido"

  app "noido.app"
  binary "#{appdir}/noido.app/Contents/MacOS/noido"

  # An upgrade replaces the bundle in place; without this the running app
  # is written over under itself.
  uninstall quit: "io.github.rikardg.noido"

  # The app is ad-hoc signed and not notarized, so a quarantined copy would
  # hit Gatekeeper on every version. Strip the attribute from the staged
  # tree: no quarantine attribute means no Gatekeeper prompt.
  preflight_steps do
    run "/usr/bin/xattr", args: ["-r", "-d", "com.apple.quarantine", "{{staged_path}}"]
  end
end
