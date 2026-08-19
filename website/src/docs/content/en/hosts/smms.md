---
title: SM.MS
description: Configure Dropline for SM.MS — getting an API token, the smfile field, the data.url response path, and the service's size and rate limits.
---

# SM.MS

**Engine:** `multipart/form-data` · **Preset:** `SM.MS`

SM.MS is a free image host with a simple v2 API. Good for throwaway screenshots;
not somewhere to keep anything you care about.

## Configuration

Settings → Hosts → **+** → **SM.MS**. Everything but the token is pre-filled.

| Field | Value |
| --- | --- |
| Upload URL | `https://sm.ms/api/v2/upload` |
| Method | `POST` |
| File field name | `smfile` |
| Authentication | **Custom header** |
| Header name | `Authorization` |
| Header value | your API token — goes to the keychain |
| JSON path | `data.url` |
| Final URL template | *(empty)* |

Note the authentication kind is **Custom header**, not Bearer: SM.MS wants the
token on its own, with no `Bearer ` prefix. Dropline's custom-header kind sends
the value verbatim, which is exactly that.

## Get a token

1. Register at [sm.ms](https://sm.ms/) and sign in.
2. **User → Dashboard → API Token**.
3. Generate a token and copy it into the **Header value** field.

Uploads without a token are possible but anonymous — you cannot list or delete
them afterwards, and the rate limit is much tighter. Use a token.

## The response

```json
{
  "success": true,
  "code": "success",
  "data": {
    "url": "https://s2.loli.net/2026/08/19/abc123.png",
    "delete": "https://sm.ms/delete/xxxxx",
    "page": "https://sm.ms/image/abc123"
  }
}
```

`data.url` is the direct image link, which is what the preset reads.

### Duplicate uploads

Upload the same bytes twice and SM.MS answers differently — `success: false`
with the existing URL in the `images` field rather than under `data`. Dropline's
path lookup then fails with `Path data.url not found in the response`. Nothing
is broken; the file is already hosted. Re-uploading an identical file is the
only way to hit this.

## Limits

| Limit | Value |
| --- | --- |
| Max file size | 5 MB |
| Formats | jpg, png, gif, bmp, webp |
| Rate | roughly 20 uploads per minute with a token |

Non-image files are rejected outright — SM.MS is an image host, so send video and
documents to [object storage](/docs/hosts/overview) instead.

A `HTTP 429` means you hit the rate limit. Lower **Settings → General →
Concurrent uploads** to 1.

## Object key template

SM.MS assigns its own name and path, so the key template has no effect beyond the
`filename` in the multipart part. Leave the default alone.

## Common problems

| Symptom | Cause |
| --- | --- |
| `HTTP 401` | Token missing, or set as Bearer instead of Custom header |
| `Path data.url not found` | Duplicate upload, or the file was rejected |
| `HTTP 413` | Over 5 MB |
| `HTTP 429` | Rate limited |
