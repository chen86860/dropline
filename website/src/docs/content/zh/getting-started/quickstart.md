---
title: 第一次上传
description: 在 Dropline 里配好一个图床、用「测试上传」验证它，五分钟左右拿到第一条能用的公开链接。
---

# 第一次上传

这一页走一遍「配好一个图床、拿到链接」的全过程。大约五分钟，而且不管用哪个服务，流程都是这个样子。

## 1. 打开「图床」

打开 Dropline，进入**设置 → 图床**（`⌘,`）。全新安装时左边的列表是空的。

点左下角的 **+**，弹出来的就是预设列表：

```text
空白 · 自定义 HTTP
空白 · 自定义二进制 PUT
Amazon S3
Cloudflare R2
阿里云 OSS（S3 兼容）
腾讯云 COS（S3 兼容）
MinIO / 自建 S3
SM.MS
Imgur
Lsky Pro / Chevereto
EasyImage / PicGo 自定义
```

挑一个和你的服务最接近的。预设会把接口形状、文件字段名、鉴权方式和 JSON path 都填好 —— 除了你自己的密钥和域名。如果没有合适的，就从**空白 · 自定义 HTTP** 开始，参见[自定义 multipart 图床](/zh/docs/hosts/custom-multipart)。

## 2. 填上你的密钥

要填什么取决于预设选的引擎。

**S3 兼容**类预设（S3、R2、OSS、COS、MinIO）要填：

| 字段 | 示例 |
| --- | --- |
| Endpoint | `https://<account>.r2.cloudflarestorage.com`；AWS 留空 |
| Region | `auto`、`us-east-1`、`oss-cn-hangzhou` |
| Bucket | `my-assets` |
| Access Key ID | `AKIA…` |
| Secret Access Key | 存在钥匙串里，不会写进配置文件 |
| 公开访问前缀 | `https://cdn.example.com` —— 可选 |

**图床**类预设要填的是上传地址和一个密钥，别的基本不用管。文件字段名和链接在响应里的位置，预设已经知道了。

[图床配置](/zh/docs/hosts/overview)一节里，每个服务的页面都列了它全部的字段和该填的值。

## 3. 先测一次再信它

点编辑器底部的**测试上传**。Dropline 会生成一张 8×8 的 PNG，完全按真实上传的流程走一遍，然后给你两种结果之一：

- **成功**，后面跟着返回的链接。点开看看。图片能加载，说明这套配置从头到尾都对 —— 请求、鉴权、响应解析、链接拼装。
- **报错**，红色。[疑难排查](/zh/docs/guide/troubleshooting)把每条报错对应到该改的字段。

当前默认的那份配置旁边有个绿色对勾。如果你配了不止一个，选中你要用的那个，点**设为默认**。

## 4. 真的传一个文件

关掉设置，用五个入口里的任意一个：

- 把文件**拖**到 Dropline 窗口上
- **拖**到程序坞图标上
- 在访达里**右键** → 使用 Dropline 上传
- **粘贴** —— `⇧⌘4` 截的图不用先存盘，直接从剪贴板传
- **菜单栏** → 上传…

菜单栏图标会变成进度环。传完之后会有一条系统通知，而链接已经在剪贴板里了 —— 直接去粘贴就行。

## 5. 可选：Markdown

如果你整天往 Markdown 里贴链接，打开**设置 → 通用 → 复制为 Markdown**，剪贴板里就是 `![name](url)` 而不是裸链接。

## 下一页

- [五种上传方式 →](/zh/docs/guide/upload-methods)
- [模板变量 →](/zh/docs/guide/templates) —— 控制远端路径
- [图床配置 →](/zh/docs/hosts/overview) —— 你用的服务，逐字段说明
