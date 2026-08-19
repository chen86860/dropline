---
title: 图床总览
description: Dropline 支持的全部上传目标 —— 三种引擎、九个预设 —— 每种引擎的字段说明、五种鉴权方式，以及一张「该选哪个」的对照表。
---

# 图床总览

一份**图床配置**就是一个上传目标：一个接口、一套密钥，外加把响应变成链接的规则。你可以同时配好任意多份，随时切换默认，也可以并发地往几个地方传。

这一页讲这些字段是什么意思。每个具体服务另有单独一页，写清楚该填什么值。

## 该选哪个

| 你的情况 | 用 |
| --- | --- |
| 已经有 AWS 账号 | [Amazon S3](/zh/docs/hosts/s3) |
| 想要零出站费用 | [Cloudflare R2](/zh/docs/hosts/r2) |
| 用户在中国大陆 | [阿里云 OSS](/zh/docs/hosts/oss) 或[腾讯云 COS](/zh/docs/hosts/cos) |
| 自己跑对象存储 | [MinIO](/zh/docs/hosts/minio) |
| 想要免费图床、不注册 | [SM.MS](/zh/docs/hosts/smms) |
| 想要免费图床、能拿 API key | [Imgur](/zh/docs/hosts/imgur) |
| 自建了图床程序 | [兰空图床 / Chevereto](/zh/docs/hosts/lsky-chevereto) 或 [EasyImage](/zh/docs/hosts/easyimage) |
| 你的接口不在上面 | [自定义 multipart](/zh/docs/hosts/custom-multipart) 或[自定义二进制 PUT](/zh/docs/hosts/custom-binary) |

## 三种引擎

配置编辑器顶部的**上传方式**选择器决定请求的形状，下面的字段会跟着变。

### `multipart/form-data`

就是普通的 HTML 表单提交 —— 文件是其中一个 part，旁边可以带别的字段。几乎所有图床 API 说的都是这套。

| 字段 | 含义 |
| --- | --- |
| 上传地址 | 接口地址。支持模板，`{{key}}` 之类都能用 |
| 方法 | `POST`、`PUT` 或 `PATCH` —— 绝大多数是 `POST` |
| 文件字段名 | 文件放在哪个表单字段里：`file`、`image`、`smfile` |
| 自定义请求头 | 额外的请求头；值支持模板 |
| 额外表单字段 | 与文件并列的其它字段；值支持模板 |
| JSON path | 链接在响应里的位置 —— 见[解析响应](/zh/docs/guide/response) |
| 最终链接模板 | 可选，对上一步的结果做改写 |

multipart 里那个 `filename` 取的是渲染后对象键的**最后一段**。多数图床会忽略它，自己另起名字。

### 二进制 `PUT` / `POST`

文件的字节就是整个请求体，`Content-Type` 由扩展名推出来。没有表单，所以既没有表单字段也没有文件字段名。

这是给 WebDAV 风格接口和小型自建接收端用的引擎，特点是**路径决定名字**：

```text
上传地址     https://files.example.com/{{key}}
方法         PUT
JSON path    （留空）
最终链接      https://files.example.com/{{key}}
```

### S3 兼容（AWS SigV4）

用 AWS 签名 V4 对一次 `PUT` 做签名。Dropline 一律签 **path-style** 请求 —— `endpoint/bucket/key` —— 这正是 R2、MinIO 和自建网关期望的形式，AWS 也仍然接受。

| 字段 | 含义 |
| --- | --- |
| Endpoint | 服务的 origin。AWS 留空，会自动用 `https://s3.<region>.amazonaws.com` |
| Region | `auto`、`us-east-1`、`oss-cn-hangzhou`… |
| Bucket | 只填桶名，绝对不要拼进 endpoint |
| Access Key ID | 非机密，存在配置文件里 |
| Secret Access Key | 机密，存在**钥匙串**里 |
| 公开访问前缀 | 可选。留空则链接是 `endpoint/bucket/key` |

这里没有 JSON path：S3 成功时返回空响应体，所以链接是拼出来的，不是解析出来的。

## 五种鉴权方式

适用于 multipart 和二进制引擎。无论选哪种，密钥本身都进钥匙串。

| 方式 | Dropline 实际发送 |
| --- | --- |
| 无 | 什么都不发。适用于 token 放在表单字段里的情况 |
| Bearer Token | `Authorization: Bearer <密钥>` |
| Basic | `Authorization: Basic base64(<用户名>:<密钥>)` |
| 自定义请求头 | `<头名>: <密钥>` —— 原样发送，不加任何前缀 |
| URL 查询参数 | 在上传地址后追加 `?<参数名>=<密钥>` |

**自定义请求头**是万能出口。因为值是原样发送的，所以要求 `Authorization: Client-ID abc123` 的接口，只要把头名设成 `Authorization`、值设成整串 `Client-ID abc123` 就行。

## 管理配置

- **+** 从预设新建一份，**−** 删掉选中的那份。
- **设为默认**决定新的上传用哪一份；默认那份在列表里带绿色对勾。
- **测试上传**发一张 8×8 的 PNG 走一遍完整流程，把链接或报错摆给你看。每改一次配置都点一下。
- 删掉配置时，它对应的钥匙串条目也一起删掉。

## 预设一览

| 预设 | 引擎 | 鉴权 | JSON path |
| --- | --- | --- | --- |
| [Amazon S3](/zh/docs/hosts/s3) | S3 | SigV4 | — |
| [Cloudflare R2](/zh/docs/hosts/r2) | S3 | SigV4 | — |
| [阿里云 OSS](/zh/docs/hosts/oss) | S3 | SigV4 | — |
| [腾讯云 COS](/zh/docs/hosts/cos) | S3 | SigV4 | — |
| [MinIO](/zh/docs/hosts/minio) | S3 | SigV4 | — |
| [SM.MS](/zh/docs/hosts/smms) | multipart | 自定义请求头 | `data.url` |
| [Imgur](/zh/docs/hosts/imgur) | multipart | 自定义请求头 | `data.link` |
| [兰空图床 / Chevereto](/zh/docs/hosts/lsky-chevereto) | multipart | Bearer | `data.links.url` |
| [EasyImage](/zh/docs/hosts/easyimage) | multipart | 表单字段 | `url` |
| [自定义 HTTP](/zh/docs/hosts/custom-multipart) | multipart | 任意 | `url` |
| [自定义二进制 PUT](/zh/docs/hosts/custom-binary) | 二进制 | 任意 | *(留空)* |
