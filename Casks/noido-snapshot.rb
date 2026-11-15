cask "noido-snapshot" do
  version "0.1.0+20261115-162703-330c6122"

  on_macos do
    on_arm do
      sha256 "691d8bfb8a202001e5c926616e3a6edb98455121dddf5e6b7780893b15458a9c"
      url "https://github.com/rikardg/noido/releases/download/snapshot-20261115-162703-330c6122/noido-aarch64-apple-darwin-0.1.0+330c6122.app.zip"
    end

    on_intel do
      sha256 "8594e0b16c0754829c09b7bfcadc388ccd39684e4167d0dc69312a8eb5ca3557"
      url "https://github.com/rikardg/noido/releases/download/snapshot-20261115-162703-330c6122/noido-x86_64-apple-darwin-0.1.0+330c6122.app.zip"
    end
  end

  name "noido"
  desc "PDF reader and note taker"
  homepage "https://github.com/rikardg/noido"

  app "noido.app"
  binary "#{appdir}/noido.app/Contents/MacOS/noido"

  # The app is ad-hoc signed and not notarized, so a quarantined copy would
  # hit Gatekeeper on every version. Strip the attribute from the staged
  # tree: no quarantine attribute means no Gatekeeper prompt.
  preflight_steps do
    run "/usr/bin/xattr", args: ["-r", "-d", "com.apple.quarantine", "{{staged_path}}"]
  end
end
