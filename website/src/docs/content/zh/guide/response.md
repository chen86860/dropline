---
title: 解析响应
description: Dropline 怎么从上传接口的响应里把公开链接取出来 —— 支持数组下标的 JSON path、纯文本响应体，以及把相对路径改写到你 CDN 域名下的最终链接模板。
---

# 解析响应

你的图床会返回点什么。Dropline 要做的是把这个「点什么」变成一条 URL。两个字段负责这件事，按顺序执行。

1. **JSON path** —— 从响应体里挑出一个值 → `{{result}}`
2. **最终链接模板** —— 可选，把它改写成你真正想要的链接

两个都在**设置 → 图床 → 你的配置 → 响应**下。它们适用于 `multipart/form-data` 和二进制引擎；[S3 引擎](/zh/docs/hosts/s3)是用 bucket 和 key 自己拼出链接的，不走 JSON path。

## JSON path

一条点号分隔的路径，指向解析后的 JSON。每一段要么是对象的键，要么是**数组下标**。

对于这样的响应：

```json
{
  "status": "success",
  "data": {
    "url": "https://i.example.com/2026/abc.png",
    "thumb": "https://i.example.com/2026/abc.thumb.png"
  }
}
```

路径就是：

```text
data.url
```

如果结果被包在数组里：

```json
{
  "files": [
    { "url": "https://i.example.com/abc.png", "size": 20481 }
  ]
}
```

下标就是普通的一段：

```text
files.0.url
```

除了字符串，数字也能取 —— 返回值是个纯数字 id 也能用，会被转成字符串。

### 响应体本身就是链接

很多自建接口只返回一条链接，别的什么都没有：

```text
https://files.example.com/2026/08/abc.png
```

这时**把 JSON path 留空**。Dropline 会取整个响应体，去掉首尾空白和换行，当作 `{{result}}`。返回空响应体的接口也该这么设，再配一个用 `{{key}}` 拼出来的最终链接模板。

### 怎么找到正确的路径

不知道响应长什么样，最快的办法是点**测试上传**。失败时 Dropline 会把消息摆出来；路径取不到值时它说得很明确：

```text
响应里找不到路径 `data.url`
```

再不行就用 `curl` 手动传一次看看：

```bash
curl -sS -F "file=@test.png" \
     -H "Authorization: Bearer $TOKEN" \
     https://your-host.example.com/api/upload | jq
```

## 最终链接模板

**可选。** 留空则直接用 `{{result}}` —— 接口本来就返回绝对 URL 时，这是对的。

不是绝对 URL 时才填它。这里能用全部[模板变量](/zh/docs/guide/templates)，外加 `{{result}}`。

### 相对路径 → 绝对 URL

接口返回 `2026/08/abc.png`，而你的文件由 CDN 域名提供：

```text
https://cdn.example.com/{{result}}
```

### 无视响应，直接用 key 拼

接口什么有用的东西都没返回，但文件去哪儿了你本来就知道，因为是你的键模板决定的：

```text
https://files.example.com/{{key}}
```

配一个空的 JSON path 一起用。

### 换个域名

接口返回的是源站 URL，而你前面挂了 CDN。这里没有字符串替换函数，所以改为用 key 拼：

```text
https://cdn.example.com/{{key}}
```

## 三条报错分别是什么意思

| 报错 | 原因 | 怎么改 |
| --- | --- | --- |
| `响应不是合法 JSON，无法读取路径 …` | 你填了 JSON path，但响应体是 HTML、纯文本或者空的 | 如果响应体本身就是链接，把 JSON path 清空；否则请求多半没到上传处理逻辑就被拒了 —— 检查地址和鉴权 |
| `响应里找不到路径 …` | 响应能解析，但里面没有这条路径 | 用 `curl` 跑一次看真实结构，改路径 |
| `路径 … 上的值不是字符串` | 路径停在了对象或数组上，不是叶子节点 | 补上最后一段，比如 `data.links` → `data.links.url` |

## 下一页

[密钥与隐私 →](/zh/docs/guide/security)
