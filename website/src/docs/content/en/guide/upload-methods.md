---
title: The five ways to upload
description: Window, Dock, Finder context menu, clipboard and menu bar — every way to get a file into Dropline, what each one is best at, and what happens when the upload finishes.
---

# The five ways to upload

Dropline has five entry points, and every one of them is somewhere macOS already
put your hands. However a file gets in, it leaves the same way: the URL on your
clipboard, plus a system notification.

## 1. The window

Open Dropline and drop files onto it. The window is the only place that shows
the full queue — one row per file, each with its own progress bar, and the
history list underneath.

Drop a **folder** and Dropline expands it, uploading the files inside.

## 2. The Dock icon

Drag a file onto the Dropline icon in the Dock without opening anything. The
upload starts immediately; the window does not come forward.

If you never want a Dock icon, turn on **Settings → General → Hide the Dock icon
(menu bar only)**. Dropline then runs as a menu bar app with no Dock presence
and no ⌘-Tab entry.

## 3. The Finder context menu

Right-click any file in Finder and choose **Upload with Dropline**. It sits at
the *top level* of the menu, not buried under *Services*.

This comes from a Finder extension, which macOS keeps switched off until you
approve it — see [Install](/docs/getting-started/install#enable-the-finder-extension).
Three display modes are available under **Settings → General → Finder Context
Menu**:

| Mode | What you get |
| --- | --- |
| Show (with icon) | The item, with an upload glyph beside it |
| Show (without icon) | The item, plain, matching the system's own entries |
| Don't show | Nothing in the context menu; every other way still works |

The change takes effect immediately — no Finder restart.

### As a Services shortcut

The same command appears under **System Settings → Keyboard → Keyboard Shortcuts
→ Services → Files and Folders**, where you can bind it to a key combination.
Select files in Finder, press the key, done.

## 4. The clipboard

Copy an image and upload it without ever writing it to disk. This is the fast
path for screenshots: press `⇧⌘4`, drag a region, then upload from the clipboard
— macOS puts the screenshot on the clipboard when you hold `⌃` while capturing,
or you can use the on-screen capture bar's clipboard option.

Clipboard uploads are also how you move an image out of a browser, a chat window
or Preview without saving a file first.

## 5. The menu bar

The menu bar icon is the app's real home.

- **Upload…** opens the system file panel.
- **The last five links** sit in the menu, one click from being copied again.
- The icon **turns into a progress ring** while an upload runs, showing overall
  progress without you switching to anything.

## What happens on finish

The same three things happen for all five, and each is a switch in
**[Settings → General](/docs/guide/settings)**:

1. **The link goes on your clipboard** — as a bare URL, or as
   `![name](url)` with *Copy as Markdown* on.
2. **A system notification fires**, naming the file.
3. **The record joins the history**, which keeps the last 300 uploads and
   surfaces the last five in the menu bar.

## Large files and concurrency

Any file type is accepted. Large ones — video especially — are streamed from a
temporary file rather than held in memory, so a two-gigabyte upload costs the
same RAM as a screenshot.

Uploads run **concurrently**, three at a time by default, adjustable to 1, 2, 3,
5 or 8 under **Settings → General → Concurrent uploads**. The transfer timeout is
one hour per file, so slow links and big videos do not get cut off.

## Next

[Settings reference →](/docs/guide/settings)
