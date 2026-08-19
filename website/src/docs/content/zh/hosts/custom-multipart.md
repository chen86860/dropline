---
title: 自定义 multipart 图床
description: 把 Dropline 指向任意接受 multipart/form-data 的图床接口 —— 怎么把 API 文档翻译成这几个字段、两个完整例子，以及怎么先用 curl 验证。
---

# 自定义 multipart 图床

**引擎：** `multipart/form-data` · **预设：** `空白 · 自定义 HTTP`

如果你的服务不在预设列表里，那它几乎肯定能用这种方式配出来。凡是 PicGo、uPic、ShareX 能对接的图床 API，都落在下面这几个字段里。

## Dropline 实际发出的请求

```http
POST /api/upload HTTP/1.1
Host: your-domain.com
Authorization: Bearer <密钥>
Content-Type: multipart/form-data; boundary=DroplineBoundary-…

--DroplineBoundary-…
Content-Disposition: form-data; name="token"

abc123
--DroplineBoundary-…
Content-Disposition: form-data; name="file"; filename="a1f3c9.png"
Content-Type: image/png

<文件字节>
--DroplineBoundary-…--
```

把它和你的 API 文档对着看，每个字段该填什么就清楚了。

## 各字段

| 字段 | 对应文档里的什么 |
| --- | --- |
| **上传地址** | 接口地址。支持模板 —— `{{key}}` 之类都能用 |
| **方法** | 除非文档写了 `PUT` 或 `PATCH`，否则就是 `POST` |
| **文件字段名** | 文件那个 part 的名字：`file`、`image`、`source`、`smfile` |
| **自定义请求头** | 鉴权之外文档要求的头，通常是 `Accept: application/json` |
| **额外表单字段** | 非文件的参数：相册 id、token、有效期、可见性 |
| **鉴权方式** | 见下 |
| **JSON path** | 链接在响应里的位置 —— [解析响应](/zh/docs/guide/response) |
| **最终链接模板** | 只在响应给的是相对路径时才需要 |

请求头的值和表单字段的值都支持模板，所以 `{{key}}`、`{{base}}`、`{{date}}` 这些在两边都能用。

## 怎么选鉴权方式

| 文档写的是 | 选 | 怎么填 |
| --- | --- | --- |
| `Authorization: Bearer TOKEN` | Bearer Token | 密钥 = token，不带前缀 |
| `Authorization: TOKEN` | 自定义请求头 | 头名 `Authorization`，值 = token |
| `Authorization: Client-ID xyz` | 自定义请求头 | 头名 `Authorization`，值 = `Client-ID xyz` |
| `X-API-Key: TOKEN` | 自定义请求头 | 头名 `X-API-Key`，值 = token |
| URL 里带 `?token=TOKEN` | URL 查询参数 | 参数名 `token`，值 = token |
| 用户名 + 密码 | Basic | 用户名填在名字那一栏，密码作为密钥 |
| token 是一个表单字段 | 无 | 改在*额外表单字段*里加 |

**自定义请求头**方式原样发送你填的值、不加任何前缀，这正是它能表达各种奇怪写法的原因。

## 例子一：token 放在表单字段里

文档写着：

> `POST https://img.example.com/upload`，参数 `file` 和 `api_key`，返回
> `{"code":0,"data":{"path":"/i/2026/abc.png"}}`，文件由 `https://img.example.com` 提供。

对应配置：

| 字段 | 值 |
| --- | --- |
| 上传地址 | `https://img.example.com/upload` |
| 方法 | `POST` |
| 文件字段名 | `file` |
| 额外表单字段 | `api_key` = `YOUR_KEY` |
| 鉴权方式 | 无 |
| JSON path | `data.path` |
| 最终链接模板 | `https://img.example.com{{result}}` |

注意模板里 `{{result}}` 前面**没有斜杠** —— 返回的路径自带一个。

## 例子二：目录写在地址里

有的接口把目标目录作为路径的一部分：

| 字段 | 值 |
| --- | --- |
| 上传地址 | `https://img.example.com/upload/{{date}}` |
| 对象键模板 | `{{uuid}}.{{ext}}` |
| JSON path | `url` |

地址里的模板在构造请求前就渲染好了，于是每天的上传各自落进自己的目录。

## 先用 curl 验证

如果**测试上传**失败而报错又看不明白，就在应用外面把这个请求复现一遍。在这里失败的，在 Dropline 里也一样会失败；而原始输出会直接告诉你 JSON path 该怎么写：

```bash
curl -sSv -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/json" \
  -F "file=@/tmp/test.png" \
  -F "album_id=3" \
  https://img.example.com/api/upload | jq
```

然后照着抄：每个 `-H` 是一个自定义请求头（或者对应某种鉴权方式），每个非文件的 `-F` 是一个额外表单字段，带 `@` 的那个 `-F` 给出文件字段名。

## 关于文件名

multipart 里那个 `filename` 取的是渲染后[对象键](/zh/docs/guide/templates)的**最后一段**。如果你的 API 会拿它来决定存储名，那么把键模板写成 `{{base}}-{{rand}}.{{ext}}` 就能控制它。多数图床会忽略它，自己另起名字。

## 下一页

[自定义二进制 PUT →](/zh/docs/hosts/custom-binary)
