---
title: SM.MS
description: 把 Dropline 配到 SM.MS —— 获取 API Token、smfile 字段、data.url 响应路径，以及这个服务的体积与频率限制。
---

# SM.MS

**引擎：** `multipart/form-data` · **预设：** `SM.MS`

SM.MS 是一个免费图床，v2 API 很简单。随手扔截图挺合适，但不适合放你在乎的东西。

## 配置

设置 → 图床 → **+** → **SM.MS**。除了 token，其它都已经填好。

| 字段 | 值 |
| --- | --- |
| 上传地址 | `https://sm.ms/api/v2/upload` |
| 方法 | `POST` |
| 文件字段名 | `smfile` |
| 鉴权方式 | **自定义请求头** |
| 请求头名 | `Authorization` |
| 请求头值 | 你的 API Token —— 存进钥匙串 |
| JSON path | `data.url` |
| 最终链接模板 | *(留空)* |

注意鉴权方式是**自定义请求头**，不是 Bearer：SM.MS 要的是裸 token，前面不加 `Bearer `。Dropline 的自定义请求头方式原样发送值，正好就是这个。

## 拿一个 Token

1. 在 [sm.ms](https://sm.ms/) 注册并登录。
2. **User → Dashboard → API Token**。
3. 生成一个 token，粘进**请求头值**。

不带 token 也能传，但那是匿名的 —— 之后既列不出来也删不掉，而且频率限制严得多。用 token 吧。

## 响应

```json
{
  "success": true,
  "code": "success",
  "data": {
    "url": "https://s2.loli.net/2026/08/19/abc123.png",
    "delete": "https://sm.ms/delete/xxxxx",
    "page": "https://sm.ms/image/abc123"
  }
}
```

`data.url` 是直链，也就是预设读取的那一项。

### 重复上传

同样的字节传第二次，SM.MS 的响应就不一样了 —— `success: false`，已有的 URL 出现在 `images` 字段里而不是 `data` 下面。于是 Dropline 报 `响应里找不到路径 data.url`。这不是坏了，文件本来就已经在上面了。只有重传一模一样的文件才会碰到。

## 限制

| 限制 | 值 |
| --- | --- |
| 单文件大小 | 5 MB |
| 格式 | jpg、png、gif、bmp、webp |
| 频率 | 带 token 大约每分钟 20 次 |

非图片文件直接被拒 —— SM.MS 是图床，视频和文档请发到[对象存储](/zh/docs/hosts/overview)。

`HTTP 429` 意味着触发了频率限制。把**设置 → 通用 → 并发上传数**降到 1。

## 对象键模板

SM.MS 自己决定文件名和路径，所以键模板除了影响 multipart 里那个 `filename` 之外没有作用。保持默认即可。

## 常见问题

| 现象 | 原因 |
| --- | --- |
| `HTTP 401` | 没填 token，或者错用了 Bearer 而不是自定义请求头 |
| `找不到路径 data.url` | 重复上传，或者文件被拒 |
| `HTTP 413` | 超过 5 MB |
| `HTTP 429` | 触发频率限制 |
