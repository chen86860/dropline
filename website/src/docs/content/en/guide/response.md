---
title: Reading the response
description: How Dropline pulls the public link out of an upload API's response — JSON path syntax including array indices, plain-text bodies, and the final URL template that rewrites a relative path onto your CDN domain.
---

# Reading the response

Your host replies with something. Dropline's job is to turn that something into
one URL. Two fields do it, and they run in order.

1. **JSON path** — pick a value out of the response body → `{{result}}`
2. **Final URL template** — optionally rewrite it into the URL you actually want

Both live under **Settings → Hosts → your profile → Response**. They apply to
the `multipart/form-data` and binary engines; the
[S3 engine](/docs/hosts/s3) constructs its URL from the bucket and key instead
and does not use the JSON path.

## JSON path

A dot-separated path into the parsed JSON. Each segment is either an object key
or an **array index**.

Given this response:

```json
{
  "status": "success",
  "data": {
    "url": "https://i.example.com/2026/abc.png",
    "thumb": "https://i.example.com/2026/abc.thumb.png"
  }
}
```

the path is:

```text
data.url
```

Given a response that wraps results in an array:

```json
{
  "files": [
    { "url": "https://i.example.com/abc.png", "size": 20481 }
  ]
}
```

the index is just another segment:

```text
files.0.url
```

Numbers are accepted as well as strings — a response whose link is a bare
numeric id still works, and the value is stringified.

### When the body *is* the URL

Many self-hosted endpoints answer with the link and nothing else:

```text
https://files.example.com/2026/08/abc.png
```

**Leave the JSON path empty.** Dropline then takes the whole response body,
trims surrounding whitespace and newlines, and uses that as `{{result}}`. This
is also the right setting for an endpoint that returns an empty body — pair it
with a final URL template built from `{{key}}`.

### Finding the right path

If you do not know the response shape, the fastest route is **Test Upload**. On
failure Dropline shows the message; on an unparseable path it says so
explicitly:

```text
Path `data.url` not found in the response
```

Failing that, run the upload once with `curl` and look:

```bash
curl -sS -F "file=@test.png" \
     -H "Authorization: Bearer $TOKEN" \
     https://your-host.example.com/api/upload | jq
```

## Final URL template

**Optional.** Leave it empty and `{{result}}` is used as-is — correct whenever
your API already returns an absolute URL.

Fill it in when it does not. Every [template
variable](/docs/guide/templates) is available here, plus `{{result}}`.

### Relative path → absolute URL

The API returns `2026/08/abc.png`, and your files are served from a CDN domain:

```text
https://cdn.example.com/{{result}}
```

### Ignore the response, build from the key

The API returns nothing useful, but you already know where the file went,
because your key template put it there:

```text
https://files.example.com/{{key}}
```

Pair this with an empty JSON path.

### Swap the domain

The API returns an origin URL and you serve through a CDN in front of it. There
is no string-replace function, so build the URL from the key instead:

```text
https://cdn.example.com/{{key}}
```

## Diagnosing the two failure messages

| Message | Cause | Fix |
| --- | --- | --- |
| `The response is not valid JSON, cannot read path …` | You set a JSON path, but the body is HTML, plain text or empty | Empty the JSON path if the body is the URL; otherwise the request is probably being rejected before it reaches the upload handler — check the URL and auth |
| `Path … not found in the response` | The body parsed, but that path is not in it | Run the request with `curl`, look at the real shape, correct the path |
| `The value at path … is not a string` | The path landed on an object or array, not a leaf | Add the missing final segment, e.g. `data.links` → `data.links.url` |

## Next

[Credentials and privacy →](/docs/guide/security)
