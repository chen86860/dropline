---
title: Template variables
description: Every {{variable}} Dropline substitutes — filename, base, ext, uuid, date, datetime, timestamp, rand, key and result — where each one is available, and recipes for common object-key layouts.
---

# Template variables

Several fields in a host profile are templates. Anything of the form
`{{name}}` — or `{{ name }}`, with spaces — is replaced before the request goes
out. Unknown names are left alone, which makes a typo visible in the result
rather than silent.

## The variables

| Variable | Value | Example |
| --- | --- | --- |
| `{{filename}}` | The original filename, unchanged, with extension | `My Screenshot.PNG` |
| `{{base}}` | The filename without extension, **sanitised** | `My-Screenshot` |
| `{{ext}}` | The extension, lowercased, no dot | `png` |
| `{{uuid}}` | A fresh UUID, lowercase hex, dashes removed — 32 chars | `a1f3c9e04b7d…` |
| `{{date}}` | Today, local time, as `yyyy/MM/dd` | `2026/08/19` |
| `{{datetime}}` | Now, local time, as `yyyyMMddHHmmss` | `20260819142233` |
| `{{timestamp}}` | Unix time in **seconds** | `1787148153` |
| `{{rand}}` | Six lowercase characters from a fresh UUID | `a1f3c9` |
| `{{key}}` | The rendered object key — see below | `images/2026/08/19/a1f3c9….png` |
| `{{result}}` | The URL parsed out of the response — see below | `https://i.host/abc.png` |

### About `{{base}}`

`{{base}}` is sanitised for URLs. ASCII letters and digits, `-`, `_`, `.` and
CJK characters survive; **everything else becomes a dash**, spaces included. Use
it when you want the remote name to resemble the local one. Use `{{filename}}`
only where the raw name is genuinely wanted — it can contain characters that
need escaping.

### About `{{key}}` and `{{result}}`

These two are not file properties; they are results of earlier steps, so they
only exist once that step has run.

- `{{key}}` is your **object key template** after rendering. It becomes
  available immediately afterwards, so the upload URL, headers, form fields and
  the final URL template can all refer to it.
- `{{result}}` is whatever the [response parsing](/docs/guide/response) step
  produced. It exists **only** in the final URL template.

## The object key template

**Settings → Hosts → your profile → Remote filename / object key template.**

This is the path the file gets on the far end. The default is:

```text
{{date}}/{{uuid}}.{{ext}}
```

which produces `2026/08/19/a1f3c9e04b7d….png`. The S3-family presets ship with
a folder prefix instead:

```text
images/{{date}}/{{uuid}}.{{ext}}
```

What the key is *used for* depends on the engine:

| Engine | Role of the key |
| --- | --- |
| S3-compatible | The object key. This is literally where the file lands. |
| Binary `PUT`/`POST` | Usually interpolated into the endpoint as `{{key}}` |
| `multipart/form-data` | Its **last path segment** becomes the `filename` in the form part; most image hosts ignore it and assign their own name |

## Recipes

**Date folders, unguessable name** — the default, and the right answer most of
the time. No collisions, no information leaked by the URL.

```text
images/{{date}}/{{uuid}}.{{ext}}
```

**Readable, still collision-proof** — keeps the original name so the URL means
something, with a short suffix so two files called `chart.png` cannot overwrite
each other.

```text
blog/{{date}}/{{base}}-{{rand}}.{{ext}}
```

**Flat, sortable** — one folder, names that sort chronologically.

```text
{{datetime}}-{{rand}}.{{ext}}
```

**Grouped by type** — separate prefixes so lifecycle rules can treat images and
video differently.

```text
{{ext}}/{{date}}/{{uuid}}.{{ext}}
```

**Preserve the name exactly** — only safe when you know names are unique, since
a repeat silently overwrites.

```text
uploads/{{base}}.{{ext}}
```

## Where templates are accepted

| Field | Variables available |
| --- | --- |
| Object key template | everything except `{{key}}` and `{{result}}` |
| Upload URL | everything except `{{result}}`, including `{{key}}` |
| Custom header values | everything except `{{result}}`, including `{{key}}` |
| Extra form field values | everything except `{{result}}`, including `{{key}}` |
| Final URL template | everything, including `{{key}}` and `{{result}}` |

A templated **upload URL** is what makes the binary engine work at all:

```text
https://files.example.com/{{key}}
```

Each upload then `PUT`s to its own path.

## A worked example

Profile: Cloudflare R2, bucket `assets`, public base URL
`https://cdn.example.com`, key template `images/{{date}}/{{uuid}}.{{ext}}`.

You drop `Q3 Revenue.PNG` on 19 August 2026:

```text
{{filename}} → Q3 Revenue.PNG
{{base}}     → Q3-Revenue
{{ext}}      → png
{{date}}     → 2026/08/19
{{uuid}}     → 6b1d4f2a9c8e47b0a3d5e7f1c2b4a6d8

{{key}}      → images/2026/08/19/6b1d4f2a9c8e47b0a3d5e7f1c2b4a6d8.png
result       → https://cdn.example.com/images/2026/08/19/6b1d4f2a9c8e47b0a3d5e7f1c2b4a6d8.png
```

That last line is what lands on your clipboard.

## Next

[Reading the response →](/docs/guide/response)
