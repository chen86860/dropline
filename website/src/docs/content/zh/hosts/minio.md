---
title: MinIO
description: 把 Dropline 配到自建 MinIO 或任意 S3 兼容网关 —— 带端口的 endpoint、path-style 寻址、限定权限的访问密钥，以及匿名下载策略。
---

# MinIO

**引擎：** S3 兼容（AWS SigV4） · **预设：** `MinIO / 自建 S3`

这一页同样适用于**任何**你自己跑的 S3 兼容服务 —— Garage、SeaweedFS、Ceph RGW、Zenko，以及 Backblaze B2 的 S3 端点、Wasabi、DigitalOcean Spaces。字段完全一样，只有 endpoint 不同。

## 配置

设置 → 图床 → **+** → **MinIO / 自建 S3**。

| 字段 | 值 |
| --- | --- |
| Endpoint | `http://127.0.0.1:9000`，或者 `https://s3.example.com` |
| Region | `us-east-1` —— MinIO 的默认值。只要和服务端一致，填什么都行 |
| Bucket | 只填桶名 |
| Access Key ID | MinIO 的访问密钥 |
| Secret Access Key | 对应的密钥 —— 存进钥匙串 |
| 公开访问前缀 | 可选；只有前面挂了 CDN 或反向代理时才填 |
| 对象键模板 | `images/{{date}}/{{uuid}}.{{ext}}` |

**端口不是 443 或 80 就要写出来。** Dropline 把 host 连同端口一起签名，所以对签名而言 `https://s3.example.com:9000` 和 `https://s3.example.com` 是两个不同的 host —— 填你实际访问服务用的那个。

Dropline 一律使用 **path-style** 寻址（`endpoint/bucket/key`），这正是 MinIO 的原生模式。不需要为此配任何东西，也不需要泛域名 DNS 或者 virtual-host 风格。

其它服务商的 endpoint，供参考：

| 服务 | Endpoint | Region |
| --- | --- | --- |
| Backblaze B2 | `https://s3.us-west-004.backblazeb2.com` | `us-west-004` |
| Wasabi | `https://s3.eu-central-1.wasabisys.com` | `eu-central-1` |
| DigitalOcean Spaces | `https://fra1.digitaloceanspaces.com` | `fra1` |

## 创建限定权限的密钥

在 MinIO 控制台里 **Access Keys → Create access key**，并挂一条策略，让泄露的密钥除了上传什么都干不了：

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:PutObject"],
      "Resource": ["arn:aws:s3:::assets/images/*"]
    }
  ]
}
```

不要把 `MINIO_ROOT_USER` 那对根凭证交给 Dropline。

## 让对象可读

用 `mc` 客户端给一个前缀开匿名下载：

```bash
mc alias set local http://127.0.0.1:9000 ACCESSKEY SECRETKEY
mc anonymous set download local/assets/images
```

或者在控制台里：桶 → **Anonymous** → 添加一条对该前缀的 *readonly* 规则。

## 链接怎么给出去

如果 MinIO 有公网可达的域名，把**公开访问前缀**留空，Dropline 返回：

```text
https://s3.example.com/assets/images/2026/08/19/a1f3….png
```

如果前面有反向代理或 CDN，把桶挂在更干净的路径上，就把前缀设成它。典型的 nginx 前端会把桶名吃掉：

```text
公开访问前缀   https://cdn.example.com
```

对应的代理把 `/` 映射到上游的 `/assets/`。

## localhost 的注意事项

`http://127.0.0.1:9000` 用来测试很合适 —— **测试上传**会通过 —— 但返回的链接只在你自己这台机器上有效。从 localhost 配置分享出去的任何链接，对别人都是死链。

## 常见问题

| 现象 | 原因 |
| --- | --- |
| 连接被拒绝 | MinIO 没在跑，或者端口不对 |
| `SignatureDoesNotMatch` | endpoint 少了端口，或者代理改写了 `Host` 头 |
| `HTTP 403 AccessDenied` | 密钥的策略没允许该前缀下的 `s3:PutObject` |
| `HTTP 404 NoSuchBucket` | 桶不存在 —— MinIO 不会替你创建 |
| 链接 403 | 该前缀没有匿名下载策略 |
