---
title: Troubleshooting
description: Every error Dropline can show and what to change — Gatekeeper on first launch, a missing Finder menu item, HTTP 401/403/404/413, SignatureDoesNotMatch, JSON path failures and links that 404 in the browser.
---

# Troubleshooting

## The app will not open

> "Dropline" is damaged and can't be opened. / …can't be opened because it is
> from an unidentified developer.

The build is ad-hoc signed rather than notarised, so Gatekeeper blocks the first
launch. Right-click the app and choose **Open**, or:

```bash
xattr -dr com.apple.quarantine /Applications/Dropline.app
```

This is a one-time step. It applies to the Homebrew cask too.

## There is no Dropline item in the Finder right-click menu

In order:

1. **Approve the extension.** System Settings → General → Login Items &
   Extensions → **Finder Extensions** → turn Dropline on.
2. **Check the setting.** Settings → General → Finder Context Menu → *Show as*
   must not be *Don't show*.
3. **Relaunch Finder** if it still does not appear: `killall Finder`.

The command is always available under **Keyboard → Keyboard Shortcuts →
Services → Files and Folders**, even when the context-menu item is hidden.

## Upload errors

Every message below comes from Dropline itself and appears next to **Test
Upload** and on the failed row in the window.

### `Incomplete configuration: missing Bucket`

### `Incomplete configuration: missing Access Key ID / Secret Access Key`

An S3-family profile with an empty required field. Note the secret access key is
held in the keychain, so it can look "filled in" in the console and still be
empty here — retype it.

### `Invalid upload URL: …`

The endpoint is empty, or has no scheme. It must start with `http://` or
`https://`. If the URL uses `{{key}}` and the rendered value looks wrong, check
the object key template.

### `HTTP 401` / `HTTP 403`

Authentication. What to check depends on the engine:

| Engine | Look at |
| --- | --- |
| multipart / binary | The auth kind, the header or parameter name, and the secret. Imgur wants the *whole* string `Client-ID abc123` as the header value, not just the id |
| S3-compatible | Access key ID and secret; then whether the key is allowed `s3:PutObject` on that bucket and prefix |

A `403` on S3 that is not a signature error is almost always a permissions
policy, not a wrong key.

### `HTTP 403 … SignatureDoesNotMatch`

The request was signed, but with the wrong material. Usually one of:

- **Region mismatch.** AWS is strict: the region in the profile must match the
  bucket's. R2 and most self-hosted gateways accept `auto` or `us-east-1`.
- **A trailing slash or path on the endpoint.** Give the host origin only —
  `https://<account>.r2.cloudflarestorage.com`, not `…/my-bucket`. The bucket
  goes in its own field, because Dropline signs path-style requests
  (`endpoint/bucket/key`).
- **The secret was pasted with whitespace.** Retype it.

### `HTTP 404`

The endpoint is wrong, or — on S3 — the bucket does not exist in that account or
region. On a self-hosted host, check whether the API path includes a version
segment you omitted.

### `HTTP 413`

The file is larger than the host allows. On self-hosted PHP hosts this is
`upload_max_filesize` / `post_max_size` in `php.ini`, or `client_max_body_size`
in nginx. Public image hosts have hard limits — SM.MS is 5 MB, Imgur 20 MB for
non-animated images.

### `HTTP 429`

Rate limited. Lower **Settings → General → Concurrent uploads** to 1 and wait.

### `The response is not valid JSON, cannot read path …`

The request reached something, but got HTML, plain text or an empty body back.
Either the JSON path should be empty (the body *is* the URL), or the request
never reached the upload handler — a login page or an error page is a common
body here. See [Reading the response](/docs/guide/response).

### `Path … not found in the response`

The path is wrong for this API. Run the same upload with `curl` and look at the
real shape:

```bash
curl -sS -F "file=@test.png" -H "Authorization: Bearer $TOKEN" \
     https://your-host.example.com/api/upload | jq
```

### `The value at path … is not a string`

The path stops on an object or an array. Add the last segment — `data.links`
usually needs to be `data.links.url`.

## The upload succeeds but the link 404s in the browser

The file went up; the URL is wrong or the object is not public.

1. **Is the object public?** S3 needs a bucket policy or an ACL; R2 needs a
   public bucket domain or a custom domain bound to it. A signed-URL-only bucket
   will always 404 (or 403) for a bare link.
2. **Is the public base URL right?** Dropline joins it to the key as
   `base + "/" + key`, with no other rewriting. If your CDN serves the bucket
   at a sub-path, include that sub-path in the base URL.
3. **Is the CDN cache negative?** Some CDNs cache a 404 from before the object
   existed. Purge that path.
4. **Compare against the storage console.** Find the object in the bucket
   browser and copy the path it reports; if it differs from the tail of your
   link, the key template or the base URL is the culprit.

## Uploads are slow or stall

- The per-file transfer timeout is one hour, so large videos will not be cut
  off — but a stalled connection will sit there. Cancel the row and retry.
- Dropline waits for connectivity rather than failing instantly when the network
  drops, which can look like a hang. Check the connection first.
- Lower concurrency if your uplink is saturated; eight parallel uploads on a
  slow connection are slower overall than three.

## Notifications never appear

macOS asks once. If you dismissed it, re-enable Dropline under **System Settings
→ Notifications**, and check **Settings → General → Send a system notification**
is on.

## Still stuck

Open an issue with the exact error text and the engine you are using:
[github.com/chen86860/dropline/issues](https://github.com/chen86860/dropline/issues).
Never paste a secret access key or a token into an issue.

## Next

[Build from source →](/docs/guide/build-from-source)
