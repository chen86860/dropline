---
title: Tencent COS
description: Configure Dropline for Tencent Cloud COS through its S3-compatible API — the bucket name with APPID, region endpoints, CAM sub-account keys and public read permissions.
---

# Tencent COS

**Engine:** S3-compatible (AWS SigV4) · **Preset:** `Tencent COS (S3-compatible)`

## Configuration

Settings → Hosts → **+** → **Tencent COS (S3-compatible)**.

| Field | Value |
| --- | --- |
| Endpoint | `https://cos.ap-guangzhou.myqcloud.com` — your bucket's region |
| Region | The same region id: `ap-guangzhou` |
| Bucket | **`name-APPID`**, e.g. `my-assets-1250000000` |
| Access Key ID | `SecretId` from a CAM sub-account |
| Secret Access Key | `SecretKey` — goes to the keychain |
| Public base URL | Your bucket or CDN domain |
| Object key template | `images/{{date}}/{{uuid}}.{{ext}}` |

### The bucket name includes your APPID

This is the one COS-specific gotcha. A COS bucket displayed as `my-assets` is
actually named `my-assets-1250000000`, with your ten-digit APPID appended. The
console shows the full name in the bucket list; use that, in full, in the
**Bucket** field.

### Region endpoints

| Region | Endpoint |
| --- | --- |
| `ap-guangzhou` | `https://cos.ap-guangzhou.myqcloud.com` |
| `ap-shanghai` | `https://cos.ap-shanghai.myqcloud.com` |
| `ap-beijing` | `https://cos.ap-beijing.myqcloud.com` |
| `ap-chengdu` | `https://cos.ap-chengdu.myqcloud.com` |
| `ap-hongkong` | `https://cos.ap-hongkong.myqcloud.com` |
| `ap-singapore` | `https://cos.ap-singapore.myqcloud.com` |
| `na-siliconvalley` | `https://cos.na-siliconvalley.myqcloud.com` |

## Create a sub-account key

In the **CAM console**, not the root account:

1. **Users → Create User → Custom Create**, with programmatic access.
2. Save the `SecretId` and `SecretKey`.
3. Attach a custom policy scoped to the upload prefix:

```json
{
  "version": "2.0",
  "statement": [
    {
      "effect": "allow",
      "action": ["cos:PutObject"],
      "resource": [
        "qcs::cos:ap-guangzhou:uid/1250000000:my-assets-1250000000/images/*"
      ]
    }
  ]
}
```

Replace the region, the uid (your APPID) and the bucket to match.

## Make objects readable

COS console → bucket → **Permission Management → Public Read/Private Write** for
the whole bucket, or a bucket policy granting `cos:GetObject` to `*` on the
prefix only. Dropline sends no ACL header, so objects inherit the bucket.

## The default and CDN domains

The default bucket domain is:

```text
https://my-assets-1250000000.cos.ap-guangzhou.myqcloud.com
```

For anything with traffic, enable **Domain & Transfer Management → Default CDN
Acceleration Domain**, or bind your own, and use that as the **Public base URL**.

> A custom domain on a mainland-China region needs an ICP filing (备案).

## The link you get back

```text
https://cdn.example.com/images/2026/08/19/a1f3….png
```

## Common problems

| Symptom | Cause |
| --- | --- |
| `HTTP 404 NoSuchBucket` | The APPID suffix is missing from the bucket name |
| `SignatureDoesNotMatch` | Region and endpoint disagree, or the bucket is in the endpoint |
| `HTTP 403` | CAM policy missing `cos:PutObject` on that path, or root keys with MFA required |
| Link 403s | Bucket is private-read |
