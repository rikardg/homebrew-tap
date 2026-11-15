# noido snapshots

A Homebrew cask that installs the newest [noido](https://github.com/rikardg/noido)
**snapshot** on macOS: `noido.app` in `/Applications` plus the `noido`
command.

```
brew install --cask rikardg/tap/noido-snapshot
```

That one command taps `rikardg/tap` and records the trust Homebrew asks of a
third-party tap before it loads the tap's Ruby. Nothing else is needed.

If you prefer to tap first and install by the short name, Homebrew wants the
trust stated explicitly:

```
brew tap rikardg/tap
brew trust --cask rikardg/tap/noido-snapshot
brew install --cask noido-snapshot
```

Update whenever you like:

```
brew upgrade --cask noido-snapshot
```

`brew upgrade` only finds a new snapshot after it has refreshed the tap, which
Homebrew does at most once a day (`HOMEBREW_AUTO_UPDATE_SECS`). Run `brew
update` first if you want the very latest.

## What it is, and what it isn't

A snapshot is a pre-release built from a commit, not a release. The version
reads `0.1.0+YYYYMMDD-HHMMSS-<commit>`, so `brew list --cask --versions`
tells you exactly when and where it came from.

The app is **not notarized** and is signed ad hoc. A browser download of the
same bundle would be blocked by Gatekeeper. This cask removes the
`com.apple.quarantine` attribute from the bundle before installing it, which
is the only reason it opens without a prompt — a deliberate choice, so that
`brew upgrade` is the whole update. If you would rather not run software
this way, build noido from source.

Because of that, the cask lives here and never in `homebrew/cask`, which
requires Apple notarization.

## Updating this cask

`.github/workflows/update.yml` runs hourly: it reads
`https://github.com/rikardg/noido/releases.atom`, takes the newest
`snapshot-*` release, renders `Casks/noido-snapshot.rb` from it and commits
the result. Nothing is pushed from the noido repository, and no secret is
involved.

A public repository's scheduled workflows are disabled after 60 days without
activity. If snapshots stop arriving, open Actions and re-enable the
workflow (or run it by hand).

## Notes

- If you installed noido before with `noido --install`, run
  `noido --uninstall` first: otherwise `~/Applications/noido.app` stays
  registered and "Open With" offers two apps.
- `brew upgrade` prints a "signer changed" warning on every upgrade. It is
  harmless here: the new bundle is unquarantined before it is installed.
- Snapshot builds replace each other; there is no version to pin.
