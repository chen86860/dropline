---
title: 安装
description: 下载 macOS 版 Dropline、第一次启动时绕过 Gatekeeper、打开访达扩展，以及自动更新是怎么下发的。
---

# 安装

Dropline 需要 **macOS 13 Ventura 或更高版本**。发布的安装包面向 Apple Silicon；Intel Mac 请改为[自行编译](/zh/docs/guide/build-from-source)。

## 方式一：DMG

从[最新 Release](https://github.com/chen86860/dropline/releases/latest) 下载 `Dropline.dmg`，打开后把 **Dropline** 拖进「应用程序」文件夹。

发布的安装包不带版本号，所以这个链接永远指向最新的正式版本：

```text
https://github.com/chen86860/dropline/releases/latest/download/Dropline.dmg
```

## 方式二：Homebrew

```bash
brew install --cask chen86860/tap/dropline
```

cask 跟随最新版本，所以不带版本号。Homebrew 会给装好的应用加隔离标记，下面第一次启动那一步仍然要做。

## 第一次启动

构建用的是 **ad-hoc 签名，没有走公证**，所以第一次启动会被 Gatekeeper 拦下，提示应用已损坏或者来自身份不明的开发者。这是正常的，而且只会遇到一次。

要么右键点「应用程序」里的 **Dropline** 选**打开**再确认，要么在终端里清掉隔离标记：

```bash
xattr -dr com.apple.quarantine /Applications/Dropline.app
```

之后每次都能正常打开。

## 打开访达扩展

访达右键菜单第一层的「使用 Dropline 上传」来自一个系统扩展，而 macOS 在你手动批准之前不会启用扩展。

打开**系统设置 → 通用 → 登录项与扩展 → 访达扩展**，把 **Dropline** 勾上。

同一条命令也会出现在**键盘 → 键盘快捷键 → 服务 → 文件和文件夹**下，可以给它配一个快捷键。如果你根本不想让它出现在右键菜单里，把**设置 → 通用 → 访达右键菜单 → 显示方式**设成「不显示」，其它入口照常可用。

## Dropline 待在哪儿

装好以后，Dropline 首先是一个菜单栏应用，其次才是一个窗口。

- **菜单栏图标**提供快速上传和最近 5 条链接，上传时会变成进度环。
- **主窗口**是一个拖放目标，带实时队列和历史记录。
- **程序坞图标**同样可以接收拖放，也可以在**设置 → 通用 → 隐藏程序坞图标**里彻底关掉。

## 自动更新

更新通过 [Sparkle](https://sparkle-project.org) 下发，用 EdDSA 签名。默认会自动检查；你可以在**设置 → 通用 → 软件更新**里关掉，或者打开「自动下载并安装」。更新说明有中英两份，跟着你在设置里选的语言走。

## 卸载

把 `Dropline.app` 拖到废纸篓。会留下两样东西，都无害，也都能在终端里清掉：

```bash
# 偏好设置：图床配置（不含密钥）、各项设置、上传历史
defaults delete dev.emmmm.Dropline

# 钥匙串：每个图床配置一条，存的是它的密钥
security delete-generic-password -s dev.emmmm.Dropline
```

`security` 那条命令每执行一次删掉一条，配过几个图床就执行几次。

## 下一页

[第一次上传 →](/zh/docs/getting-started/quickstart)
