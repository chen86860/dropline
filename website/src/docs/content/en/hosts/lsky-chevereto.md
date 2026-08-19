---
title: Lsky Pro / Chevereto
description: Configure Dropline for a self-hosted Lsky Pro (兰空图床) or Chevereto gallery — the v1 API endpoint, Bearer token, Accept header, storage strategy and album fields.
---

# Lsky Pro / Chevereto

**Engine:** `multipart/form-data` · **Preset:** `Lsky Pro / Chevereto`

Both are self-hosted image galleries with a token-authenticated upload API. The
preset targets **Lsky Pro v2's** API shape; Chevereto is close enough that the
same profile works with one field changed, noted below.

## Configuration — Lsky Pro

Settings → Hosts → **+** → **Lsky Pro / Chevereto**.

| Field | Value |
| --- | --- |
| Upload URL | `https://your-domain.com/api/v1/upload` |
| Method | `POST` |
| File field name | `file` |
| Custom header | `Accept: application/json` |
| Authentication | **Bearer Token** |
| Token | `1|abcdefg…` — the whole string, goes to the keychain |
| JSON path | `data.links.url` |
| Final URL template | *(empty)* |

The `Accept: application/json` header is not optional. Without it Lsky Pro
answers with an HTML error page on failure, and Dropline reports
`The response is not valid JSON` instead of the real problem.

### Get a token

Either from the web UI — sign in, then **Settings → API tokens (接口 Token)** —
or from the API:

```bash
curl -sS -X POST https://your-domain.com/api/v1/tokens \
     -H "Accept: application/json" \
     -F "email=you@example.com" \
     -F "password=your-password"
```

The response's `data.token` looks like `1|xxxxxxxx…`. Paste it whole; the
leading `1|` is part of the token.

### Optional extra form fields

Lsky Pro accepts more parameters, and Dropline's **Extra form fields** sends
them alongside the file:

| Key | Value | Meaning |
| --- | --- | --- |
| `strategy_id` | `1` | Which storage strategy to write to (local, S3, …) |
| `album_id` | `3` | Put uploads in a specific album |
| `permission` | `1` | `1` public, `0` private |
| `expired_at` | `2026-12-31 23:59:59` | Auto-delete time |

Values are templated, so `expired_at` can be built from `{{date}}` if you want.

### The response

```json
{
  "status": true,
  "message": "上传成功",
  "data": {
    "key": "abc123",
    "name": "a1f3c9.png",
    "links": {
      "url": "https://your-domain.com/i/2026/08/19/a1f3c9.png",
      "html": "<img src=\"…\" alt=\"…\" />",
      "markdown": "![](…)"
    }
  }
}
```

`data.links.url` is the direct link. `data.links.markdown` is also there, but
prefer Dropline's own **Copy as Markdown** setting — it uses the original
filename as the alt text.

## Configuration — Chevereto

Chevereto's v1 API differs in two fields:

| Field | Value |
| --- | --- |
| Upload URL | `https://your-domain.com/api/1/upload` |
| File field name | `source` |
| Authentication | **URL query parameter**, name `key` |
| JSON path | `image.url` |

Chevereto's own key is passed as `?key=…` rather than as a Bearer header. Its
response is shaped like:

```json
{
  "status_code": 200,
  "image": {
    "url": "https://your-domain.com/images/2026/08/19/abc.png",
    "display_url": "https://your-domain.com/images/2026/08/19/abc.md.png"
  }
}
```

Set the JSON path to `image.url` for the original, or `image.display_url` for
the resized variant.

## Object key template

Both services rename uploads according to their own settings, so the key
template does not control the final path. Leave the default.

## Common problems

| Symptom | Cause |
| --- | --- |
| `The response is not valid JSON` | Missing `Accept: application/json` header |
| `HTTP 401` | Token expired or revoked; generate a new one |
| `HTTP 403` | The token's user lacks upload permission, or the strategy id is not theirs |
| `HTTP 413` | The gateway limit — `client_max_body_size` in nginx, `upload_max_filesize` in PHP |
| `Path data.links.url not found` | You are on Chevereto, not Lsky Pro — use `image.url` |
