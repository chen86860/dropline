import Foundation
import AppKit

/// 界面语言。
///
/// 源码里一律写英文原文，中文按 `L10n.zh` 查表翻译 —— 查不到就原样返回英文，
/// 所以「兜底英文」是这套机制的天然行为，漏翻一条也只是显示英文，不会显示 key。
enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case system
    case english
    case chinese

    var id: String { rawValue }

    /// 语言名用它自己的语言写，这样在任何界面语言下都认得出来
    var label: String {
        switch self {
        case .system:  return "Follow System".t
        case .english: return "English"
        case .chinese: return "简体中文"
        }
    }
}

enum L10n {
    enum Resolved { case en, zh }

    /// 当前生效的语言，由 AppState 在启动时和用户切换时设置
    static var language: AppLanguage = .system {
        didSet { resolved = resolve(language) }
    }

    private(set) static var resolved: Resolved = resolve(.system)

    /// 只有系统首选语言是中文才用中文，其余一律英文
    static func resolve(_ language: AppLanguage) -> Resolved {
        switch language {
        case .english: return .en
        case .chinese: return .zh
        case .system:
            let preferred = Locale.preferredLanguages.first ?? "en"
            return preferred.hasPrefix("zh") ? .zh : .en
        }
    }

    static func string(_ english: String) -> String {
        guard resolved == .zh, let zh = table[english] else { return english }
        return zh
    }

