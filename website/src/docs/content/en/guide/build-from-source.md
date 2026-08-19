---
title: Build from source
description: Clone Dropline and build it yourself with build.sh — what the script does, how to install and register the Finder extension, and how to build on an Intel Mac.
---

# Build from source

Dropline is a Swift Package with two executable targets — the app and the Finder
extension — plus [Sparkle](https://sparkle-project.org) as its only dependency.
Building it needs nothing beyond Xcode's command line tools.

## Requirements

- macOS 13 Ventura or later
- Xcode 15 or later, or the Command Line Tools (`xcode-select --install`)
- Swift 5.9+ (bundled with the above)

## Build and install

```bash
git clone https://github.com/chen86860/dropline.git
cd dropline
./build.sh --install
```

That is the whole thing. `--install` does the extra work of putting the app
where macOS expects it, which matters more here than for most apps:

1. Quits any running copy
2. Removes the previous install
3. Deregisters stale LaunchServices entries — **two copies of `Dropline.app` on
   disk break the Services and Finder menu items**, so this step is not optional
4. Copies the bundle to `/Applications`
5. Registers the Services menu entry and enables the Finder extension
6. Launches the app

Without `--install`, the script stops after producing `dist/Dropline.app`, which
is useful for inspection but will not have a working context-menu item.

## What the script does

```text
swift build -c release --arch arm64      # compile
assemble Dropline.app                    # bundle layout
package DroplineFinder.appex             # the Finder extension
embed Sparkle.framework                  # from the resolved package
generate the icon                        # tools/makeicon.swift
write Info.plist                         # version, feed URL, EdDSA public key
codesign --sign -                        # ad-hoc
```

The version number comes from the newest entry in `CHANGELOG.md`, so a build
cannot disagree with the release notes. Override it if you need to:

```bash
DROPLINE_VERSION=1.4.1 ./build.sh --install
```

## Signing

By default the bundle is **ad-hoc signed**, which is why a downloaded release
needs the [Gatekeeper
step](/docs/getting-started/install#first-launch). A locally built copy is
generally not quarantined, so it just opens.

If you have a Developer ID certificate, use it:

```bash
DROPLINE_SIGN_ID="Developer ID Application: Your Name (TEAMID)" ./build.sh --install
```

## Building on an Intel Mac

The script hard-codes `--arch arm64` to match the published release. On Intel,
change that line to your architecture — or drop the flag to build for the host:

```diff
-swift build -c release --arch arm64
+swift build -c release
```

Everything else in the script is architecture-independent. Nothing in the app
itself is Apple-Silicon-specific; only the shipped binary is.

## Project layout

| Path | What it is |
| --- | --- |
| `Sources/Dropline` | The app — SwiftUI views, state, upload engines |
| `Sources/DroplineFinder` | The Finder extension (`.appex`) |
| `Sources/Dropline/UploadService.swift` | The three engines and the request builders |
| `Sources/Dropline/S3Signer.swift` | AWS SigV4, path-style `PUT` |
| `Sources/Dropline/Templating.swift` | `{{variable}}` rendering and JSON path extraction |
| `Sources/Dropline/Models.swift` | The profile model and every built-in preset |
| `tools/` | Icon and DMG generators, changelog and Sparkle helpers |
| `website/` | This site — TanStack Start on Cloudflare Workers |

If you are adding a preset, `ProfilePresets` in `Models.swift` is the one place
to touch; it drives the **+** menu in Settings → Hosts directly.

## Troubleshooting the build

**`❌ Can't find Sparkle.framework`** — resolve the package first:

```bash
swift package resolve
```

**The right-click menu item does not appear after installing** — you probably
have a second copy of the app somewhere. `./build.sh --install` cleans stale
registrations; running plain `./build.sh` and dragging the bundle yourself does
not.

**Nothing changed after rebuilding** — quit the running app first; `--install`
does this for you.

## Next

[Host configuration →](/docs/hosts/overview)
