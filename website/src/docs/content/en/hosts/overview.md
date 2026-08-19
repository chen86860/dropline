---
title: Hosts overview
description: Every upload target Dropline supports — nine presets across three engines — with the field reference for each engine, the five authentication kinds, and a decision table for picking one.
---

# Hosts overview

A **host profile** is one upload target: an endpoint, credentials, and the rules
for turning a response into a link. You can keep as many as you like side by
side, switch the default at any time, and upload to several concurrently.

This page is the reference for what the fields mean. Each service then has its
own page with the exact values to type.

## Pick a host

| Your situation | Use |
| --- | --- |
| You already have an AWS account | [Amazon S3](/docs/hosts/s3) |
| You want zero egress fees | [Cloudflare R2](/docs/hosts/r2) |
| Your users are in mainland China | [Aliyun OSS](/docs/hosts/oss) or [Tencent COS](/docs/hosts/cos) |
| You run your own storage | [MinIO](/docs/hosts/minio) |
| You want a free image host, no account | [SM.MS](/docs/hosts/smms) |
| You want a free image host with an API key | [Imgur](/docs/hosts/imgur) |
| You self-host an image gallery | [Lsky Pro / Chevereto](/docs/hosts/lsky-chevereto) or [EasyImage](/docs/hosts/easyimage) |
| Your API is not on this list | [Custom multipart](/docs/hosts/custom-multipart) or [Custom binary PUT](/docs/hosts/custom-binary) |

## The three engines

The **Upload method** picker at the top of the profile editor chooses one of
three request shapes. Everything below it changes to match.

### `multipart/form-data`

A normal HTML form post — the file as one part, optional extra fields alongside
it. This is what almost every image-host API speaks.

| Field | Meaning |
| --- | --- |
| Upload URL | The endpoint. Templated, so `{{key}}` and friends work |
| Method | `POST`, `PUT` or `PATCH` — `POST` for nearly everything |
| File field name | The form field the file goes in: `file`, `image`, `smfile` |
| Custom headers | Extra request headers; values are templated |
| Extra form fields | Extra parts alongside the file; values are templated |
| JSON path | Where the link is in the response — see [Reading the response](/docs/guide/response) |
| Final URL template | Optional rewrite of that value |

The multipart part's `filename` is the **last path segment** of your rendered
object key. Most hosts ignore it and assign their own name.

### Binary `PUT` / `POST`

The file's bytes are the entire request body, with a `Content-Type` derived from
the extension. There is no form, so there are no form fields and no file field
name.

This is the engine for WebDAV-style endpoints and small self-hosted receivers,
where the **path decides the name**:

```text
Upload URL   https://files.example.com/{{key}}
Method       PUT
JSON path    (empty)
Final URL    https://files.example.com/{{key}}
```

### S3-compatible (AWS SigV4)

A signed `PUT` of the object, using AWS Signature Version 4. Dropline always
signs **path-style** requests — `endpoint/bucket/key` — which is what R2, MinIO
and self-hosted gateways expect, and which AWS still accepts.

| Field | Meaning |
| --- | --- |
| Endpoint | The service origin. Leave empty for AWS, which then uses `https://s3.<region>.amazonaws.com` |
| Region | `auto`, `us-east-1`, `oss-cn-hangzhou`… |
| Bucket | The bucket name, on its own — never part of the endpoint |
| Access Key ID | Not secret; stored in the config file |
| Secret Access Key | Secret; stored in the **keychain** |
| Public base URL | Optional. Empty means the link is `endpoint/bucket/key` |

There is no JSON path here: S3 replies with an empty body on success, so the URL
is constructed rather than parsed.

## The five authentication kinds

For the multipart and binary engines. The secret itself always goes to the
keychain, whichever kind you pick.

| Kind | What Dropline sends |
| --- | --- |
| None | Nothing. Used when a token rides in a form field instead |
| Bearer Token | `Authorization: Bearer <secret>` |
| Basic | `Authorization: Basic base64(<username>:<secret>)` |
| Custom header | `<header name>: <secret>` — verbatim, no prefix added |
| URL query parameter | `?<parameter name>=<secret>` appended to the upload URL |

**Custom header** is the escape hatch. Because the value is sent verbatim, an
API wanting `Authorization: Client-ID abc123` is configured by setting the
header name to `Authorization` and the value to the whole string
`Client-ID abc123`.

## Managing profiles

- **+** adds a profile from a preset. **−** deletes the selected one.
- **Set as Default** marks which profile new uploads use; the default carries a
  green tick in the list.
- **Test Upload** sends an 8×8 PNG through the profile and reports the URL or
  the error. Use it after every change.
- Deleting a profile deletes its keychain entry with it.

## All presets at a glance

| Preset | Engine | Auth | JSON path |
| --- | --- | --- | --- |
| [Amazon S3](/docs/hosts/s3) | S3 | SigV4 | — |
| [Cloudflare R2](/docs/hosts/r2) | S3 | SigV4 | — |
| [Aliyun OSS](/docs/hosts/oss) | S3 | SigV4 | — |
| [Tencent COS](/docs/hosts/cos) | S3 | SigV4 | — |
| [MinIO](/docs/hosts/minio) | S3 | SigV4 | — |
| [SM.MS](/docs/hosts/smms) | multipart | Custom header | `data.url` |
| [Imgur](/docs/hosts/imgur) | multipart | Custom header | `data.link` |
| [Lsky Pro / Chevereto](/docs/hosts/lsky-chevereto) | multipart | Bearer | `data.links.url` |
| [EasyImage](/docs/hosts/easyimage) | multipart | form field | `url` |
| [Custom HTTP](/docs/hosts/custom-multipart) | multipart | any | `url` |
| [Custom binary PUT](/docs/hosts/custom-binary) | binary | any | *(empty)* |
