---
title: 自行编译
description: 克隆仓库、用 build.sh 自己编译 Dropline —— 脚本做了哪些事、怎么安装并注册访达扩展、以及在 Intel Mac 上怎么编。
---

# 自行编译

Dropline 是一个 Swift Package，两个可执行目标（主 App 和访达扩展），唯一的依赖是 [Sparkle](https://sparkle-project.org)。编译它不需要 Xcode 命令行工具之外的任何东西。

## 环境要求

- macOS 13 Ventura 或更高版本
- Xcode 15 及以上，或者命令行工具（`xcode-select --install`）
- Swift 5.9+（随上面一起装好）

## 编译并安装

```bash
git clone https://github.com/chen86860/dropline.git
cd dropline
./build.sh --install
```

就这些。`--install` 多做的那些事，在这个项目上比在多数应用上都更要紧：

1. 退出正在运行的副本
2. 卸载旧版本
3. 注销失效的 LaunchServices 注册 —— **磁盘上同时存在两份 `Dropline.app` 会让服务菜单和访达菜单项失效**，所以这一步不是可选的
4. 把 bundle 拷到 `/Applications`
5. 注册服务菜单项并启用访达扩展
6. 启动应用

不带 `--install` 的话，脚本产出 `dist/Dropline.app` 就停了。这适合拿来看看，但右键菜单项不会正常工作。

## 脚本做了什么

```text
swift build -c release --arch arm64      # 编译
组装 Dropline.app                        # bundle 结构
打包 DroplineFinder.appex                # 访达扩展
嵌入 Sparkle.framework                   # 来自已解析的依赖
生成图标                                  # tools/makeicon.swift
写入 Info.plist                          # 版本号、feed 地址、EdDSA 公钥
codesign --sign -                        # ad-hoc 签名
```

版本号取自 `CHANGELOG.md` 里最新的一条，所以构建不会和发布说明对不上。需要的话可以覆盖：

```bash
DROPLINE_VERSION=1.4.1 ./build.sh --install
```

## 签名

默认是 **ad-hoc 签名**，这也是为什么下载的正式版需要走一次 [Gatekeeper 那一步](/zh/docs/getting-started/install#第一次启动)。本地编出来的那份一般不带隔离标记，直接就能打开。

如果你有 Developer ID 证书：

```bash
DROPLINE_SIGN_ID="Developer ID Application: Your Name (TEAMID)" ./build.sh --install
```

## 在 Intel Mac 上编译

脚本写死了 `--arch arm64`，和发布的包保持一致。在 Intel 上把那一行改成你的架构，或者干脆去掉这个参数按宿主机编：

```diff
-swift build -c release --arch arm64
+swift build -c release
```

脚本里其余部分与架构无关。应用本身没有任何 Apple Silicon 专属的东西，只是发布的二进制是这么编的。

## 项目结构

| 路径 | 内容 |
| --- | --- |
| `Sources/Dropline` | 主 App —— SwiftUI 视图、状态、上传引擎 |
| `Sources/DroplineFinder` | 访达扩展（`.appex`） |
| `Sources/Dropline/UploadService.swift` | 三种引擎与请求构造 |
| `Sources/Dropline/S3Signer.swift` | AWS SigV4，path-style `PUT` |
| `Sources/Dropline/Templating.swift` | `{{变量}}` 渲染与 JSON path 取值 |
| `Sources/Dropline/Models.swift` | 配置模型与全部内置预设 |
| `tools/` | 图标、DMG、changelog、Sparkle 相关脚本 |
| `website/` | 这个站点 —— 跑在 Cloudflare Workers 上的 TanStack Start |

想加一个预设的话，`Models.swift` 里的 `ProfilePresets` 是唯一需要改的地方；它直接驱动设置 → 图床里的 **+** 菜单。

## 编译出问题

**`❌ 找不到 Sparkle.framework`** —— 先解析依赖：

```bash
swift package resolve
```

**装完之后右键菜单项没出现** —— 多半是别处还有一份副本。`./build.sh --install` 会清理失效注册，而只跑 `./build.sh` 再自己拖 bundle 不会。

**重新编译后没有任何变化** —— 先退出正在运行的应用；`--install` 会替你做这件事。

## 下一页

[图床配置 →](/zh/docs/hosts/overview)
