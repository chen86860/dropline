<div align="center">

<img src="assets/logo.png" width="128" alt="Dropline">

# Dropline

**Drop it in, the link is on your clipboard.**

A native macOS uploader: send images, videos or any file to your own host by drag & drop,
right-click or the menu bar, and get the public URL copied automatically.
Pure Swift + SwiftUI, ~1 MB executable.

[![Release](https://img.shields.io/github/v/release/chen86860/dropline?color=2f6feb)](https://github.com/chen86860/dropline/releases/latest)
[![Stars](https://img.shields.io/github/stars/chen86860/dropline?color=f5a623)](https://github.com/chen86860/dropline/stargazers)
[![Downloads](https://img.shields.io/github/downloads/chen86860/dropline/total?color=3fb950)](https://github.com/chen86860/dropline/releases)
![Platform](https://img.shields.io/badge/macOS-13%2B%20·%20Apple%20Silicon-black)
[![License](https://img.shields.io/github/license/chen86860/dropline?color=8957e5)](LICENSE)

**English** · [简体中文](README.zh-CN.md)

</div>

---

## Features

- **Five ways to upload**: drop on the window / drop on the Dock icon / system file panel / clipboard (screenshots work directly) / **top-level Finder context menu**
- **Lives in the menu bar**: the icon turns into a progress ring while uploading, and offers quick upload plus the last 5 links
- **Auto-copies the link when done + system notification**, optionally as Markdown `![name](url)`
- **Any file type**: large videos stream from a temporary file instead of being held in memory
- Switch between multiple host profiles, concurrent uploads, live progress, history
- Secrets live in the **system keychain**, never in the config file
- **English & Chinese**: follows the system language (anything other than Chinese falls back to English), or pick one in Settings → General
- Built-in [Sparkle](https://sparkle-project.org) auto-update

## Supported hosts

Built-in presets: Amazon S3, Cloudflare R2, Aliyun OSS, Tencent COS, MinIO, SM.MS, Imgur, Lsky Pro / Chevereto, EasyImage.

Three engines cover almost any service, and anything else can be configured by hand:

| Engine | Use for |
| --- | --- |
| `multipart/form-data` | most image-host APIs |
| Binary `PUT` / `POST` | self-hosted services, WebDAV-style endpoints |
| S3-compatible (AWS SigV4) | S3 / R2 / OSS / COS / MinIO |

**Authentication**: none / Bearer token / Basic / custom header / URL query parameter.

### Configuring a custom host

Settings → Hosts → new profile:

- **Upload URL** `https://your-domain.com/api/upload`
- **JSON path** for parsing the response, e.g. `data.url`, `files.0.url`; leave empty if the body itself is the URL
- **Final URL template** (optional) `https://cdn.example.com/{{result}}`, for APIs that only return a relative path
- **Object key template** `images/{{date}}/{{uuid}}.{{ext}}`

Template variables: `{{filename}} {{base}} {{ext}} {{uuid}} {{date}} {{datetime}} {{timestamp}} {{rand}} {{key}} {{result}}`

"Test Upload" at the bottom of the editor sends an 8×8 test image and shows the returned URL, or the error.

## Install

Download from [Releases](https://github.com/chen86860/dropline/releases/latest) and drag it into Applications.
The asset name carries no version number, so this link always points at the newest stable build:
[`Dropline.dmg`](https://github.com/chen86860/dropline/releases/latest/download/Dropline.dmg).

The build is ad-hoc signed, so on first launch right-click the app → Open, or run:

```bash
xattr -dr com.apple.quarantine /Applications/Dropline.app
```

If the context menu item does not show up, enable Dropline under
System Settings → General → Login Items & Extensions → Finder Extensions.
(There is also a Services item with the same name under Keyboard → Keyboard Shortcuts →
Services → Files and Folders, which you can assign a shortcut to.)

## Building from source

Requires macOS 13+ and the Xcode command line tools (Swift 5.9+).

```bash
./build.sh --install     # build + install to /Applications + register the context menu
./build.sh               # build into dist/ only
```

`--install` first quits the running Dropline and its Finder extension, unregisters and removes
the old copy in `/Applications`, installs the new one, re-registers the Services menu and the
Finder extension, and launches it. **Host profiles and secrets are untouched** — they live in
UserDefaults (`~/Library/Preferences/dev.emmmm.Dropline.plist`) and the login keychain
respectively, keyed by bundle ID, so deleting the `.app` does not take them along.

> LaunchServices must hold exactly one Dropline.app registration — with several it flip-flops
> between them and the context menu stops working. `--install` lists every registered
> Dropline.app and unregisters them all before registering the new one. The most common
> stray registration comes from a DMG you once mounted: the entry survives ejecting the volume
> even though the path is long gone, and such a dead entry can still be removed with
> `lsregister -u <original path>`. Real copies elsewhere on disk are only unregistered, never
> deleted for you. `--install` uses `mv` rather than `cp`, so nothing is left behind in `dist/`.

## Building the DMG

```bash
./tools/dmg.sh          # version comes from the latest CHANGELOG entry, produces dist/Dropline.dmg
```

Ships with a background image, a volume icon and a "drag to Applications" hint.
Requires `brew install create-dmg`.

The window layout is a `.DS_Store` that create-dmg writes into the volume through Finder
AppleScript. That occasionally fails, so the script retries three times; the release pipeline
sets `DMG_REQUIRE_STYLE=1` so a missing layout fails the build instead of silently shipping a
bare DMG without a background. Use `DMG_SKIP_STYLE=1` to skip the styling and build faster
while debugging.

## Releasing

Add a `## [1.0.1] - date` section at the top of **both** [CHANGELOG.md](CHANGELOG.md) and
[CHANGELOG.zh-CN.md](CHANGELOG.zh-CN.md), commit, push, then **tag it**:

```bash
git tag v1.0.1
git push origin v1.0.1
```

Pushing the tag triggers the `Release` workflow. The version comes from the tag (minus the
leading `v`); the workflow builds the app, packs the DMG, signs the appcast, and publishes the
DMG, the update zip, the delta packages and `appcast.xml` as release assets. Neither the
appcast nor the release notes are kept in the repository any more.

The build fails if the version is missing from CHANGELOG. To retry a failed build, hit Re-run
on the Actions page; if you changed code, delete the tag and re-create it:

```bash
git tag -d v1.0.1 && git push --delete origin v1.0.1
```

The signing key has to be configured once:

```bash
./tools/sparkle.sh export-key                                   # export from the keychain
gh secret set SPARKLE_PRIVATE_KEY < sparkle-private-key.txt     # store as a repository secret
rm sparkle-private-key.txt
```

**Releasing locally** (emergencies only — normally use the tag flow above):

```bash
./tools/sparkle.sh release 1.0.1   # build → pack → EdDSA sign → generate appcast → publish
```

> This creates the `v1.0.1` tag on the remote, which **also** triggers the `Release` workflow —
> effectively releasing twice (whichever finishes last overwrites the assets with `--clobber`).
> Pick one path, not both.

CHANGELOG is the single source of release notes: the scripts extract the matching section,
turn it into an HTML fragment embedded in the appcast for Sparkle's update dialog, and use the
English Markdown as the GitHub release body. **A missing entry aborts the release**, so no
version ever ships without notes.

Notes are shipped in both languages: each appcast item carries an `<description xml:lang="en">`
and a `<description xml:lang="zh-Hans">`, and Sparkle picks one via
`NSBundle.preferredLocalizations(from:)`. The app writes the language chosen in Settings into
`AppleLanguages` so the update dialog follows it — that takes effect from the next launch,
since CFBundle resolves the language list at process start. A version missing from the Chinese
file only logs a warning; that release then has English notes only.

Updates are signed with EdDSA; the public key sits in Info.plist and the private key in the
login keychain. For public distribution pass a Developer ID and the script enables hardened
runtime and timestamping automatically (both required for notarization):

```bash
DROPLINE_SIGN_ID="Developer ID Application: NAME (TEAMID)" ./tools/sparkle.sh release 1.0.1
```

## Code layout

```
Sources/Dropline/
  DroplineApp.swift    entry point, menu bar item, Dock drop, AppDelegate
  AppState.swift       settings, upload queue and concurrency, history, clipboard
  Models.swift         configuration model and host presets
  UploadService.swift  the three upload engines: multipart / binary / S3
  S3Signer.swift       AWS Signature V4 (streaming SHA256)
  Templating.swift     {{variable}} rendering + JSON path lookup
  Updater.swift        Sparkle wrapper
  Notifier.swift       system notifications
  TrayIcon.swift       menu bar icon with progress ring
  Keychain.swift       secret storage
  Localization.swift   English/Chinese string table (source is English, Chinese via lookup,
                       missing entries fall back to English)
  ContentView.swift    main window
  SettingsView.swift   settings (General / Hosts / About)

Sources/DroplineFinder/
  FinderSyncExtension.swift   Finder context menu extension (sandboxed, hands the selection
                              to the main app over dropline://)

tools/
  sparkle.sh        release helper
  changelog.py      extracts a version section from CHANGELOG.md / CHANGELOG.zh-CN.md
                    as Markdown / HTML (--lang en|zh)
  appcast_i18n.py   adds the Chinese <description xml:lang="zh-Hans"> to each appcast item
  makeicon.swift    generates the app icon
```

## License

[MIT](LICENSE)
