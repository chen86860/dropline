---
title: Credentials and privacy
description: Where Dropline stores access keys and tokens, what leaves your Mac and what does not, and how to scope bucket credentials so an upload key cannot do more than upload.
---

# Credentials and privacy

## Nothing passes through anyone else's server

Dropline has no backend. Every request goes from your Mac directly to the
endpoint in your host profile. There is no account to create, no sign-in, no
analytics and no crash reporting. The only network traffic Dropline makes on its
own is the Sparkle update check, which fetches a signed appcast and sends
nothing about you or your files.

## Where secrets live

Secrets go in the **macOS keychain**, under the service `dev.emmmm.Dropline`,
one entry per host profile. That covers:

- Bearer tokens
- Basic auth passwords
- Custom header and query-parameter values
- S3 / R2 / OSS / COS secret access keys

Everything else — profile names, endpoints, regions, buckets, access key **IDs**,
templates, settings and upload history — is in
`~/Library/Preferences/dev.emmmm.Dropline.plist`, which is plain and readable.

That split is why the preferences file is safe to sync, back up or paste into a
bug report, and why keychain entries are marked *after first unlock*: they are
unavailable while the Mac is locked at boot, and available afterwards.

### Verifying it yourself

```bash
# The config file — search it for your secret; it is not there
plutil -p ~/Library/Preferences/dev.emmmm.Dropline.plist

# The keychain entries — one per configured profile
security find-generic-password -s dev.emmmm.Dropline
```

## Scope your bucket credentials

The single most useful thing you can do is give Dropline a key that can *only*
do what Dropline does: put objects into one prefix of one bucket. Then a leaked
key cannot read your bucket, cannot delete anything and cannot touch anything
else in the account.

### AWS S3 — a minimal policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::my-assets/images/*"
    }
  ]
}
```

Attach it to a dedicated IAM user whose access key you give to Dropline. Note
there is no `s3:GetObject` and no `s3:ListBucket` — Dropline never needs either.

### Cloudflare R2

Create an **API token** scoped to *Object Read & Write* on the single bucket, in
the R2 dashboard. R2 tokens cannot be narrowed to a prefix, so a bucket per
purpose is the unit of isolation there.

### Aliyun OSS and Tencent COS

Use a RAM user (OSS) or a sub-account with a CAM policy (COS), granting only
`PutObject` on the bucket path you upload to. Never use the account's root
credentials.

## Public buckets and what a URL reveals

For the returned link to work in a browser, the object has to be publicly
readable — via a bucket policy, a public R2 domain, or a CDN in front. Two
consequences follow:

- **Anyone with the URL can fetch the file.** Treat every upload as public.
- **The URL is the only secret.** That is why the default key template ends in
  a `{{uuid}}` — a 32-character random name is not guessable, whereas
  `uploads/invoice.pdf` is.

If you use `{{base}}` or `{{filename}}` in your key template, remember that the
local filename becomes part of a public URL.

## Third-party image hosts

The privacy story above is about the transport. If your host profile points at
SM.MS or Imgur, then SM.MS or Imgur has your file, subject to their terms — they
can delete it, and in Imgur's case anonymous uploads have no owner and no
guarantee. Nothing Dropline does changes that. For anything you need to keep,
use storage you control.

## This website

The app sends nothing about you; this website does count visits. Page views
are recorded with [PostHog](https://posthog.com), through the proxy
`a.emmmm.dev`, so the numbers show which pages people read and which docs they
cannot find. Automatic click capture is switched off. PostHog stores an
anonymous visitor ID in a cookie and local storage; block them in your browser
and the site works exactly the same.

## Rotating a secret

Change it in the provider's console, then paste the new value into **Settings →
Hosts → your profile**. The keychain entry is overwritten on the spot. Click
**Test Upload** to confirm before you revoke the old key.

## Next

[Troubleshooting →](/docs/guide/troubleshooting)
