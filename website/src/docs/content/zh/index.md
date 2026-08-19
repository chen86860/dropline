---
title: 简介
description: Dropline 是什么、一次上传到底经历了哪几步、接下来该看哪一页 —— 这个把公开链接直接送到剪贴板的原生 macOS 上传工具的完整手册。
---

# 简介

Dropline 是给自己搭图床的人写的原生 macOS 应用。你把文件丢给它 —— 从窗口、程序坞、访达右键菜单、剪贴板或者菜单栏 —— 它就把这个文件传到**你自己的**存储：你的 S3 存储桶、你的 R2、你的图床。传完之后，公开链接已经在剪贴板里了。

它用 Swift 和 SwiftUI 写成，可执行文件大约一兆，采用 MIT 协议。

## 它不是什么

没有 Dropline 账号，没有 Dropline 服务器，没有任何埋点。每个请求都是从你的 Mac 直接发到你配置的那个接口。你把应用删掉，除了你自己的存储桶里，任何地方都不会留下你的东西。

## 一次上传经历了什么

不管走哪种引擎，每次上传都是同样的五步。你能配的东西几乎都对应其中一步，所以值得先读一遍。

1. **收集变量。** 文件给出文件名、扩展名和大小，时钟给出日期。它们就是 `{{filename}}`、`{{ext}}`、`{{date}}` 这些 —— 见[模板变量](/zh/docs/guide/templates)。
2. **渲染对象键。** 你的键模板（S3 类配置默认是 `images/{{date}}/{{uuid}}.{{ext}}`）渲染成远端路径，结果本身又可以作为 `{{key}}` 继续用。
3. **构造并签名请求。** 具体形状取决于引擎：multipart 表单、裸二进制请求体，或者 AWS SigV4 签名的 `PUT`。密钥在这一刻才从系统钥匙串里取出来，不经过磁盘。
4. **解析响应。** 用 `data.url` 这样的 JSON path 从接口返回里把链接取出来。见[解析响应](/zh/docs/guide/response)。
5. **拼出最终链接。** 可选的 URL 模板把相对路径换成你 CDN 域名下的链接，结果落到剪贴板。

## 三种引擎

这三种加起来，基本覆盖了世面上所有上传 API。

| 引擎 | 适用于 |
| --- | --- |
| `multipart/form-data` | 绝大多数图床 API —— SM.MS、Imgur、兰空图床、EasyImage |
| 二进制 `PUT` / `POST` | 自建服务、WebDAV 风格的接口 |
| S3 兼容（AWS SigV4） | S3、R2、阿里云 OSS、腾讯云 COS、MinIO |

九个服务内置了预设，其余的用同样这几个字段手动配就行。[图床配置](/zh/docs/hosts/overview)一节里，每个服务都有单独一页。

## 接下来看哪儿

- **[安装 Dropline](/zh/docs/getting-started/install)** —— 下载、第一次启动、以及绕过 Gatekeeper 那一步。
- **[第一次上传](/zh/docs/getting-started/quickstart)** —— 配好一个图床并拿到链接，大约五分钟。
- **[图床配置](/zh/docs/hosts/overview)** —— 每个支持的服务一页，字段逐个填满。
- **[疑难排查](/zh/docs/guide/troubleshooting)** —— 常见报错分别是什么意思、该改哪儿。

## 系统要求

- macOS 13 Ventura 或更高版本
- 发布的安装包面向 Apple Silicon；Intel Mac 可以[自行编译](/zh/docs/guide/build-from-source)
- 不需要别的运行时 —— 没有 Electron，没有 Node，没有 Python
