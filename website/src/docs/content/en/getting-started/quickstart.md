---
title: Your first upload
description: Configure a host profile in Dropline, verify it with Test Upload, and get a working public link on your clipboard in about five minutes.
---

# Your first upload

This walks through configuring one host and getting a link back. It takes about
five minutes, and the shape of it is the same whichever service you use.

## 1. Open Hosts

Open Dropline, then **Settings → Hosts** (`⌘,`). The list on the left is empty
on a fresh install.

Click **+** at the bottom left. The menu that appears is the preset list:

```text
Blank · Custom HTTP
Blank · Custom binary PUT
Amazon S3
Cloudflare R2
Aliyun OSS (S3-compatible)
Tencent COS (S3-compatible)
MinIO / self-hosted S3
SM.MS
Imgur
Lsky Pro / Chevereto
EasyImage / PicGo custom
```

Pick the one closest to your service. A preset fills in the endpoint shape, the
file field name, the authentication kind and the JSON path — everything except
your own credentials and domain. If nothing fits, start from **Blank · Custom
HTTP** and see [Custom multipart host](/docs/hosts/custom-multipart).

## 2. Fill in your credentials

What you need depends on the engine the preset chose.

**S3-compatible** presets (S3, R2, OSS, COS, MinIO) ask for:

| Field | Example |
| --- | --- |
| Endpoint | `https://<account>.r2.cloudflarestorage.com`, empty for AWS |
| Region | `auto`, `us-east-1`, `oss-cn-hangzhou` |
| Bucket | `my-assets` |
| Access Key ID | `AKIA…` |
| Secret Access Key | stored in the keychain, never in the config file |
| Public base URL | `https://cdn.example.com` — optional |

**Image-host** presets ask for an upload URL, an authentication secret, and
little else. The preset already knows the file field name and where the link
sits in the response.

Each host page in the [host configuration](/docs/hosts/overview) section lists
every field for that service, with the values to type.

## 3. Test it before you trust it

Click **Test Upload** at the bottom of the editor. Dropline generates an 8×8 PNG,
sends it through the profile exactly as a real upload would, and shows you one of
two things:

- **Success**, followed by the URL that came back. Open it. If the image loads,
  the profile is correct end to end — request, authentication, response parsing
  and URL assembly.
- **An error**, in red. [Troubleshooting](/docs/guide/troubleshooting) maps each
  message to the field that causes it.

A green tick appears next to the profile that is currently the default. If you
have more than one, select yours and click **Set as Default**.

## 4. Upload something real

Close Settings and use any of the five ways in:

- **Drop** a file on the Dropline window
- **Drop** it on the Dock icon
- **Right-click** it in Finder → *Upload with Dropline*
- **Paste** — a `⇧⌘4` screenshot uploads straight from the clipboard, with no
  saving first
- **Menu bar** → *Upload…*

The menu bar icon becomes a progress ring. When it finishes, a system
notification confirms it and the URL is already on your clipboard — paste it
wherever you were going.

## 5. Optional: Markdown

If you paste links into Markdown all day, turn on **Settings → General → Copy as
Markdown** and the clipboard gets `![name](url)` instead of the bare URL.

## Next

- [The five ways to upload →](/docs/guide/upload-methods)
- [Template variables →](/docs/guide/templates) — control the remote path
- [Host configuration →](/docs/hosts/overview) — your service, field by field
