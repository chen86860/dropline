---
title: 密钥与隐私
description: Dropline 把 Access Key 和 token 存在哪里、什么东西会离开你的 Mac、以及怎么给上传用的密钥做最小权限，让它除了上传什么都干不了。
---

# 密钥与隐私

## 不经过任何第三方服务器

Dropline 没有后端。每个请求都是从你的 Mac 直接发到你在图床配置里填的那个接口。不用注册账号、不用登录、没有统计、没有崩溃上报。Dropline 自己发起的网络请求只有 Sparkle 的更新检查，它拉取一份签名过的 appcast，不上报关于你或你文件的任何信息。

## 密钥存在哪儿

密钥存在 **macOS 钥匙串**里，service 为 `dev.emmmm.Dropline`，每个图床配置一条。包括：

- Bearer token
- Basic 鉴权的密码
- 自定义请求头和 URL 查询参数的值
- S3 / R2 / OSS / COS 的 Secret Access Key

其余的东西 —— 配置名、endpoint、region、bucket、Access Key **ID**、各种模板、设置项和上传历史 —— 都在 `~/Library/Preferences/dev.emmmm.Dropline.plist` 里，明文可读。

正因为这个拆分，那个偏好设置文件才可以放心同步、备份，或者贴进 issue 里；也正因如此，钥匙串条目标记为「首次解锁后可用」：开机锁屏期间取不到，解锁之后就可以。

### 自己验证一下

```bash
# 配置文件 —— 在里面搜你的密钥，搜不到
plutil -p ~/Library/Preferences/dev.emmmm.Dropline.plist

# 钥匙串条目 —— 配过几个图床就有几条
security find-generic-password -s dev.emmmm.Dropline
```

## 给存储密钥做最小权限

最值得做的一件事，是给 Dropline 一把只能干它该干的事的钥匙：往一个 bucket 的一个前缀下写对象。这样即使钥匙泄露，也读不了你的桶、删不了东西、碰不到账号里其它任何资源。

### AWS S3 —— 最小策略

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::my-assets/images/*"
    }
  ]
}
```

把它挂到一个专用的 IAM 用户上，再把这个用户的 Access Key 交给 Dropline。注意里面没有 `s3:GetObject`，也没有 `s3:ListBucket` —— Dropline 两个都不需要。

### Cloudflare R2

在 R2 控制台创建一个 **API token**，权限选 *Object Read & Write*，范围限定到这一个 bucket。R2 的 token 无法按前缀收窄，只能按 bucket，所以在 R2 上「一个用途一个 bucket」才是隔离的单位。

### 阿里云 OSS 与腾讯云 COS

用 RAM 子用户（OSS）或者带 CAM 策略的子账号（COS），只授予你上传的那条路径上的 `PutObject`。绝对不要用主账号的密钥。

## 公开的存储桶，以及 URL 泄露了什么

要让返回的链接能在浏览器里打开，对象就必须可公开读取 —— 通过 bucket 策略、R2 的公开域名，或者前面挂一层 CDN。由此有两个推论：

- **任何拿到 URL 的人都能取到文件。** 把每一次上传都当成公开的。
- **URL 本身就是唯一的秘密。** 这也是默认键模板以 `{{uuid}}` 结尾的原因 —— 32 位随机名字猜不出来，而 `uploads/invoice.pdf` 一猜一个准。

如果你在键模板里用了 `{{base}}` 或 `{{filename}}`，记住本地文件名会成为公开 URL 的一部分。

## 第三方图床

上面讲的隐私是关于传输链路的。如果你的配置指向 SM.MS 或 Imgur，那你的文件就在 SM.MS 或 Imgur 手上，受它们的条款约束 —— 它们可以删掉，而 Imgur 的匿名上传更是无主、无保证。这一点 Dropline 改变不了。任何你需要长期留着的东西，请放在自己控制的存储里。

## 关于本网站

App 本身不发送任何关于你的信息；这个网站会统计访问。页面浏览通过 [PostHog](https://posthog.com) 记录，经由代理 `a.emmmm.dev` 转发，用来了解大家在读哪些页面、哪些文档没找到。自动点击采集是关闭的。PostHog 会在 cookie 和本地存储里放一个匿名访客 ID；在浏览器里屏蔽它们，网站照常可用。

## 轮换密钥

在服务商控制台里换掉，然后把新值粘进**设置 → 图床 → 你的配置**。钥匙串条目会当场覆盖。吊销旧密钥之前，先点一次**测试上传**确认新的能用。

## 下一页

[疑难排查 →](/zh/docs/guide/troubleshooting)
