---
title: Custom multipart host
description: Point Dropline at any image-host API that takes a multipart/form-data POST — how to read the API docs into the six fields, worked examples, and how to reproduce the request with curl.
---

# Custom multipart host

**Engine:** `multipart/form-data` · **Preset:** `Blank · Custom HTTP`

If your service is not on the preset list, it is almost certainly reachable this
way. Every image-host API that PicGo, uPic or ShareX can talk to fits into the
fields below.

## What Dropline sends

```http
POST /api/upload HTTP/1.1
Host: your-domain.com
Authorization: Bearer <secret>
Content-Type: multipart/form-data; boundary=DroplineBoundary-…

--DroplineBoundary-…
Content-Disposition: form-data; name="token"

abc123
--DroplineBoundary-…
Content-Disposition: form-data; name="file"; filename="a1f3c9.png"
Content-Type: image/png

<the file's bytes>
--DroplineBoundary-…--
```

Reading that against your API's documentation gives you every field.

## The fields

| Field | Where it comes from in the API docs |
| --- | --- |
| **Upload URL** | The endpoint. Templated — `{{key}}` and the rest work here |
| **Method** | `POST` unless the docs say `PUT` or `PATCH` |
| **File field name** | The name of the file part: `file`, `image`, `source`, `smfile` |
| **Custom headers** | Anything the docs require beyond auth — usually `Accept: application/json` |
| **Extra form fields** | Non-file parameters: album ids, tokens, expiry, visibility |
| **Authentication** | See below |
| **JSON path** | Where the link sits in the response — [Reading the response](/docs/guide/response) |
| **Final URL template** | Only if the response gives a relative path |

Header values and form-field values are both templated, so
`{{key}}`, `{{base}}`, `{{date}}` and friends can be used in either.

## Choosing the authentication kind

| The docs say | Use | Configure |
| --- | --- | --- |
| `Authorization: Bearer TOKEN` | Bearer Token | Secret = the token, no prefix |
| `Authorization: TOKEN` | Custom header | Name `Authorization`, value = the token |
| `Authorization: Client-ID xyz` | Custom header | Name `Authorization`, value = `Client-ID xyz` |
| `X-API-Key: TOKEN` | Custom header | Name `X-API-Key`, value = the token |
| `?token=TOKEN` in the URL | URL query parameter | Name `token`, value = the token |
| Username and password | Basic | Username in the name field, password as the secret |
| A token as a form field | None | Add it under *Extra form fields* instead |

The **custom header** kind sends the value exactly as typed and adds no prefix,
which is what makes odd schemes expressible.

## Worked example: a token in a form field

An API documented as:

> `POST https://img.example.com/upload` with `file` and `api_key`, returning
> `{"code":0,"data":{"path":"/i/2026/abc.png"}}`, served from
> `https://img.example.com`.

becomes:

| Field | Value |
| --- | --- |
| Upload URL | `https://img.example.com/upload` |
| Method | `POST` |
| File field name | `file` |
| Extra form fields | `api_key` = `YOUR_KEY` |
| Authentication | None |
| JSON path | `data.path` |
| Final URL template | `https://img.example.com{{result}}` |

Note the template has **no slash** before `{{result}}` — the returned path
already starts with one.

## Worked example: a folder in the URL

An API that takes the target directory as part of the path:

| Field | Value |
| --- | --- |
| Upload URL | `https://img.example.com/upload/{{date}}` |
| Object key template | `{{uuid}}.{{ext}}` |
| JSON path | `url` |

Templates in the endpoint are rendered before the request is built, so each
day's uploads land in their own directory.

## Prove it with curl first

If **Test Upload** fails and the message is not obvious, reproduce the request
outside the app. Anything that fails here will fail in Dropline too, and the raw
output tells you the JSON path:

```bash
curl -sSv -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/json" \
  -F "file=@/tmp/test.png" \
  -F "album_id=3" \
  https://img.example.com/api/upload | jq
```

Then transcribe: each `-H` is a custom header (or the auth kind), each non-file
`-F` is an extra form field, the `-F` with `@` names the file field.

## Filenames

The multipart part's `filename` is the **last path segment** of your rendered
[object key](/docs/guide/templates). If your API derives the stored name from
it, a key template of `{{base}}-{{rand}}.{{ext}}` gives you control. Most hosts
assign their own name and ignore it.

## Next

[Custom binary PUT →](/docs/hosts/custom-binary)
