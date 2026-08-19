---
title: 腾讯云 COS
description: 通过 S3 兼容 API 把 Dropline 配到腾讯云 COS —— 带 APPID 的桶名、各地域 endpoint、CAM 子账号密钥，以及公有读权限。
---

# 腾讯云 COS

**引擎：** S3 兼容（AWS SigV4） · **预设：** `腾讯云 COS（S3 兼容）`

## 配置

设置 → 图床 → **+** → **腾讯云 COS（S3 兼容）**。

| 字段 | 值 |
| --- | --- |
| Endpoint | `https://cos.ap-guangzhou.myqcloud.com` —— 你桶所在的地域 |
| Region | 同一个地域 id：`ap-guangzhou` |
| Bucket | **`名字-APPID`**，例如 `my-assets-1250000000` |
| Access Key ID | CAM 子账号的 `SecretId` |
| Secret Access Key | 对应的 `SecretKey` —— 存进钥匙串 |
| 公开访问前缀 | 你的桶域名或 CDN 域名 |
| 对象键模板 | `images/{{date}}/{{uuid}}.{{ext}}` |

### 桶名要带 APPID

这是 COS 独有的一个坑。控制台里显示为 `my-assets` 的桶，实际名字是 `my-assets-1250000000`，后面接着你那串十位的 APPID。桶列表里显示的就是完整名字，请把完整名字填进 **Bucket**。

### 各地域 endpoint

| Region | Endpoint |
| --- | --- |
| `ap-guangzhou` | `https://cos.ap-guangzhou.myqcloud.com` |
| `ap-shanghai` | `https://cos.ap-shanghai.myqcloud.com` |
| `ap-beijing` | `https://cos.ap-beijing.myqcloud.com` |
| `ap-chengdu` | `https://cos.ap-chengdu.myqcloud.com` |
| `ap-hongkong` | `https://cos.ap-hongkong.myqcloud.com` |
| `ap-singapore` | `https://cos.ap-singapore.myqcloud.com` |
| `na-siliconvalley` | `https://cos.na-siliconvalley.myqcloud.com` |

## 创建子账号密钥

在 **CAM 控制台**里做，不要用根账号：

1. **用户 → 新建用户 → 自定义创建**，开启编程访问。
2. 保存 `SecretId` 和 `SecretKey`。
3. 挂一条限定到上传前缀的自定义策略：

```json
{
  "version": "2.0",
  "statement": [
    {
      "effect": "allow",
      "action": ["cos:PutObject"],
      "resource": [
        "qcs::cos:ap-guangzhou:uid/1250000000:my-assets-1250000000/images/*"
      ]
    }
  ]
}
```

把地域、uid（你的 APPID）和桶名换成你自己的。

## 让对象可读

COS 控制台 → 桶 → **权限管理 → 公有读私有写**（针对整个桶），或者写一条只对该前缀把 `cos:GetObject` 开放给 `*` 的桶策略。Dropline 不发 ACL 头，对象继承桶的设置。

## 默认域名与 CDN 域名

默认桶域名是：

```text
https://my-assets-1250000000.cos.ap-guangzhou.myqcloud.com
```

有一定访问量的话，去**域名与传输管理 → 默认 CDN 加速域名**开一个，或者绑自己的域名，然后填进**公开访问前缀**。

> 指向中国大陆地域的自定义域名需要 ICP 备案。

## 你拿到的链接

```text
https://cdn.example.com/images/2026/08/19/a1f3….png
```

## 常见问题

| 现象 | 原因 |
| --- | --- |
| `HTTP 404 NoSuchBucket` | 桶名少了 APPID 后缀 |
| `SignatureDoesNotMatch` | region 和 endpoint 对不上，或者桶名拼进了 endpoint |
| `HTTP 403` | CAM 策略缺该路径下的 `cos:PutObject`，或者用了要求 MFA 的根账号密钥 |
| 链接 403 | 桶是私有读 |
