---
title: 兰空图床 / Chevereto
description: 把 Dropline 配到自建的兰空图床（Lsky Pro）或 Chevereto —— v1 接口地址、Bearer token、Accept 请求头、储存策略与相册字段。
---

# 兰空图床 / Chevereto

**引擎：** `multipart/form-data` · **预设：** `Lsky Pro / Chevereto`

两者都是自建的图床程序，上传接口用 token 鉴权。预设针对的是**兰空图床 v2** 的接口形状；Chevereto 差别不大，改一两个字段就能用，下面有说明。

## 配置 —— 兰空图床

设置 → 图床 → **+** → **Lsky Pro / Chevereto**。

| 字段 | 值 |
| --- | --- |
| 上传地址 | `https://your-domain.com/api/v1/upload` |
| 方法 | `POST` |
| 文件字段名 | `file` |
| 自定义请求头 | `Accept: application/json` |
| 鉴权方式 | **Bearer Token** |
| Token | `1|abcdefg…` —— 整串，存进钥匙串 |
| JSON path | `data.links.url` |
| 最终链接模板 | *(留空)* |

`Accept: application/json` 这个头不是可选的。没有它，兰空图床出错时会返回一个 HTML 错误页，于是 Dropline 报的是「响应不是合法 JSON」而不是真正的问题。

### 拿 Token

在网页后台里 —— 登录后进**设置 → 接口 Token** —— 或者用接口拿：

```bash
curl -sS -X POST https://your-domain.com/api/v1/tokens \
     -H "Accept: application/json" \
     -F "email=you@example.com" \
     -F "password=your-password"
```

响应里的 `data.token` 形如 `1|xxxxxxxx…`。整串粘进去，开头的 `1|` 是 token 的一部分。

### 可选的额外表单字段

兰空图床还接受更多参数，用 Dropline 的**额外表单字段**和文件一起发过去：

| 键 | 值 | 含义 |
| --- | --- | --- |
| `strategy_id` | `1` | 写到哪个储存策略（本地、S3…） |
| `album_id` | `3` | 放进指定相册 |
| `permission` | `1` | `1` 公开，`0` 私有 |
| `expired_at` | `2026-12-31 23:59:59` | 自动删除时间 |

值支持模板，所以 `expired_at` 想用 `{{date}}` 拼也可以。

### 响应

```json
{
  "status": true,
  "message": "上传成功",
  "data": {
    "key": "abc123",
    "name": "a1f3c9.png",
    "links": {
      "url": "https://your-domain.com/i/2026/08/19/a1f3c9.png",
      "html": "<img src=\"…\" alt=\"…\" />",
      "markdown": "![](…)"
    }
  }
}
```

`data.links.url` 是直链。`data.links.markdown` 也在，但更建议用 Dropline 自己的**复制为 Markdown** —— 它用的是原始文件名作为 alt。

## 配置 —— Chevereto

Chevereto 的 v1 接口有两处不同：

| 字段 | 值 |
| --- | --- |
| 上传地址 | `https://your-domain.com/api/1/upload` |
| 文件字段名 | `source` |
| 鉴权方式 | **URL 查询参数**，参数名 `key` |
| JSON path | `image.url` |

Chevereto 的 key 是通过 `?key=…` 传的，不走 Bearer 头。它的响应形如：

```json
{
  "status_code": 200,
  "image": {
    "url": "https://your-domain.com/images/2026/08/19/abc.png",
    "display_url": "https://your-domain.com/images/2026/08/19/abc.md.png"
  }
}
```

要原图就把 JSON path 设成 `image.url`，要缩放版就用 `image.display_url`。

## 对象键模板

两者都会按自己的设置重命名上传的文件，所以键模板控制不了最终路径。保持默认。

## 常见问题

| 现象 | 原因 |
| --- | --- |
| `响应不是合法 JSON` | 少了 `Accept: application/json` 请求头 |
| `HTTP 401` | Token 过期或被吊销，重新生成一个 |
| `HTTP 403` | token 对应的用户没有上传权限，或者储存策略 id 不属于他 |
| `HTTP 413` | 网关限制 —— nginx 的 `client_max_body_size`、PHP 的 `upload_max_filesize` |
| `找不到路径 data.links.url` | 你用的是 Chevereto 而不是兰空图床 —— 改成 `image.url` |
