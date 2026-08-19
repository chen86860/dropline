---
title: 模板变量
description: Dropline 支持的全部 {{变量}} —— filename、base、ext、uuid、date、datetime、timestamp、rand、key、result，各自能在哪些字段里用，以及常见对象键布局的写法。
---

# 模板变量

图床配置里有好几个字段是模板。形如 `{{name}}` 的地方 —— 中间带空格的 `{{ name }}` 也行 —— 会在请求发出前被替换掉。不认识的名字原样保留，这样打错字会直接体现在结果里，而不是悄悄消失。

## 变量表

| 变量 | 值 | 示例 |
| --- | --- | --- |
| `{{filename}}` | 原始文件名，原样保留，带扩展名 | `My Screenshot.PNG` |
| `{{base}}` | 去掉扩展名的文件名，**已净化** | `My-Screenshot` |
| `{{ext}}` | 扩展名，转小写，不带点 | `png` |
| `{{uuid}}` | 新生成的 UUID，小写十六进制、去掉横线，32 位 | `a1f3c9e04b7d…` |
| `{{date}}` | 今天，本地时间，格式 `yyyy/MM/dd` | `2026/08/19` |
| `{{datetime}}` | 此刻，本地时间，格式 `yyyyMMddHHmmss` | `20260819142233` |
| `{{timestamp}}` | Unix 时间戳，**秒** | `1787148153` |
| `{{rand}}` | 从新 UUID 里取的 6 位小写字符 | `a1f3c9` |
| `{{key}}` | 渲染后的对象键 —— 见下 | `images/2026/08/19/a1f3c9….png` |
| `{{result}}` | 从响应里解析出的链接 —— 见下 | `https://i.host/abc.png` |

### 关于 `{{base}}`

`{{base}}` 会为 URL 做净化。ASCII 字母数字、`-`、`_`、`.` 和 CJK 字符保留，**其余一律变成横线**，空格也算。想让远端名字和本地名字长得像，就用它。只有确实需要原始名字时才用 `{{filename}}` —— 它可能含有需要转义的字符。

### 关于 `{{key}}` 和 `{{result}}`

这两个不是文件属性，而是前面某一步的结果，所以只有那一步跑完之后才存在。

- `{{key}}` 是你的**对象键模板**渲染之后的值。它渲染完立即可用，所以上传地址、请求头、表单字段和最终链接模板里都能引用它。
- `{{result}}` 是[解析响应](/zh/docs/guide/response)那一步的产物。它**只在**最终链接模板里存在。

## 对象键模板

**设置 → 图床 → 你的配置 → 远端文件名 / 对象键模板。**

这是文件在对面的路径。默认是：

```text
{{date}}/{{uuid}}.{{ext}}
```

渲染出来是 `2026/08/19/a1f3c9e04b7d….png`。S3 家族的预设默认多一层前缀：

```text
images/{{date}}/{{uuid}}.{{ext}}
```

这个键*用在哪儿*取决于引擎：

| 引擎 | 键的作用 |
| --- | --- |
| S3 兼容 | 就是对象键。文件确确实实落在这个路径。 |
| 二进制 `PUT`/`POST` | 一般通过 `{{key}}` 拼进上传地址里 |
| `multipart/form-data` | 它的**最后一段**作为表单里的 `filename`；多数图床会忽略它，自己另起名字 |

## 几种常用写法

**日期目录 + 不可猜的文件名** —— 默认写法，多数情况下也是正确答案。不会撞名，URL 也不泄露任何信息。

```text
images/{{date}}/{{uuid}}.{{ext}}
```

**可读，但仍然不撞名** —— 保留原始名字，让 URL 有意义，再加一小段后缀，这样两个 `chart.png` 不会互相覆盖。

```text
blog/{{date}}/{{base}}-{{rand}}.{{ext}}
```

**平铺、可排序** —— 一个目录，名字按时间自然排序。

```text
{{datetime}}-{{rand}}.{{ext}}
```

**按类型分组** —— 前缀分开，方便对图片和视频用不同的生命周期规则。

```text
{{ext}}/{{date}}/{{uuid}}.{{ext}}
```

**完全保留原名** —— 只有在你确定名字唯一时才安全，重名会直接覆盖。

```text
uploads/{{base}}.{{ext}}
```

## 哪些字段支持模板

| 字段 | 可用变量 |
| --- | --- |
| 对象键模板 | 除 `{{key}}`、`{{result}}` 外的全部 |
| 上传地址 | 除 `{{result}}` 外的全部，含 `{{key}}` |
| 自定义请求头的值 | 除 `{{result}}` 外的全部，含 `{{key}}` |
| 额外表单字段的值 | 除 `{{result}}` 外的全部，含 `{{key}}` |
| 最终链接模板 | 全部，含 `{{key}}` 和 `{{result}}` |

**上传地址支持模板**正是二进制引擎能用起来的原因：

```text
https://files.example.com/{{key}}
```

每个文件就 `PUT` 到自己那条路径上。

## 一个完整例子

配置：Cloudflare R2，bucket `assets`，公开访问前缀 `https://cdn.example.com`，键模板 `images/{{date}}/{{uuid}}.{{ext}}`。

2026 年 8 月 19 日，你拖进去一个 `Q3 Revenue.PNG`：

```text
{{filename}} → Q3 Revenue.PNG
{{base}}     → Q3-Revenue
{{ext}}      → png
{{date}}     → 2026/08/19
{{uuid}}     → 6b1d4f2a9c8e47b0a3d5e7f1c2b4a6d8

{{key}}      → images/2026/08/19/6b1d4f2a9c8e47b0a3d5e7f1c2b4a6d8.png
最终结果      → https://cdn.example.com/images/2026/08/19/6b1d4f2a9c8e47b0a3d5e7f1c2b4a6d8.png
```

最后那一行就是落到剪贴板里的东西。

## 下一页

[解析响应 →](/zh/docs/guide/response)
