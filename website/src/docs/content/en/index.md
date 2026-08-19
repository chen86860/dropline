---
title: Introduction
description: What Dropline is, how an upload actually travels, and where to go next — the manual for the native macOS uploader that puts the public link on your clipboard.
---

# Introduction

Dropline is a native macOS app for people who host their own files. You drop a
file on it — from the window, the Dock, the Finder context menu, the clipboard
or the menu bar — and it uploads that file to **your** storage: your S3 bucket,
your R2 account, your image host. When the upload finishes, the public URL is on
your clipboard.

It is written in Swift and SwiftUI, ships as roughly a one-megabyte executable,
and is MIT licensed.

## What it is not

There is no Dropline account, no Dropline server and no telemetry. Every request
goes from your Mac straight to the endpoint you configured. If you delete the
app, nothing of yours is left anywhere except in your own bucket.

## How an upload travels

Every upload, whichever engine it uses, runs the same five steps. Almost
everything you can configure is one of these steps, so it is worth reading once.

1. **Variables are collected.** The file gives up its name, extension and size;
   the clock gives up the date. These become `{{filename}}`, `{{ext}}`,
   `{{date}}` and the rest — see [Template variables](/docs/guide/templates).
2. **The object key is rendered.** Your key template — `images/{{date}}/{{uuid}}.{{ext}}`
   by default for S3 profiles — becomes the remote path. The result is then
   itself available as `{{key}}`.
3. **The request is built and signed.** Which shape it takes depends on the
   engine: a multipart form, a raw binary body, or an AWS SigV4-signed `PUT`.
   Credentials come out of the system keychain at this moment, never from disk.
4. **The response is parsed.** A JSON path such as `data.url` pulls the link out
   of whatever your API returned. See [Reading the response](/docs/guide/response).
5. **The final URL is assembled.** An optional URL template turns a relative
   path into a link on your CDN domain, and the result lands on your clipboard.

## Three engines

Between them, these three cover very nearly every upload API in existence.

| Engine | Use it for |
| --- | --- |
| `multipart/form-data` | Most image-host APIs — SM.MS, Imgur, Lsky Pro, EasyImage |
| Binary `PUT` / `POST` | Self-hosted services and WebDAV-style endpoints |
| S3-compatible (AWS SigV4) | S3, R2, Aliyun OSS, Tencent COS, MinIO |

Nine services ship as ready-made presets. Everything else is reachable by hand
with the same handful of fields. The [host configuration](/docs/hosts/overview)
section has a page for each one.

## Where to go next

- **[Install Dropline](/docs/getting-started/install)** — download, first
  launch, and the Gatekeeper step.
- **[Your first upload](/docs/getting-started/quickstart)** — configure a host
  and get a link back, in about five minutes.
- **[Host configuration](/docs/hosts/overview)** — a page per supported
  service, with every field filled in.
- **[Troubleshooting](/docs/guide/troubleshooting)** — what the common errors
  mean and what to change.

## System requirements

- macOS 13 Ventura or later
- Apple Silicon for the published build; Intel Macs can
  [build from source](/docs/guide/build-from-source)
- No other runtime — there is no Electron, no Node, no Python
