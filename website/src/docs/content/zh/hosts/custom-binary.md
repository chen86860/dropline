---
title: 自定义二进制 PUT
description: 把文件裸字节 PUT 到 WebDAV、nginx WebDAV 模块、Caddy 或 Worker 接收端 —— Dropline 的二进制引擎，路径决定名字，附几份可直接抄的服务端配置。
---

# 自定义二进制 PUT

**引擎：** 二进制 `PUT` / `POST` · **预设：** `空白 · 自定义二进制 PUT`

这个引擎把文件的字节直接放进请求体，外面什么都不包。没有表单，没有 boundary，没有字段 —— 只有文件本身，外加一个由扩展名推出来的 `Content-Type`。

只要**是 URL 决定文件去哪儿**，这个引擎就是对的选择：WebDAV、nginx 的 DAV 模块、Caddy 的 `file_server`、一个小 Worker，或者一个单文件的 PHP 接收端。

## Dropline 实际发出的请求

```http
PUT /files/images/2026/08/19/a1f3c9.png HTTP/1.1
Host: files.example.com
Authorization: Basic dXNlcjpwYXNz
Content-Type: image/png

<文件字节>
```

## 配置

设置 → 图床 → **+** → **空白 · 自定义二进制 PUT**。

| 字段 | 值 |
| --- | --- |
| 上传地址 | `https://files.example.com/{{key}}` |
| 方法 | `PUT` |
| 自定义请求头 | 服务端需要什么就填什么 |
| 鉴权方式 | 服务端用哪种就选哪种 |
| JSON path | **留空** —— 这类服务不返回响应体 |
| 最终链接模板 | `https://files.example.com/{{key}}` |
| 对象键模板 | `images/{{date}}/{{uuid}}.{{ext}}` |

形状永远是这样：`{{key}}` 出现**两次**，一次在你写入的地址里，一次在你读取的地址里。如果两个主机名不同 —— 写源站、读 CDN —— 差异就体现在这儿。

JSON path 留空意味着 Dropline 把响应体当作结果；对于一个空的 `201 Created`，那就是空字符串，真正的链接由最终链接模板给出。

## 几份服务端配置

### nginx + DAV 模块

```nginx
server {
    server_name files.example.com;
    root /var/www/files;

    location / {
        # 读是公开的
        autoindex off;
    }

    location /images/ {
        dav_methods PUT;
        create_full_put_path on;
        dav_access user:rw group:r all:r;
        client_max_body_size 512m;

        auth_basic "upload";
        auth_basic_user_file /etc/nginx/.htpasswd;

        limit_except GET HEAD { }
    }
}
```

`create_full_put_path on` 是必须的 —— 没有它，`PUT` 到一条目录还不存在的路径会返回 `409 Conflict`，而按日期分目录的键模板每天都会产生一个新目录。

在 Dropline 里：鉴权方式选 **Basic**，用户名填在名字栏，密码作为密钥。

### Caddy

```text
files.example.com {
    root * /var/www/files
    file_server

    @upload method PUT
    handle @upload {
        basicauth {
            uploader $2a$14$…hash…
        }
        rewrite * /upload{path}
        reverse_proxy localhost:8080
    }
}
```

Caddy 没有内置的 `PUT` 接收端，配一个小上游 —— 或者用 `webdav` 插件。

### 写入 R2 的 Cloudflare Worker

想在 R2 前面套一层自定义鉴权、而不是把 S3 密钥放在客户端时，这个很好用。

```ts
export default {
  async fetch(request: Request, env: Env) {
    if (request.method !== 'PUT') return new Response('Method not allowed', { status: 405 })
    if (request.headers.get('Authorization') !== `Bearer ${env.UPLOAD_TOKEN}`) {
      return new Response('Unauthorized', { status: 401 })
    }

    const key = new URL(request.url).pathname.slice(1)
    await env.BUCKET.put(key, request.body, {
      httpMetadata: { contentType: request.headers.get('Content-Type') ?? 'application/octet-stream' },
    })

    return new Response(null, { status: 201 })
  },
}
```

在 Dropline 里：上传地址 `https://upload.example.com/{{key}}`，鉴权方式 **Bearer Token**，JSON path 留空，最终链接模板 `https://cdn.example.com/{{key}}`。

### 通用 WebDAV

多数 WebDAV 服务端 —— Nextcloud、`rclone serve webdav`、群晖 —— 都接受普通的 `PUT`：

| 字段 | 值 |
| --- | --- |
| 上传地址 | `https://dav.example.com/remote.php/dav/files/user/{{key}}` |
| 方法 | `PUT` |
| 鉴权方式 | Basic |

注意 WebDAV 的存储通常**不是**公开可读的，所以最终链接模板要指向服务端提供的分享链接 —— 在 Nextcloud 上就是那个目录的公开分享。

## 服务端确实返回了内容时

有些接收端会用纯文本返回链接：

```text
https://files.example.com/images/2026/08/19/a1f3c9.png
```

这时把 JSON path 留空（Dropline 会去掉首尾空白直接用响应体），最终链接模板也留空，让服务端的答案说了算。

如果返回的是 JSON，就照常设 JSON path，见[解析响应](/zh/docs/guide/response)。

## 常见问题

| 现象 | 原因 |
| --- | --- |
| `HTTP 409` | 父目录不存在 —— nginx 里加 `create_full_put_path on` |
| `HTTP 405` | 服务端不允许对该路径 `PUT` |
| `HTTP 401` | 鉴权方式选错了；确认服务端要的是 Basic 还是 token |
| `HTTP 411` | 服务端要求分块请求体带 `Content-Length` —— 很少见，试试 `POST` |
| 上传成功但链接 404 | 读的主机名或路径和写的不一样 —— 修最终链接模板 |
| 剪贴板里是空字符串 | JSON path 和最终链接模板都留空了，而响应体也是空的 |
