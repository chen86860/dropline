# Dropline

macOS 原生（Swift + SwiftUI + AppKit）文件 / 图床上传工具，Apple Silicon 原生编译。
**没有使用 Electron / Tauri / WebView**，整个 App 只有一个 ~1MB 的原生可执行文件。

## 功能

- **多种上传入口**
  - 拖拽到主窗口虚线区域
  - 拖拽到 Dock 图标
  - 主窗口「选择文件…」调用系统面板（`NSOpenPanel`，支持多选与文件夹递归）
  - 「从剪贴板上传」——可直接上传刚截的图
  - **Finder 右键 →「服务」→「使用 Dropline 上传」**（macOS Services，支持多选）
  - **系统托盘（菜单栏）** 图标：快速上传 / 查看并复制最近 8 条链接
- **上传完成后默认把可访问 URL 写入剪贴板**（可切换为 Markdown `![name](url)` 格式）
- **任意文件类型**：图片、视频、压缩包……大文件走临时文件流式上传，不占内存
- **多图床配置**，可随时在主窗口下拉框切换默认图床
- 并发上传（可配 1/2/3/5/8）、实时进度、失败原因展示、历史记录（本地保存 300 条）
- 密钥 / Token 存放在 **系统钥匙串（Keychain）**，不写入配置文件

## 支持的图床 / 存储

内置预设：Amazon S3、Cloudflare R2、阿里云 OSS、腾讯云 COS、MinIO、SM.MS、Imgur、Lsky Pro / Chevereto、EasyImage，以及两个空白自定义模板。

三种上传方式覆盖几乎所有服务：

| 方式 | 说明 |
| --- | --- |
| `multipart/form-data` | 绝大多数图床 API（自定义文件字段名、附加表单字段、自定义请求头） |
| 二进制 `PUT` / `POST` | 请求体直接是文件内容，适合自建服务 / WebDAV 风格接口 |
| S3 兼容（AWS SigV4） | S3 / R2 / OSS / COS / MinIO，本地实现签名，无第三方依赖 |

**认证方式**：无 / Bearer Token / Basic / 自定义请求头 / URL 查询参数。

### 自定义域名 + 认证怎么配

在「设置 → 图床配置」里新建一个配置：

- **上传地址**：`https://your-domain.com/api/upload`（支持模板变量）
- **认证**：选 Bearer / 自定义头 / Query 参数，填入密钥（存 Keychain）
- **响应解析**：填 JSON 路径，如 `data.url`、`data.links.url`、`files.0.url`；留空表示响应体本身就是 URL
- **最终 URL 模板**（可选）：如 `https://cdn.example.com/{{result}}`，用于接口只返回相对路径的情况
- **对象 Key 模板**：`images/{{date}}/{{uuid}}.{{ext}}`

可用模板变量：`{{filename}} {{base}} {{ext}} {{uuid}} {{date}} {{datetime}} {{timestamp}} {{rand}} {{key}} {{result}}`

配置页底部有「测试上传」，会传一张 8×8 的测试图并直接显示返回的 URL 或错误原因。

## 构建与安装

```bash
./build.sh --install     # 编译 + 打包 + 装到 /Applications + 注册右键服务（推荐）
./build.sh               # 只构建到 dist/，用于开发调试
```

要求：macOS 13+、Xcode 命令行工具（Swift 5.9+）。

首次打开若被 Gatekeeper 拦截（ad-hoc 签名），右键 App →「打开」，或
`xattr -dr com.apple.quarantine /Applications/Dropline.app`。

**重要：磁盘上同一时间只能存在一份 Dropline.app。** 只要 `dist/` 里还留着一份副本，
LaunchServices 迟早会把它重新索引，形成同一 Bundle ID 的两份注册，右键服务菜单就会消失
或点了没反应。因此 `--install` 是 **move 而非 copy**：装完 `dist/Dropline.app` 就不存在了。
构建脚本末尾会检查重复注册并告警；手动挪动过 App 后请重新执行一次 `./build.sh --install`。

右键服务菜单没出现时：系统设置 → 键盘 → 键盘快捷键 → 服务 → 文件与文件夹，勾选「使用 Dropline 上传」（也可在此设快捷键）。

## 标识符

| 项 | 值 |
| --- | --- |
| Bundle ID | `dev.emmmm.Dropline` |
| 钥匙串服务名 | `dev.emmmm.Dropline` |
| 配置存储 | UserDefaults 域 `dev.emmmm.Dropline` |
| 服务端口名 | `Dropline`（`NSPortName` 必须与 `CFBundleName` 一致，否则右键服务失效） |

改动 Bundle ID 会同时换掉钥匙串与 UserDefaults 的位置，已有配置需要重新填写。

## 代码结构

```
Sources/Dropline/
  DroplineApp.swift    App 入口、菜单栏托盘、Dock 拖放、AppDelegate
  AppState.swift       全局状态：配置、上传队列与并发调度、历史、剪贴板
  Models.swift         配置模型与内置图床预设
  UploadService.swift  multipart / 二进制 / S3 三种上传实现 + 进度
  S3Signer.swift       AWS Signature V4（流式 SHA256，支持大文件）
  Templating.swift     {{变量}} 渲染 + JSON 路径取值
  Keychain.swift       密钥存取
  ContentView.swift    主窗口：拖拽区、队列、历史
  SettingsView.swift   设置：图床配置编辑器、通用选项、右键上传说明
```

## 验证情况

针对本地测试服务器做过端到端验证，均通过：

- multipart 上传：文件内容 SHA256 与源文件一致、Bearer / 自定义头 / Query 认证、附加表单字段、URL 模板变量渲染、进度回调到 100%
- 二进制 PUT 上传：路径模板与响应改写正确
- S3 SigV4：签名与 Python 独立实现逐位一致，`x-amz-content-sha256` 与文件哈希一致
- 错误处理：JSON 路径缺失、非法地址均给出可读中文提示
- GUI：主窗口渲染正常，菜单栏托盘项已注册
- **Finder 右键全链路**：Finder 选中文件 → 服务 → 「使用 Dropline 上传」→ App 收到 → 上传成功 → URL 自动进剪贴板
- 设置窗口：齿轮按钮 / 托盘「设置…」均可打开，字段可输入并即时持久化
- 主窗口关闭后可通过 Dock、`open`、托盘「打开主窗口」唤回

### 踩过的坑（改动原因）

| 现象 | 原因 | 修法 |
| --- | --- | --- |
| Finder 右键没有服务菜单 | 文件类服务写成了 `NSSendFileTypes: public.item` | 改为 `NSSendTypes: NSFilenamesPboardType` + `NSRequiredContext/NSTextContent = FilePath`（与系统上其他生效服务一致） |
| 服务菜单时有时无 / 点击无反应 | `/Applications` 与 `dist/` 同时存在同 Bundle ID 的两份副本，LaunchServices 在两者间摇摆（`lsregister -u` 也挡不住系统重新索引 `dist/`） | `--install` 改为 `mv`，磁盘上只保留一份；脚本末尾检查重复注册 |
| 齿轮 / 托盘「设置…」点了没反应 | `NSApp.sendAction(showSettingsWindow:)` 在新版 macOS 已失效 | 改用 `SettingsLink`，并保留遍历应用菜单的兜底 |
| 关掉主窗口后 App 像卡死 | 关窗后 SwiftUI 不会自动重建窗口 | 实现 `applicationShouldHandleReopen`，复用已有 NSWindow |
