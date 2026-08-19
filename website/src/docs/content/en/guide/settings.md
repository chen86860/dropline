---
title: Settings reference
description: Every setting in Dropline — clipboard and Markdown, notifications, the Dock icon, concurrency, the Finder context menu, appearance, language and Sparkle updates.
---

# Settings reference

Open Settings with `⌘,`, or from the menu bar icon. There are three tabs:
**General**, **Hosts** and **About**. This page covers General and About;
[host configuration](/docs/hosts/overview) has its own section.

## General

### Copy the link to the clipboard when an upload finishes

**Default: on.** The whole point of the app. Turn it off and uploads still run,
still notify and still enter the history — you just have to copy the link from
the menu bar or the history list yourself.

### Copy as Markdown `![name](url)`

**Default: off.** Requires the setting above. With it on, the clipboard receives

```text
![screenshot-2026-08-08.png](https://cdn.example.com/2026/08/a1f3c9.png)
```

instead of the bare URL. The alt text is the original filename, not the remote
object key.

### Send a system notification when an upload finishes

**Default: on.** A standard macOS notification naming the file. macOS may ask
for notification permission the first time; if you declined and want it back,
re-enable Dropline under **System Settings → Notifications**.

### Hide the Dock icon (menu bar only)

**Default: off.** Turns Dropline into a pure menu bar app — no Dock icon, no
⌘-Tab entry. Note that this also removes the Dock as a drop target; the window,
Finder, clipboard and menu bar all keep working.

### Concurrent uploads

**Default: 3.** Choose 1, 2, 3, 5 or 8. Files beyond the limit queue and start
as slots free up. Raise it for many small files on a fast link; lower it to 1 if
your host rate-limits you or you want deterministic ordering.

## Finder Context Menu

### Show as

**Default: Show (with icon).** Controls the top-level **Upload with Dropline**
entry in the Finder right-click menu.

| Option | Behaviour |
| --- | --- |
| Show (with icon) | Top of the context menu, with an upload glyph |
| Show (without icon) | Top of the context menu, plain — matches system items |
| Don't show | Absent from the context menu entirely |

Changes apply immediately, with no need to relaunch Finder. If the item is
missing altogether even on *Show*, the extension itself is not approved yet —
see [Install](/docs/getting-started/install#enable-the-finder-extension).

## Appearance

### Color scheme

**Default: Follow System.** *Light* and *Dark* override the appearance for
Dropline only; the rest of macOS is untouched. *Follow System* includes the
system's own automatic day/night switch.

The menu bar icon is a template image, so it always inverts to match the menu
bar itself regardless of this setting — which is correct, because that is what
every other menu bar icon does.

## Language

### Interface language

**Default: Follow System.** Anything other than Chinese falls back to English.
Choosing explicitly takes effect immediately, with no restart, and the choice
also propagates to the Finder extension's menu item.

## Software Update

Updates go through [Sparkle](https://sparkle-project.org) and are signed with
EdDSA, so a tampered build cannot install itself.

| Setting | Default | Effect |
| --- | --- | --- |
| Check for updates automatically | on | Periodic background check |
| Download and install updates automatically | off | Silent update; requires the check above |
| Check Now | — | Immediate check, reporting either an update or that you are current |

The panel also shows the current version and when the last check ran. Release
notes ship in English and Chinese and follow your interface language.

## About

The app icon, the version string (selectable, so you can paste it into a bug
report), and three buttons: **Check for Updates…**, **Project Home** and
**Report an Issue**.

## Where settings are stored

| What | Where |
| --- | --- |
| Settings and host profiles | `~/Library/Preferences/dev.emmmm.Dropline.plist` |
| Upload history (last 300) | the same preferences file |
| Secrets — tokens, secret access keys | the **system keychain**, service `dev.emmmm.Dropline` |

Nothing secret is ever written to the preferences file. That split is deliberate
and is covered in [Credentials and privacy](/docs/guide/security).

## Next

[Template variables →](/docs/guide/templates)
