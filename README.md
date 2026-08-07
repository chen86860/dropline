<div align="center">

<img src="assets/logo.png" width="128" alt="Dropline">

# Dropline

**拖进去，链接就在剪贴板里。**

macOS 原生上传工具：拖拽、右键、菜单栏一键上传图片 / 视频 / 任意文件，
完成后自动复制可访问 URL。纯 Swift + SwiftUI，可执行文件仅 ~1 MB。

[![Release](https://img.shields.io/github/v/release/chen86860/dropline?color=2f6feb)](https://github.com/chen86860/dropline/releases/latest)
[![Stars](https://img.shields.io/github/stars/chen86860/dropline?color=f5a623)](https://github.com/chen86860/dropline/stargazers)
[![Downloads](https://img.shields.io/github/downloads/chen86860/dropline/total?color=3fb950)](https://github.com/chen86860/dropline/releases)
![Platform](https://img.shields.io/badge/macOS-13%2B%20·%20Apple%20Silicon-black)
[![License](https://img.shields.io/github/license/chen86860/dropline?color=8957e5)](LICENSE)

</div>

---

## 功能

- **五种上传入口**：拖到窗口 / 拖到 Dock 图标 / 系统文件面板 / 剪贴板（可直接传截图） / **Finder 右键顶层菜单**
- **菜单栏常驻**：上传时图标变进度环，可快速上传并复制最近 8 条链接
- **上传完成自动复制链接 + 系统通知**，可切换 Markdown `![name](url)` 格式
- **任意文件类型**：大视频走临时文件流式上传，不占内存
- 多图床配置随时切换、并发上传、实时进度、历史记录
- 密钥存**系统钥匙串**，不写入配置文件
- 内置 [Sparkle](https://sparkle-project.org) 自动更新

## 支持的图床

内置预设：Amazon S3、Cloudflare R2、阿里云 OSS、腾讯云 COS、MinIO、SM.MS、Imgur、Lsky Pro / Chevereto、EasyImage。

三种引擎覆盖几乎所有服务，也可以完全自定义：

| 引擎 | 适用 |
| --- | --- |
| `multipart/form-data` | 绝大多数图床 API |
| 二进制 `PUT` / `POST` | 自建服务、WebDAV 风格接口 |
| S3 兼容（AWS SigV4） | S3 / R2 / OSS / COS / MinIO |

**认证**：无 / Bearer Token / Basic / 自定义请求头 / URL 查询参数。

### 配置自定义图床

设置 → 图床配置 → 新建：

- **上传地址** `https://your-domain.com/api/upload`
- **响应解析** 填 JSON 路径，如 `data.url`、`files.0.url`；留空表示响应体本身就是 URL
- **最终 URL 模板**（可选）`https://cdn.example.com/{{result}}`，用于接口只返回相对路径的情况
- **对象 Key 模板** `images/{{date}}/{{uuid}}.{{ext}}`

模板变量：`{{filename}} {{base}} {{ext}} {{uuid}} {{date}} {{datetime}} {{timestamp}} {{rand}} {{key}} {{result}}`

配置页底部的「测试上传」会传一张 8×8 测试图，直接显示返回的 URL 或错误原因。

## 安装

到 [Releases](https://github.com/chen86860/dropline/releases/latest) 下载，拖进「应用程序」即可。

ad-hoc 签名，首次打开右键 App →「打开」，或：

```bash
xattr -dr com.apple.quarantine /Applications/Dropline.app
```

右键菜单项没出现时，到「系统设置 → 通用 → 登录项与扩展 → 访达扩展」打开 Dropline。
（另外在「键盘 → 键盘快捷键 → 服务 → 文件与文件夹」里还有一个同名的服务项，可为它设快捷键。）

## 从源码构建

要求 macOS 13+、Xcode 命令行工具（Swift 5.9+）。

```bash
./build.sh --install     # 构建 + 装到 /Applications + 注册右键服务
./build.sh               # 只构建到 dist/
```

> 磁盘上只能存在一份 Dropline.app——两份副本会让 LaunchServices 在它们之间摇摆，
> 右键服务菜单随之失效。`--install` 用 `mv` 而非 `cp`，装完 `dist/` 里不会有残留。

## 发布新版本

先在 [CHANGELOG.md](CHANGELOG.md) 顶部加一节 `## [1.0.1] - 日期`，再执行：

```bash
./Tools/sparkle.sh release 1.0.1   # 构建 → 打包 → EdDSA 签名 → 生成 appcast → 发 Release → 推送
```

CHANGELOG 是发布说明的唯一来源：脚本从中抽取对应版本的条目，转成 HTML 供 Sparkle
更新弹窗显示，同时用 Markdown 原文作为 GitHub Release 正文。**没写条目会直接报错中止**，
不会发出没有说明的版本。

更新包用 EdDSA 签名，公钥在 Info.plist，私钥存登录钥匙串。
正式分发时带上 Developer ID，脚本会自动启用 hardened runtime 与时间戳（公证所需）：

```bash
DROPLINE_SIGN_ID="Developer ID Application: NAME (TEAMID)" ./Tools/sparkle.sh release 1.0.1
```

## 代码结构

```
Sources/Dropline/
  DroplineApp.swift    入口、菜单栏托盘、Dock 拖放、AppDelegate
  AppState.swift       配置、上传队列与并发调度、历史、剪贴板
  Models.swift         配置模型与图床预设
  UploadService.swift  multipart / 二进制 / S3 三种上传实现
  S3Signer.swift       AWS Signature V4（流式 SHA256）
  Templating.swift     {{变量}} 渲染 + JSON 路径取值
  Updater.swift        Sparkle 封装
  Notifier.swift       系统通知
  TrayIcon.swift       菜单栏进度环图标
  Keychain.swift       密钥存取
  ContentView.swift    主窗口
  SettingsView.swift   设置（图床 / 通用 / 右键上传 / 关于）

Sources/DroplineFinder/
  FinderSyncExtension.swift   Finder 右键扩展（沙盒，经 dropline:// 把选中文件交给主 App）

Tools/
  sparkle.sh       发布助手
  changelog.py     从 CHANGELOG.md 抽取版本条目，输出 Markdown / HTML
  makeicon.swift   生成 App 图标
```

## 许可证

[MIT](LICENSE)
