---
title: Install
description: Download Dropline for macOS, get past Gatekeeper on first launch, enable the Finder extension, and understand how updates arrive.
---

# Install

Dropline runs on **macOS 13 Ventura or later**. The published build targets
Apple Silicon; on an Intel Mac, [build from
source](/docs/guide/build-from-source) instead.

## Option 1 — the DMG

Download `Dropline.dmg` from the
[latest release](https://github.com/chen86860/dropline/releases/latest), open
it, and drag **Dropline** into your Applications folder.

The release asset carries no version number, so this link always resolves to the
newest stable build:

```text
https://github.com/chen86860/dropline/releases/latest/download/Dropline.dmg
```

## Option 2 — Homebrew

```bash
brew install --cask chen86860/tap/dropline
```

The cask tracks the latest release, so it needs no version number. Homebrew
quarantines what it installs, so the first-launch step below still applies.

## First launch

The build is **ad-hoc signed rather than notarised**, so Gatekeeper blocks the
first launch with a message about the app being damaged or from an unidentified
developer. This is expected, and it happens once.

Either right-click **Dropline** in Applications and choose **Open**, then
confirm — or clear the quarantine flag from Terminal:

```bash
xattr -dr com.apple.quarantine /Applications/Dropline.app
```

After that, Dropline opens normally every time.

## Enable the Finder extension

The top-level **Upload with Dropline** item in the Finder context menu comes
from a system extension, and macOS leaves extensions off until you approve them.

Open **System Settings → General → Login Items & Extensions → Finder
Extensions** and turn **Dropline** on.

The same command also appears under **Keyboard → Keyboard Shortcuts → Services →
Files and Folders**, where you can give it a keyboard shortcut. If you would
rather not have it in the context menu at all, set **Settings → General → Finder
Context Menu → Show as** to *Don't show*; every other way in keeps working.

## Where Dropline lives

Once installed, Dropline is a menu bar app first and a window second.

- The **menu bar icon** offers quick upload and the last five links, and turns
  into a progress ring while an upload runs.
- The **main window** is a drop target with the live queue and history.
- The **Dock icon** is also a drop target, and can be hidden entirely from
  **Settings → General → Hide the Dock icon**.

## Updates

Updates arrive through [Sparkle](https://sparkle-project.org) and are signed
with EdDSA. Dropline checks automatically by default; you can turn that off, or
enable silent download-and-install, under **Settings → General → Software
Update**. Release notes ship in English and Chinese and follow the language you
pick in Settings.

## Uninstall

Drag `Dropline.app` to the Trash. Two things are left behind, both harmless, and
both removable from Terminal:

```bash
# Preferences: host profiles (without secrets), settings, upload history
defaults delete dev.emmmm.Dropline

# Keychain: one entry per host profile, holding its secret
security delete-generic-password -s dev.emmmm.Dropline
```

Run the `security` command once per profile you had configured — it deletes a
single matching item each time.

## Next

[Your first upload →](/docs/getting-started/quickstart)