    private static let table: [String: String] = [
        // MARK: 通用动作
        "Copy Link": "复制链接",
        "Copy as Markdown": "复制 Markdown",
        "Open in Browser": "在浏览器打开",
        "Link copied": "已复制链接",
        "Settings": "设置",
        "Settings…": "设置…",
        "Check for Updates…": "检查更新…",

        // MARK: 主窗口
        "Upload Queue": "上传队列",
        "History": "历史记录",
        "Drag · Panel · Right-click": "拖拽 · 面板 · 右键上传",
        "Host": "图床",
        "Release to upload": "松手即可上传",
        "Drop images, videos, or any file here": "把图片 / 视频 / 任意文件拖到这里",
        "Choose Files…": "选择文件…",
        "Upload from Clipboard": "从剪贴板上传",
        "No image or file in the clipboard": "剪贴板里没有可上传的图片或文件",
        "No uploads yet": "暂无上传任务",
        "No history yet": "还没有上传记录",
        "Remove from Queue": "从队列移除",
        "Clear Finished": "清除已完成",
        "Clear History": "清空历史",
        "Waiting…": "等待中…",
        "Yesterday %@": "昨天 %@",

        // MARK: 菜单栏 / 主菜单
        "Upload Files…": "上传文件…",
        "Copy Latest Link": "复制最近链接",
        "Choose Files to Upload…": "选择文件上传…",
        "Upload File in Clipboard": "上传剪贴板中的文件",
        "No file in the clipboard": "剪贴板里没有文件",
        "Uploading %d file(s)…": "正在上传 %d 个文件…",
        "All uploads finished": "队列已全部完成",
        "Recent Uploads": "最近上传",
        "Open Main Window": "打开主窗口",
        "Quit Dropline": "退出 Dropline",

        // MARK: 设置 · 标签页
        "General": "通用",
        "Hosts": "图床配置",
        "About": "关于",

        // MARK: 设置 · 通用
        "Copy the link to the clipboard when an upload finishes": "上传完成后自动把链接复制到剪贴板",
        "Copy as Markdown ![name](url)": "复制为 Markdown 格式 ![name](url)",
        "Send a system notification when an upload finishes": "上传完成后发送系统通知",
        "Hide the Dock icon (menu bar only)": "隐藏 Dock 图标（仅保留菜单栏图标）",
        "Concurrent uploads": "同时上传数量",
        "Appearance": "外观",
        "Color scheme": "配色",
        "Light": "浅色",
        "Dark": "深色",
        "Applies to Dropline only, the system appearance is unchanged.":
            "只影响 Dropline 自己，不改变系统外观。",
        "Language": "语言",
        "Interface language": "界面语言",
        "Follow System": "跟随系统",
        "Takes effect immediately, no restart needed.": "切换后立即生效，无需重启。",
        "Software Update": "软件更新",
        "Check for updates automatically": "自动检查更新",
        "Download and install updates automatically": "自动下载并安装更新",
        "Current version": "当前版本",
        "Last checked": "上次检查",
        "Never": "从未",
        "Check Now": "现在检查更新",

        // MARK: 设置 · 关于
        "Drop it in, the link is on your clipboard": "拖进去，链接就在剪贴板里",
        "Version %@": "版本 %@",
        "Documentation": "使用文档",
        "Dropline Help": "Dropline 帮助",
        "Project Home": "项目主页",
        "Report an Issue": "反馈问题",
        "(not configured)": "(未配置)",

        // MARK: 设置 · 右键上传
        "Finder Context Menu": "访达右键菜单",
        "Show as": "显示方式",
        "Show (with icon)": "显示（带图标）",
        "Show (without icon)": "显示（不带图标）",
        "Don’t show": "不显示",
        "Shows “Upload with Dropline” at the top of the context menu, with an upload icon.":
            "右键菜单顶层显示「使用 Dropline 上传」，前面带一个上传图标。",
        "Shows “Upload with Dropline” at the top of the context menu, without an icon, matching system items.":
            "右键菜单顶层显示「使用 Dropline 上传」，不带图标，与系统菜单项风格一致。",
        "Dropline stays out of the context menu. Drag & drop, the clipboard, the menu bar and the Services menu item all keep working.":
            "右键菜单里不出现 Dropline。仍可用拖放、剪贴板、菜单栏，以及「服务」菜单里的同名项上传。",
        "Takes effect immediately. If the item is missing, turn Dropline on in System Settings → General → Login Items & Extensions → Finder Extensions.":
            "修改后立即生效。菜单里没出现时，到「系统设置 → 通用 → 登录项与扩展 → 访达扩展」中打开 Dropline。",
        "You can also drop files on the window or the Dock icon, upload from the clipboard, or use the menu bar icon.":
            "也可以把文件拖到窗口或 Dock 图标、从剪贴板上传，或用菜单栏图标。",

        // MARK: 设置 · 图床配置
        "Set as Default": "设为默认",
        "Create a host profile with “+” at the bottom left": "左下角「+」新建一个图床配置",
        "Name": "名称",
        "Upload method": "上传方式",
        "Remote filename / object key template": "远端文件名 / 对象 Key 模板",
        "Variables: {{filename}} {{base}} {{ext}} {{uuid}} {{date}} {{datetime}} {{timestamp}} {{rand}}":
            "可用变量：{{filename}} {{base}} {{ext}} {{uuid}} {{date}} {{datetime}} {{timestamp}} {{rand}}",
        "Test Upload": "测试上传",
        "Could not generate a test image": "无法生成测试图片",
        "Success: %@": "成功：%@",
        "Request": "请求",
        "Upload URL": "上传地址",
        "Method": "方法",
        "File field name": "文件字段名",
        "Custom headers": "自定义请求头",
        "Extra form fields": "附加表单字段",
        "Authentication": "认证",
        "Kind": "方式",
        "Username": "用户名",
        "Password": "密码",
        "Header name": "Header 名",
        "Header value": "Header 值",
        "Parameter name": "参数名",
        "Parameter value": "参数值",
        "The secret is stored in the system keychain, never in the config file.":
            "密钥保存在系统钥匙串，不会写入配置文件。",
        "Response": "响应解析",
        "JSON path": "JSON 取值路径",
        "data.url (empty means the body itself is the URL)": "data.url（留空表示响应体本身就是 URL）",
        "Final URL template (optional)": "最终 URL 模板（可选）",
        "{{result}} is the value parsed above; {{key}}, {{filename}} and friends also work.":
            "模板中 {{result}} 为上一步解析出的值，也可使用 {{key}}、{{filename}} 等变量。",
        "Object Storage": "对象存储",
        "Empty = AWS; R2: https://<account>.r2.cloudflarestorage.com":
            "留空 = AWS；R2: https://<account>.r2.cloudflarestorage.com",
        "Public base URL (optional)": "公开访问域名（可选）",
        "Empty means the Endpoint/Bucket/Key URL is returned. Both the Access Key ID and the Secret Access Key are stored in the system keychain.":
            "留空则使用 Endpoint/Bucket/Key 作为返回链接。Access Key ID 与 Secret Access Key 都保存在系统钥匙串。",
        "(none)": "（无）",
        "Store this value in the keychain instead of the config file": "把这一项的值存进钥匙串，不写入配置文件",
        "Click the lock on a row holding a token or key — its value moves to the system keychain.":
            "某一行放的是 Token 或密钥时，点一下锁，它的值就会转存到系统钥匙串。",

        // MARK: 设置 · 配置备份
        "Back up or restore your upload profiles": "备份或恢复上传配置",
        "Export Profiles…": "导出配置…",
        "Import Profiles…": "导入配置…",
        "Export Profiles": "导出配置",
        "Profile settings are written as readable JSON. Secrets (tokens, access keys) are included only with a password, and are encrypted with it — they are never written in the clear.":
            "配置本身以可读的 JSON 写出。Token、密钥等机密项只有设置口令后才会包含，并用该口令加密 —— 任何情况下都不会明文落盘。",
        "Include secrets": "包含密钥",
        "Backup password": "备份口令",
        "Confirm backup password": "确认备份口令",
        "Use a password of at least 8 characters": "口令至少 8 个字符",
        "The two passwords don’t match": "两次输入的口令不一致",
        "Keep this password safe — without it the secrets cannot be restored.":
            "请保管好这个口令，丢了就无法恢复其中的密钥。",
        "Without secrets you will have to re-enter every token and key after importing.":
            "不含密钥时，导入后需要重新填写每个配置的 Token 和密钥。",
        "Cancel": "取消",
        "Export…": "导出…",
        "Import": "导入",
        "Choose where to save the profile backup": "选择配置备份的保存位置",
        "Choose a Dropline profile backup": "选择 Dropline 配置备份文件",
        "Exported %d profile(s) to %@": "已导出 %d 个配置到 %@",
        "Imported %d profile(s)": "已导入 %d 个配置",
        "Imported %d profile(s). This backup carried no secrets — fill in the tokens and keys for each one.":
            "已导入 %d 个配置。该备份不含密钥，请为每个配置补填 Token 和密钥。",
        "This backup is password-protected": "该备份已用口令加密",
        "Backup failed": "备份出错",
        "Done": "完成",
        "Not a Dropline profile backup": "这不是 Dropline 的配置备份文件",
        "Wrong password, or the file has been modified": "口令不对，或文件已被改动",
        "Could not read the backup: %@": "无法读取备份文件：%@",

        // MARK: 上传方式 / 鉴权
        "Form upload (multipart/form-data)": "表单上传 (multipart/form-data)",
        "Binary upload (PUT/POST raw body)": "二进制上传 (PUT/POST raw body)",
        "S3-compatible object storage (AWS/R2/MinIO)": "S3 兼容对象存储 (AWS/R2/MinIO)",
        "None": "无",
        "Basic (username + password)": "Basic (用户名 + 密码)",
        "Custom header": "自定义请求头",
        "URL query parameter": "URL 查询参数",

        // MARK: 预设
        "Blank · Custom HTTP": "空白 · 自定义 HTTP",
        "Blank · Custom binary PUT": "空白 · 自定义二进制 PUT",
        "Aliyun OSS (S3-compatible)": "阿里云 OSS（S3 兼容）",
        "Tencent COS (S3-compatible)": "腾讯云 COS（S3 兼容）",
        "MinIO / self-hosted S3": "MinIO / 自建 S3",
        "EasyImage / PicGo custom": "EasyImage / PicGo 自定义",
        "Custom Upload": "自定义上传",
        "Custom PUT Upload": "自定义 PUT 上传",
        "Aliyun OSS": "阿里云 OSS",
        "Tencent COS": "腾讯云 COS",
        "New Profile": "新建配置",
        "S3-compatible storage": "S3 兼容存储",
        "No URL configured": "未配置地址",

        // MARK: 通知 / 状态
        "Upload finished": "上传完成",
        "Upload failed": "上传失败",
        "Uploaded %@": "已上传 %@",
        "Uploaded %@, link copied": "已上传 %@，链接已复制",
        "Upload failed: %@": "上传失败：%@",
        "Add an upload profile in Settings first": "请先在「设置」中添加一个上传配置",
        "Open Settings from the menu bar: Dropline → Settings… (⌘,)":
            "请从菜单栏「Dropline → 设置…」(⌘,) 打开设置",
        "Choose images, videos, or any file to upload": "选择要上传的图片 / 视频 / 任意文件",
        "Upload": "上传",
        "Upload to Dropline": "上传到 Dropline",
        "No files to upload": "没有可上传的文件",
        "Upload with Dropline": "使用 Dropline 上传",

        // MARK: 错误
        "Invalid upload URL: %@": "上传地址无效：%@",
        "Incomplete configuration: %@": "配置不完整：%@",
        "(empty)": "(空)",
        "missing Bucket": "缺少 Bucket",
        "missing Access Key ID / Secret Access Key": "缺少 Access Key ID / Secret Access Key",
        "The response is not valid JSON, cannot read path `%@`": "响应不是合法 JSON，无法按路径 `%@` 取值",
        "Path `%@` not found in the response": "响应中找不到路径 `%@`",
        "The value at path `%@` is not a string": "路径 `%@` 对应的值不是字符串",
    ]
}

// MARK: - 文档站

enum DocsLink {
    /// 文档分中英两套，跟 App 内的界面语言走（不是系统语言）
    static var url: String {
        L10n.resolved == .zh
            ? "https://dropline.emmmm.dev/zh/docs"
            : "https://dropline.emmmm.dev/docs"
    }

    static func open() {
        if let u = URL(string: url) { NSWorkspace.shared.open(u) }
    }
}

extension String {
    /// 源码里的英文原文 → 当前语言。查不到就原样返回，天然兜底英文。
    var t: String { L10n.string(self) }

    /// 带参数的文案，原文里用 %@ / %d 占位
    func t(_ arguments: CVarArg...) -> String {
        String(format: L10n.string(self), arguments: arguments)
    }
}
