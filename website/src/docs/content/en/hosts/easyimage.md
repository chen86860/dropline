---
title: EasyImage
description: Configure Dropline for a self-hosted EasyImage 2.0 (简单图床) — the API endpoint, the token form field rather than a header, and the url response path.
---

# EasyImage

**Engine:** `multipart/form-data` · **Preset:** `EasyImage / PicGo custom`

EasyImage 2.0 (简单图床) is a lightweight self-hosted PHP image host. Its API
authenticates with a **form field**, not a header — which is why this preset's
authentication kind is *None*.

## Configuration

Settings → Hosts → **+** → **EasyImage / PicGo custom**.

| Field | Value |
| --- | --- |
| Upload URL | `https://your-domain.com/api/index.php` |
| Method | `POST` |
| File field name | `image` |
| Extra form fields | `token` = your API token |
| Authentication | **None** |
| JSON path | `url` |
| Final URL template | *(empty)* |

> The token travels as a form field, so it is stored in the **config file**, not
> the keychain — only the *authentication secret* goes to the keychain. If you
> would rather it did not, set Authentication to *URL query parameter* with the
> name `token` instead, leave the form field out, and the value moves to the
> keychain. EasyImage accepts it either way.

## Enable the API

In the EasyImage admin panel:

1. **设置 → API 设置 (Settings → API)**.
2. Turn the API on.
3. Generate a token and copy it.
4. Check the allowed formats and size limit while you are there.

## The response

```json
{
  "result": "success",
  "code": 200,
  "url": "https://your-domain.com/i/2026/08/19/abc123.png",
  "srcName": "screenshot.png",
  "thumb": "https://your-domain.com/i/2026/08/19/abc123.th.png"
}
```

The link is at the top level, so the JSON path is just `url`.

On failure the shape is `{"result":"failed","code":204,"message":"…"}`, and
Dropline reports `Path url not found in the response` — run the request with
`curl` to read the message.

## The PicGo-compatible variant

Some EasyImage deployments, and several forks, expose a PicGo-style endpoint at
a different path with the token in the query string:

```text
Upload URL     https://your-domain.com/api/index.php?token=YOUR_TOKEN
File field     image
JSON path      url
```

Both work; the preset uses the form-field form because it keeps the token out of
URLs and logs.

## Size limits

EasyImage runs on PHP, so uploads are bounded by the server, not the app. If
large files fail with `HTTP 413` or a PHP error, raise these in `php.ini`:

```ini
upload_max_filesize = 20M
post_max_size = 20M
```

and, behind nginx:

```text
client_max_body_size 20m;
```

Restart PHP-FPM and nginx after changing them.

## Object key template

EasyImage names uploads itself, by date and hash, so the key template has no
effect on the final path.

## Common problems

| Symptom | Cause |
| --- | --- |
| `Path url not found` | Token wrong or API disabled — the body carries the reason |
| `The response is not valid JSON` | The URL is wrong and you are getting the site's HTML back |
| `HTTP 413` | PHP or nginx body-size limits |
| Link works but images are broken | The site's own domain setting differs from the one you upload to |
