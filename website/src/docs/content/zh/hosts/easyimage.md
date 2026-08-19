---
title: EasyImage
description: 把 Dropline 配到自建的 EasyImage 2.0（简单图床）—— 接口地址、放在表单字段而不是请求头里的 token，以及 url 响应路径。
---

# EasyImage

**引擎：** `multipart/form-data` · **预设：** `EasyImage / PicGo 自定义`

EasyImage 2.0（简单图床）是一个轻量的自建 PHP 图床。它的接口用**表单字段**鉴权，不是请求头 —— 这也是为什么这个预设的鉴权方式是*无*。

## 配置

设置 → 图床 → **+** → **EasyImage / PicGo 自定义**。

| 字段 | 值 |
| --- | --- |
| 上传地址 | `https://your-domain.com/api/index.php` |
| 方法 | `POST` |
| 文件字段名 | `image` |
| 额外表单字段 | `token` = 你的 API token |
| 鉴权方式 | **无** |
| JSON path | `url` |
| 最终链接模板 | *(留空)* |

> token 走的是表单字段，所以它存在**配置文件**里，而不是钥匙串 —— 只有*鉴权密钥*才进钥匙串。如果你不希望这样，把鉴权方式改成 **URL 查询参数**、参数名填 `token`，同时去掉那个表单字段，值就转到钥匙串里去了。EasyImage 两种都收。

## 开启接口

在 EasyImage 后台里：

1. **设置 → API 设置**。
2. 打开 API。
3. 生成 token 并复制。
4. 顺便看一眼允许的格式和大小限制。

## 响应

```json
{
  "result": "success",
  "code": 200,
  "url": "https://your-domain.com/i/2026/08/19/abc123.png",
  "srcName": "screenshot.png",
  "thumb": "https://your-domain.com/i/2026/08/19/abc123.th.png"
}
```

链接就在顶层，所以 JSON path 只是 `url`。

失败时的形状是 `{"result":"failed","code":204,"message":"…"}`，Dropline 会报 `响应里找不到路径 url` —— 用 `curl` 跑一次就能看到具体消息。

## PicGo 兼容写法

有些 EasyImage 部署（以及若干分支）在另一个路径上提供 PicGo 风格的接口，token 放在查询串里：

```text
上传地址     https://your-domain.com/api/index.php?token=YOUR_TOKEN
文件字段     image
JSON path    url
```

两种都能用；预设选的是表单字段那种，因为它不会把 token 留在 URL 和日志里。

## 大小限制

EasyImage 跑在 PHP 上，所以上传上限由服务端决定，不是应用。大文件报 `HTTP 413` 或者 PHP 错误时，在 `php.ini` 里调高：

```ini
upload_max_filesize = 20M
post_max_size = 20M
```

nginx 后面还要：

```text
client_max_body_size 20m;
```

改完重启 PHP-FPM 和 nginx。

## 对象键模板

EasyImage 按日期和哈希自己命名，所以键模板影响不了最终路径。

## 常见问题

| 现象 | 原因 |
| --- | --- |
| `找不到路径 url` | token 不对或者接口没开 —— 响应体里写着原因 |
| `响应不是合法 JSON` | 地址写错了，拿回来的是站点 HTML |
| `HTTP 413` | PHP 或 nginx 的请求体大小限制 |
| 链接能打开但图裂了 | 站点自己配置的域名和你上传用的域名不一致 |
