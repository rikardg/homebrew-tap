cask "noido-snapshot" do
  version "0.1.0+20261115-222903-330c6122"

  on_macos do
    on_arm do
      sha256 "d68c3bd33c649a30ab1a862780402108df9ed908dbf78aad1bcc7175297908f1"
      url "https://github.com/rikardg/noido/releases/download/snapshot-20261115-222903-330c6122/noido-aarch64-apple-darwin-0.1.0+330c6122.app.zip"
    end

    on_intel do
      sha256 "bf7be18ad9d161c9c9b510b39998eba46ea2068fc7500bc9568d21959afef911"
      url "https://github.com/rikardg/noido/releases/download/snapshot-20261115-222903-330c6122/noido-x86_64-apple-darwin-0.1.0+330c6122.app.zip"
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
