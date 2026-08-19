---
title: 疑难排查
description: Dropline 可能出现的每一条报错以及该怎么改 —— 第一次启动被 Gatekeeper 拦下、右键菜单不见了、HTTP 401/403/404/413、SignatureDoesNotMatch、JSON path 取不到值、以及链接在浏览器里 404。
---

# 疑难排查

## 应用打不开

> 「Dropline」已损坏，无法打开。／ 因为来自身份不明的开发者，无法打开。

构建用的是 ad-hoc 签名，没有走公证，所以第一次启动会被 Gatekeeper 拦下。右键点应用选**打开**，或者：

```bash
xattr -dr com.apple.quarantine /Applications/Dropline.app
```

这一步只需要做一次。Homebrew 装的也一样。

## 访达右键菜单里没有 Dropline

依次检查：

1. **批准扩展。** 系统设置 → 通用 → 登录项与扩展 → **访达扩展** → 打开 Dropline。
2. **检查设置。** 设置 → 通用 → 访达右键菜单 → *显示方式*不能是「不显示」。
3. 还是不出现就**重启访达**：`killall Finder`。

即使右键菜单项被隐藏，这条命令也一直存在于**键盘 → 键盘快捷键 → 服务 → 文件和文件夹**下。

## 上传报错

下面每一条都来自 Dropline 本身，会显示在**测试上传**旁边，以及窗口里失败的那一行上。

### `配置不完整：缺少 Bucket`

### `配置不完整：缺少 Access Key ID / Secret Access Key`

S3 类配置有必填项是空的。注意 Secret Access Key 存在钥匙串里，所以它在服务商控制台里「看起来填了」也可能这边是空的 —— 重新粘一次。

### `上传地址无效：…`

endpoint 是空的，或者没有协议头。必须以 `http://` 或 `https://` 开头。如果地址里用了 `{{key}}` 而渲染结果看着不对，去查对象键模板。

### `HTTP 401` / `HTTP 403`

鉴权问题。查什么取决于引擎：

| 引擎 | 检查 |
| --- | --- |
| multipart / 二进制 | 鉴权方式、请求头或参数名、以及密钥本身。Imgur 要的是**整串** `Client-ID abc123`，不是光一个 id |
| S3 兼容 | Access Key ID 和 Secret；然后是这把钥匙有没有对该 bucket 和前缀的 `s3:PutObject` 权限 |

S3 上的 `403` 如果没有提到签名，那几乎一定是权限策略的问题，不是密钥错了。

### `HTTP 403 … SignatureDoesNotMatch`

请求签了名，但用的材料不对。通常是这几种之一：

- **Region 不匹配。** AWS 很严格：配置里的 region 必须和 bucket 所在的一致。R2 和多数自建网关接受 `auto` 或 `us-east-1`。
- **endpoint 带了尾斜杠或路径。** 只填服务的 origin —— `https://<account>.r2.cloudflarestorage.com`，不要写成 `…/my-bucket`。bucket 有它自己的字段，因为 Dropline 签的是 path-style 请求（`endpoint/bucket/key`）。
- **密钥粘进来时带了空白字符。** 重新输一次。

### `HTTP 404`

endpoint 写错了；或者在 S3 上，这个 bucket 在该账号 / 该 region 下不存在。自建服务的话，看看 API 路径里是不是漏了版本号那一段。

### `HTTP 413`

文件超过了服务端允许的大小。自建的 PHP 图床对应 `php.ini` 里的 `upload_max_filesize` / `post_max_size`，或者 nginx 的 `client_max_body_size`。公共图床有硬限制 —— SM.MS 是 5 MB，Imgur 非动图是 20 MB。

### `HTTP 429`

被限流了。把**设置 → 通用 → 并发上传数**降到 1，然后等一会儿。

### `响应不是合法 JSON，无法读取路径 …`

请求确实到了某个地方，但拿回来的是 HTML、纯文本或者空的。要么 JSON path 该留空（响应体本身*就是*链接），要么这个请求压根没走到上传处理逻辑 —— 登录页或者错误页是这里最常见的响应体。见[解析响应](/zh/docs/guide/response)。

### `响应里找不到路径 …`

路径对这个 API 来说不对。用 `curl` 传一次，看真实结构：

```bash
curl -sS -F "file=@test.png" -H "Authorization: Bearer $TOKEN" \
     https://your-host.example.com/api/upload | jq
```

### `路径 … 上的值不是字符串`

路径停在了对象或数组上。补最后一段 —— `data.links` 通常要写成 `data.links.url`。

## 上传成功了，但链接在浏览器里 404

文件确实传上去了；是 URL 不对，或者对象不是公开的。

1. **对象公开了吗？** S3 需要 bucket 策略或 ACL；R2 需要开公开域名或者绑定自定义域名。只支持签名 URL 的桶，裸链接永远是 404（或者 403）。
2. **公开访问前缀对吗？** Dropline 是按 `前缀 + "/" + key` 拼的，不做任何别的改写。如果你的 CDN 把桶挂在某个子路径下，前缀里要带上这个子路径。
3. **CDN 缓存了 404 吗？** 有些 CDN 会把对象存在之前的 404 缓存下来。刷新那条路径。
4. **和存储控制台对一下。** 在桶的文件浏览器里找到这个对象，复制它显示的路径；如果和你链接的尾部不一样，问题就出在键模板或者前缀上。

## 上传很慢或者卡住

- 单文件传输超时是一小时，所以大视频不会被掐断 —— 但连接真的卡住了它就会一直挂在那儿。取消那一行重试。
- 网络断了时 Dropline 会等待恢复而不是立刻失败，这看起来像卡死。先检查网络。
- 上行带宽跑满就降低并发数；慢网络上开 8 个并发，总耗时反而比 3 个长。

## 收不到通知

macOS 只问一次。如果当初拒绝了，去**系统设置 → 通知**里重新允许 Dropline，并确认**设置 → 通用 → 上传完成后发送系统通知**是开着的。

## 还是不行

带上完整的报错文本和你用的引擎去提 issue：[github.com/chen86860/dropline/issues](https://github.com/chen86860/dropline/issues)。千万不要把 Secret Access Key 或 token 贴进去。

## 下一页

[自行编译 →](/zh/docs/guide/build-from-source)
