# Changelog

**English** · [简体中文](CHANGELOG.zh-CN.md)

This file is the single source of release notes: `tools/changelog.py` extracts the section for
a version, the release pipeline embeds it into the Sparkle appcast and uses it as the GitHub
release body. [CHANGELOG.zh-CN.md](CHANGELOG.zh-CN.md) holds the Chinese translation, and the
update dialog shows whichever matches the language chosen in Settings.

Before releasing, add a `## [version] - date` section at the top of **both** files — a missing
section aborts the release, and a missing translation means no release notes in that language.

## [1.4.0] - 2026-08-08

### Added

- **Dark mode**: Settings → General → Appearance switches between light and dark, or follows
  the system (the default). Takes effect immediately, no restart needed, and only Dropline is
  affected — the system appearance is left alone. The menu bar icon keeps following the menu
  bar itself, as it should.

### Changed

- **The DMG no longer carries a version number in its filename**, so the release asset name is
  stable and [`Dropline.dmg`](https://github.com/chen86860/dropline/releases/latest/download/Dropline.dmg)
  always points at the newest stable build — the same trick already used for `appcast.xml`.
  The version is still in the volume name and in the app itself. The Sparkle zip keeps its
  version, because `generate_appcast` reads the version from the filename.

### Fixed

- **Uploading from the Finder context menu really does leave the main window alone now.** 1.3.0
  tried to hide the window again after SwiftUI had already put it on screen, which raced and
  could flash or fail outright. The main window is no longer part of the SwiftUI scene tree at
  all: it is created on demand, so a background upload never brings one into existence. Normal
  launches, the Dock icon and "Open Main Window" open it exactly as before.
- A Finder upload whose files had been moved or deleted in the meantime could still pop the
  main window open.

## [1.3.0] - 2026-08-08

### Added

- **English and Chinese UI**: follows the system language by default (Chinese when the system
  is Chinese, English otherwise), and can be switched by hand in Settings → General → Language.
  Takes effect immediately, no restart needed. The Finder context menu and the Services item
  follow along.
- **Switch hosts from the menu bar**: pick the active host profile straight from the menu bar
  item without opening Settings.

### Changed

- **New icon**: the app icon and the menu bar icon now share one upload mark (arrow above a
  baseline). The menu bar icon lost its surrounding circle; while uploading it hides the
  baseline and draws a progress ring instead.
- **Settings rearranged**: General moved first; the Finder context menu setting moved into it
  and the separate "Right-click Upload" tab is gone, with its long help text cut down to two
  sentences; About no longer lists the bundle ID, update feed and other internals.
- **Background uploads no longer steal focus**: uploads started from the Finder context menu,
  the Services menu or a drop on the Dock icon no longer bring up the main window — watch the
  progress ring in the menu bar instead.
- The menu bar now lists the 5 most recent uploads instead of 8.
- **The update feed is a release asset**: `appcast.xml` is uploaded with every release and the
  app reads `releases/latest/download/appcast.xml`. Neither the appcast nor the release notes
  are written back into the repository, and release notes are embedded in the appcast itself.
- **`./build.sh --install` reinstalls cleanly**: it quits the running app and its Finder
  extension, clears every stale Dropline.app registration from LaunchServices (including dead
  entries left behind by ejected DMGs), then installs, re-enables the Finder extension and
  launches. Host profiles and keychain secrets are untouched.

### Fixed

- Pop-up buttons in Settings were misaligned because of inconsistent widths.
- After switching languages, pop-up menu items and tab titles did not refresh, and the tab bar
  showed duplicated labels and icons.

## [1.2.0] - 2026-08-07

### Added

- **Three modes for the Finder context menu**: Settings offers "show with icon", "show without
  icon" and "don't show". Changes apply immediately, without restarting Finder.
- **DMG installer**: `./tools/dmg.sh` builds an installer with a background image and a
  "drag to Applications" hint.
- **GitHub Actions**: the `CI` workflow builds and validates the artifacts on every push; the
  `Release` workflow can be triggered manually to build, pack the DMG, sign the appcast,
  publish the release and write the notes back.

## [1.1.0] - 2026-08-07

### Added

- **Finder extension**: select files in Finder and upload them straight from the top level of
  the context menu. It can be toggled under System Settings → General → Login Items &
  Extensions → Finder Extensions.
- **System notifications** on success and failure; click the notification to copy the link
  (can be turned off in Settings).
- **Progress ring in the menu bar** while uploading.
- **About panel** in Settings, showing the version, bundle ID, update feed and project page.

### Fixed

- The first row of the upload list was hidden behind the segmented control.
- The menu bar icon changed width while uploading, making the icons to its right jitter.
- Removed the redundant bottom status bar; clearing and copying moved to the list's context
  menu.

## [1.0.0] - 2026-08-07

### Added

- Five ways to upload: drop on the window, drop on the Dock icon, the system file panel, the
  clipboard, and the Finder context menu service.
- Three upload engines: `multipart/form-data`, binary `PUT`/`POST`, and S3-compatible
  (AWS SigV4, implemented in-house).
- Presets for Amazon S3, Cloudflare R2, Aliyun OSS, Tencent COS, MinIO, SM.MS, Imgur,
  Lsky Pro / Chevereto and EasyImage, plus fully custom hosts.
- Authentication via Bearer token, Basic, custom headers or URL query parameters; secrets are
  stored in the system keychain.
- The link is copied automatically when an upload finishes, optionally as Markdown; concurrent
  uploads, progress and history are supported.
- Built-in Sparkle auto-update.
