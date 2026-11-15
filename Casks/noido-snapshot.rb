cask "noido-snapshot" do
  version "0.1.0+20261115-213110-330c6122"

  on_macos do
    on_arm do
      sha256 "2413481f28a85741c672c456db43e1a5c71f417d1e0c33e244cc7bbbfb49ab9d"
      url "https://github.com/rikardg/noido/releases/download/snapshot-20261115-213110-330c6122/noido-aarch64-apple-darwin-0.1.0+330c6122.app.zip"
    end

    on_intel do
      sha256 "7ef1bc1dd172eb8b10b566eadbc51eb6c5ef340eac5eea5404f30207b64c6e14"
      url "https://github.com/rikardg/noido/releases/download/snapshot-20261115-213110-330c6122/noido-x86_64-apple-darwin-0.1.0+330c6122.app.zip"
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
