---
title: 阿里云 OSS
description: 通过 S3 兼容网关把 Dropline 配到阿里云 OSS —— 各地域 endpoint、RAM 子用户密钥、公共读 ACL，以及绑定 CDN 域名。
---

# 阿里云 OSS

**引擎：** S3 兼容（AWS SigV4） · **预设：** `阿里云 OSS（S3 兼容）`

阿里云 OSS 既有自己的 API，也有一套 S3 兼容 API。Dropline 走的是后者，所以这份配置和 S3 那份长得一模一样。

## 配置

设置 → 图床 → **+** → **阿里云 OSS（S3 兼容）**。

| 字段 | 值 |
| --- | --- |
| Endpoint | `https://oss-cn-hangzhou.aliyuncs.com` —— 你桶所在的地域 |
| Region | 同一个地域 id：`oss-cn-hangzhou` |
| Bucket | 只填桶名 |
| Access Key ID | RAM 子用户的 AccessKey ID |
| Secret Access Key | 对应的 AccessKey Secret —— 存进钥匙串 |
| 公开访问前缀 | 你的 CDN 域名或桶域名 |
| 对象键模板 | `images/{{date}}/{{uuid}}.{{ext}}` |

### 各地域 endpoint

endpoint 和 region 永远是配套的。常用的几个：

| Region | Endpoint |
| --- | --- |
| `oss-cn-hangzhou` | `https://oss-cn-hangzhou.aliyuncs.com` |
| `oss-cn-shanghai` | `https://oss-cn-shanghai.aliyuncs.com` |
| `oss-cn-beijing` | `https://oss-cn-beijing.aliyuncs.com` |
| `oss-cn-shenzhen` | `https://oss-cn-shenzhen.aliyuncs.com` |
| `oss-cn-hongkong` | `https://oss-cn-hongkong.aliyuncs.com` |
| `oss-ap-southeast-1` | `https://oss-ap-southeast-1.aliyuncs.com` |
| `oss-us-west-1` | `https://oss-us-west-1.aliyuncs.com` |

用**公网** endpoint，不要用带 `-internal` 的那个 —— 那个只在阿里云内网里能解析。

不要把桶名拼进 endpoint。OSS 自己的文档写的是 `https://bucket.oss-cn-hangzhou.aliyuncs.com`，但 Dropline 签的是 path-style 请求，桶名它自己会加。

## 创建 RAM 子用户

不要用主账号的 AccessKey。在 **RAM 控制台**里：

1. **身份管理 → 用户 → 创建用户**，勾选 *OpenAPI 调用访问*。
2. 保存好 AccessKey ID 和 Secret。
3. **授权**，挂一条自定义策略：

```json
{
  "Version": "1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "oss:PutObject",
      "Resource": "acs:oss:*:*:my-assets/images/*"
    }
  ]
}
```

## 让对象可读

要么把整个桶的 ACL 设为**公共读**（OSS 控制台 → 桶 → *权限管理*），要么保持私有、通过 CDN 回源。Dropline 上传时不带 ACL 头，所以对象继承桶的设置。

## 绑定域名

默认的桶域名是能用的：

```text
https://my-assets.oss-cn-hangzhou.aliyuncs.com
```

但它有限速，也没有缓存。正式用的话，在桶 → **传输管理 → 域名管理**里绑定自定义域名（可以再挂上阿里云 CDN），把它填进**公开访问前缀**。

> **指向中国大陆地域的自定义域名需要 ICP 备案。** 香港、新加坡、美国等非大陆地域不需要。

## 你拿到的链接

公开访问前缀填 `https://cdn.example.com` 时：

```text
https://cdn.example.com/images/2026/08/19/a1f3….png
```

## 常见问题

| 现象 | 原因 |
| --- | --- |
| `SignatureDoesNotMatch` | region 和 endpoint 对不上，或者桶名拼进了 endpoint |
| 连接超时 | 在阿里云外网用了 `-internal` 的 endpoint |
| `HTTP 403` | RAM 策略没允许该路径下的 `oss:PutObject` |
| 浏览器里 403 | 桶是私有读，而且前面没挂 CDN |
