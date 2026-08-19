---
title: Imgur
description: Configure Dropline for Imgur — registering an application for a Client-ID, the exact Authorization header format, the data.link response path, and Imgur's limits on anonymous uploads.
---

# Imgur

**Engine:** `multipart/form-data` · **Preset:** `Imgur`

## Configuration

Settings → Hosts → **+** → **Imgur**.

| Field | Value |
| --- | --- |
| Upload URL | `https://api.imgur.com/3/image` |
| Method | `POST` |
| File field name | `image` |
| Authentication | **Custom header** |
| Header name | `Authorization` |
| Header value | `Client-ID abc123def456789` — the **whole string** |
| JSON path | `data.link` |
| Final URL template | *(empty)* |

### The header value is not just the id

This is the single thing people get wrong. Imgur expects:

```http
Authorization: Client-ID abc123def456789
```

So the value you paste into Dropline is `Client-ID abc123def456789` — the words
`Client-ID`, a space, then your id. Pasting the bare id gives `HTTP 403`.

Dropline's *Custom header* kind sends the value verbatim precisely so headers
like this can be expressed. Do **not** use the Bearer kind; that is for OAuth
access tokens, which are a different thing.

## Get a Client-ID

1. Sign in at [imgur.com](https://imgur.com/).
2. Go to [api.imgur.com/oauth2/addclient](https://api.imgur.com/oauth2/addclient).
3. Pick **Anonymous usage without user authorization** as the type. It asks for
   an authorization callback URL anyway — any URL you control is fine; it is not
   used.
4. Submit. Copy the **Client ID**. The Client Secret is not needed for anonymous
   uploads.

## The response

```json
{
  "status": 200,
  "success": true,
  "data": {
    "id": "abc123",
    "link": "https://i.imgur.com/abc123.png",
    "deletehash": "xyz789",
    "type": "image/png"
  }
}
```

`data.link` is the direct image URL. `data.deletehash` is the only way to delete
an anonymous upload later — Dropline does not keep it, so if that matters,
upload under a user account through Imgur's own tools instead.

## Limits and terms

| Limit | Value |
| --- | --- |
| Max non-animated image | 20 MB |
| Max animated (GIF/MP4) | 200 MB |
| Formats | jpg, png, gif, apng, tiff, webp |
| Rate | ~1250 uploads per day per Client-ID |

Two things worth knowing before you rely on it:

- **Anonymous uploads have no owner.** You cannot list, manage or recover them,
  and Imgur removes anonymous images that go unviewed for long periods.
- **Imgur is a public gallery.** Its terms prohibit using it as a general file
  host or a CDN for a site. For anything that is not a casual share, use
  [object storage](/docs/hosts/overview).

## Object key template

Imgur assigns its own id and ignores the filename, so the key template has no
practical effect here.

## Common problems

| Symptom | Cause |
| --- | --- |
| `HTTP 403` | Header value is the bare id; it needs the `Client-ID ` prefix |
| `HTTP 400` | The file is not an image format Imgur accepts |
| `HTTP 429` | Daily or hourly rate limit reached |
| `Path data.link not found` | An error body came back — read the `data.error` field with `curl` |
