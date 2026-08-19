---
title: MinIO
description: Configure Dropline for a self-hosted MinIO or any S3-compatible gateway — endpoints with ports, path-style addressing, a scoped access key, and an anonymous download policy.
---

# MinIO

**Engine:** S3-compatible (AWS SigV4) · **Preset:** `MinIO / self-hosted S3`

This page is also the answer for **any** S3-compatible server you run yourself —
Garage, SeaweedFS, Ceph RGW, Zenko, Backblaze B2's S3 endpoint, Wasabi,
DigitalOcean Spaces. The fields are the same; only the endpoint changes.

## Configuration

Settings → Hosts → **+** → **MinIO / self-hosted S3**.

| Field | Value |
| --- | --- |
| Endpoint | `http://127.0.0.1:9000`, or `https://s3.example.com` |
| Region | `us-east-1` — MinIO's default. Any value works if it matches the server's |
| Bucket | The bucket name alone |
| Access Key ID | From a MinIO access key |
| Secret Access Key | Its secret — goes to the keychain |
| Public base URL | Optional; only if a CDN or reverse proxy fronts it |
| Object key template | `images/{{date}}/{{uuid}}.{{ext}}` |

**Include the port** if the server does not run on 443 or 80. Dropline signs the
host with its port, so `https://s3.example.com:9000` and
`https://s3.example.com` are different hosts as far as the signature is
concerned — use whichever you actually reach the server on.

Dropline always uses **path-style** addressing (`endpoint/bucket/key`), which is
MinIO's native mode. There is nothing to configure for it, and you do not need
wildcard DNS or virtual-host style.

Other providers' endpoints, for reference:

| Service | Endpoint | Region |
| --- | --- | --- |
| Backblaze B2 | `https://s3.us-west-004.backblazeb2.com` | `us-west-004` |
| Wasabi | `https://s3.eu-central-1.wasabisys.com` | `eu-central-1` |
| DigitalOcean Spaces | `https://fra1.digitaloceanspaces.com` | `fra1` |

## Create a scoped access key

In the MinIO console, **Access Keys → Create access key**, and attach a policy
so a leaked key cannot do more than upload:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:PutObject"],
      "Resource": ["arn:aws:s3:::assets/images/*"]
    }
  ]
}
```

Do not hand Dropline the root credentials from `MINIO_ROOT_USER`.

## Make objects readable

Anonymous download on one prefix, with the `mc` client:

```bash
mc alias set local http://127.0.0.1:9000 ACCESSKEY SECRETKEY
mc anonymous set download local/assets/images
```

Or in the console: bucket → **Anonymous** → add a rule with *readonly* access on
the prefix.

## Serving the links

If MinIO is reachable at a public hostname, leave **Public base URL** empty and
Dropline returns:

```text
https://s3.example.com/assets/images/2026/08/19/a1f3….png
```

If a reverse proxy or CDN serves the bucket at a cleaner path, set the base URL
to it. A typical nginx front-end that strips the bucket:

```text
Public base URL   https://cdn.example.com
```

pairs with a proxy that maps `/` to `/assets/` upstream.

## Localhost caveat

`http://127.0.0.1:9000` is perfect for testing — **Test Upload** will pass — but
the returned link only works on your own machine. Anything you share from a
localhost profile is a dead link for everyone else.

## Common problems

| Symptom | Cause |
| --- | --- |
| Connection refused | MinIO is not running, or the port is wrong |
| `SignatureDoesNotMatch` | The port is missing from the endpoint, or a proxy rewrites the `Host` header |
| `HTTP 403 AccessDenied` | The key's policy does not allow `s3:PutObject` on that prefix |
| `HTTP 404 NoSuchBucket` | Bucket does not exist — MinIO does not create it for you |
| Link 403s | No anonymous download policy on the prefix |
