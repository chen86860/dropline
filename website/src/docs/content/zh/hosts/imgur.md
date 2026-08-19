---
title: Imgur
description: 把 Dropline 配到 Imgur —— 注册应用拿 Client-ID、Authorization 头的准确写法、data.link 响应路径，以及匿名上传的限制。
---

# Imgur

**引擎：** `multipart/form-data` · **预设：** `Imgur`

## 配置

设置 → 图床 → **+** → **Imgur**。

| 字段 | 值 |
| --- | --- |
| 上传地址 | `https://api.imgur.com/3/image` |
| 方法 | `POST` |
| 文件字段名 | `image` |
| 鉴权方式 | **自定义请求头** |
| 请求头名 | `Authorization` |
| 请求头值 | `Client-ID abc123def456789` —— **整串** |
| JSON path | `data.link` |
| 最终链接模板 | *(留空)* |

### 请求头的值不是光一个 id

这是最多人搞错的地方。Imgur 要的是：

```http
Authorization: Client-ID abc123def456789
```

所以你粘进 Dropline 的值是 `Client-ID abc123def456789` —— `Client-ID` 这几个字、一个空格，然后才是你的 id。只粘 id 会得到 `HTTP 403`。

Dropline 的*自定义请求头*方式原样发送值，正是为了能表达这种写法。**不要**用 Bearer 方式，那是给 OAuth access token 用的，是另一回事。

## 拿一个 Client-ID

1. 在 [imgur.com](https://imgur.com/) 登录。
2. 打开 [api.imgur.com/oauth2/addclient](https://api.imgur.com/oauth2/addclient)。
3. 类型选 **Anonymous usage without user authorization**。它仍然会要一个回调地址 —— 随便填一个你自己的地址就行，实际用不到。
4. 提交，复制 **Client ID**。匿名上传用不到 Client Secret。

## 响应

```json
{
  "status": 200,
  "success": true,
  "data": {
    "id": "abc123",
    "link": "https://i.imgur.com/abc123.png",
    "deletehash": "xyz789",
    "type": "image/png"
  }
}
```

`data.link` 是图片直链。`data.deletehash` 是之后删掉匿名上传的唯一凭据 —— Dropline 不保存它，所以如果你在意这个，请改用 Imgur 自家工具在账号下上传。

## 限制与条款

| 限制 | 值 |
| --- | --- |
| 非动图单文件 | 20 MB |
| 动图（GIF/MP4） | 200 MB |
| 格式 | jpg、png、gif、apng、tiff、webp |
| 频率 | 每个 Client-ID 每天约 1250 次 |

依赖它之前有两点要知道：

- **匿名上传是无主的。** 你既列不出来、管不了，也找不回来；长期无人访问的匿名图片会被 Imgur 清理。
- **Imgur 是一个公开图库。** 它的条款禁止把它当通用文件存储或者网站 CDN 用。除了随手分享，请用[对象存储](/zh/docs/hosts/overview)。

## 对象键模板

Imgur 自己分配 id 且忽略文件名，所以键模板在这里没有实际作用。

## 常见问题

| 现象 | 原因 |
| --- | --- |
| `HTTP 403` | 请求头的值只填了 id，缺少 `Client-ID ` 前缀 |
| `HTTP 400` | 文件不是 Imgur 接受的图片格式 |
| `HTTP 429` | 触发了每日或每小时的频率限制 |
| `找不到路径 data.link` | 返回的是错误响应 —— 用 `curl` 看看 `data.error` 字段 |
