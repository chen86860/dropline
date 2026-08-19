---
title: Custom binary PUT
description: Upload the raw file body to a WebDAV endpoint, an nginx WebDAV module, a Caddy or Worker receiver — Dropline's binary engine, where the path decides the name, with worked server configs.
---

# Custom binary PUT

**Engine:** Binary `PUT` / `POST` · **Preset:** `Blank · Custom binary PUT`

This engine puts the file's bytes in the request body, with nothing wrapped
around them. No form, no boundary, no fields — just the file and a
`Content-Type` derived from its extension.

It is the right engine whenever **the URL decides where the file goes**: WebDAV,
nginx's DAV module, a Caddy `file_server`, a small Worker or a one-file PHP
receiver.

## What Dropline sends

```http
PUT /files/images/2026/08/19/a1f3c9.png HTTP/1.1
Host: files.example.com
Authorization: Basic dXNlcjpwYXNz
Content-Type: image/png

<the file's bytes>
```

## Configuration

Settings → Hosts → **+** → **Blank · Custom binary PUT**.

| Field | Value |
| --- | --- |
| Upload URL | `https://files.example.com/{{key}}` |
| Method | `PUT` |
| Custom headers | Anything the server needs |
| Authentication | Whichever kind the server uses |
| JSON path | **empty** — these servers return no body |
| Final URL template | `https://files.example.com/{{key}}` |
| Object key template | `images/{{date}}/{{uuid}}.{{ext}}` |

The shape is always the same: `{{key}}` appears **twice**, once in the URL you
write to and once in the URL you read from. If the two hostnames differ — you
write to an origin and read from a CDN — that is exactly where the difference
goes.

Leaving the JSON path empty makes Dropline treat the response body as the
result, which for an empty `201 Created` is an empty string; the final URL
template then supplies the real link.

## Server recipes

### nginx with the DAV module

```nginx
server {
    server_name files.example.com;
    root /var/www/files;

    location / {
        # Reads are public
        autoindex off;
    }

    location /images/ {
        dav_methods PUT;
        create_full_put_path on;
        dav_access user:rw group:r all:r;
        client_max_body_size 512m;

        auth_basic "upload";
        auth_basic_user_file /etc/nginx/.htpasswd;

        limit_except GET HEAD { }
    }
}
```

`create_full_put_path on` is required — without it, a `PUT` to a path whose
directories do not yet exist fails with `409 Conflict`, and a date-based key
template creates a new directory every day.

In Dropline: authentication **Basic**, username in the name field, password as
the secret.

### Caddy

```text
files.example.com {
    root * /var/www/files
    file_server

    @upload method PUT
    handle @upload {
        basicauth {
            uploader $2a$14$…hash…
        }
        rewrite * /upload{path}
        reverse_proxy localhost:8080
    }
}
```

Caddy has no built-in `PUT` receiver, so pair it with a tiny upstream — or use
the `webdav` plugin.

### A Cloudflare Worker writing to R2

Useful when you want a custom auth scheme in front of R2 rather than S3
credentials on the client.

```ts
export default {
  async fetch(request: Request, env: Env) {
    if (request.method !== 'PUT') return new Response('Method not allowed', { status: 405 })
    if (request.headers.get('Authorization') !== `Bearer ${env.UPLOAD_TOKEN}`) {
      return new Response('Unauthorized', { status: 401 })
    }

    const key = new URL(request.url).pathname.slice(1)
    await env.BUCKET.put(key, request.body, {
      httpMetadata: { contentType: request.headers.get('Content-Type') ?? 'application/octet-stream' },
    })

    return new Response(null, { status: 201 })
  },
}
```

In Dropline: upload URL `https://upload.example.com/{{key}}`, authentication
**Bearer Token**, JSON path empty, final URL template
`https://cdn.example.com/{{key}}`.

### Generic WebDAV

Most WebDAV servers — Nextcloud, `rclone serve webdav`, Synology — accept a
plain `PUT`:

| Field | Value |
| --- | --- |
| Upload URL | `https://dav.example.com/remote.php/dav/files/user/{{key}}` |
| Method | `PUT` |
| Authentication | Basic |

Note that WebDAV storage is usually **not** publicly readable, so the final URL
template needs to point at whatever share link the server exposes — for
Nextcloud, a public share of the folder.

## When the server does return a body

Some receivers reply with the URL as plain text:

```text
https://files.example.com/images/2026/08/19/a1f3c9.png
```

Leave the JSON path empty — Dropline trims the body and uses it — and leave the
final URL template empty too, so the server's answer wins.

If it returns JSON, set the JSON path as usual; see
[Reading the response](/docs/guide/response).

## Common problems

| Symptom | Cause |
| --- | --- |
| `HTTP 409` | Parent directory does not exist — `create_full_put_path on` in nginx |
| `HTTP 405` | The server does not allow `PUT` on that path |
| `HTTP 401` | Wrong auth kind; check whether the server wants Basic or a token |
| `HTTP 411` | The server requires `Content-Length` on a chunked body — rare; try `POST` |
| Upload succeeds, link 404s | The read hostname or path differs from the write one — fix the final URL template |
| The clipboard gets an empty string | JSON path empty *and* final URL template empty, with an empty response body |
