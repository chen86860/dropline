---
title: Aliyun OSS
description: Configure Dropline for Aliyun OSS through its S3-compatible gateway — region endpoints, RAM user credentials, public read ACLs and binding a CDN domain.
---

# Aliyun OSS

**Engine:** S3-compatible (AWS SigV4) · **Preset:** `Aliyun OSS (S3-compatible)`

Aliyun OSS speaks its own API *and* an S3-compatible one. Dropline uses the
latter, which is why the profile looks exactly like the S3 profile.

## Configuration

Settings → Hosts → **+** → **Aliyun OSS (S3-compatible)**.

| Field | Value |
| --- | --- |
| Endpoint | `https://oss-cn-hangzhou.aliyuncs.com` — your bucket's region |
| Region | The same region id: `oss-cn-hangzhou` |
| Bucket | The bucket name alone |
| Access Key ID | From a RAM user |
| Secret Access Key | Its AccessKey Secret — goes to the keychain |
| Public base URL | Your CDN or bucket domain |
| Object key template | `images/{{date}}/{{uuid}}.{{ext}}` |

### Region endpoints

Endpoint and region always agree. Common ones:

| Region | Endpoint |
| --- | --- |
| `oss-cn-hangzhou` | `https://oss-cn-hangzhou.aliyuncs.com` |
| `oss-cn-shanghai` | `https://oss-cn-shanghai.aliyuncs.com` |
| `oss-cn-beijing` | `https://oss-cn-beijing.aliyuncs.com` |
| `oss-cn-shenzhen` | `https://oss-cn-shenzhen.aliyuncs.com` |
| `oss-cn-hongkong` | `https://oss-cn-hongkong.aliyuncs.com` |
| `oss-ap-southeast-1` | `https://oss-ap-southeast-1.aliyuncs.com` |
| `oss-us-west-1` | `https://oss-us-west-1.aliyuncs.com` |

Use the **public** endpoint, not the internal `-internal` one — that only
resolves from inside Aliyun's network.

Do not put the bucket in the endpoint. OSS's own documentation shows
`https://bucket.oss-cn-hangzhou.aliyuncs.com`, but Dropline signs path-style
requests and appends the bucket itself.

## Create a RAM user

Never use the primary account's AccessKey. In the **RAM console**:

1. **Identities → Users → Create User**, with *OpenAPI Access* enabled.
2. Save the AccessKey ID and Secret.
3. **Permissions → Grant Permission**, and attach a custom policy:

```json
{
  "Version": "1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "oss:PutObject",
      "Resource": "acs:oss:*:*:my-assets/images/*"
    }
  ]
}
```

## Make objects readable

Either set the whole bucket's ACL to **public-read** (OSS console → bucket →
*Access Control*), or leave it private and serve through CDN with a signed
origin. Dropline uploads without an ACL header, so objects inherit the bucket's
setting.

## Bind a domain

The default bucket domain works:

```text
https://my-assets.oss-cn-hangzhou.aliyuncs.com
```

but it is throttled and not cached. In production, bind a custom domain under
bucket → **Transmission → Domain Names**, optionally fronted by Aliyun CDN, and
use that as the **Public base URL**.

> **Mainland China hosting requires an ICP filing (备案)** for any custom domain
> pointing at a mainland region. Regions outside the mainland — Hong Kong,
> Singapore, US — do not.

## The link you get back

With a public base URL of `https://cdn.example.com`:

```text
https://cdn.example.com/images/2026/08/19/a1f3….png
```

## Common problems

| Symptom | Cause |
| --- | --- |
| `SignatureDoesNotMatch` | Region and endpoint disagree, or the bucket is inside the endpoint |
| Connection times out | You used the `-internal` endpoint from outside Aliyun |
| `HTTP 403` | The RAM policy does not allow `oss:PutObject` on that path |
| Link 403s in a browser | Bucket ACL is private and no CDN is fronting it |
