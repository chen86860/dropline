import Cocoa
import FinderSync

/// Finder 扩展：在访达右键菜单顶层加一项「使用 Dropline 上传」。
/// 与「服务」菜单不同，它会出现在「系统设置 → 通用 → 登录项与扩展 → 访达扩展」里。
@objc(DroplineFinderSync)
final class DroplineFinderSync: FIFinderSync {

    override init() {
        super.init()
        // 监听所有已挂载卷，这样在任何位置右键都能出现菜单项
        var roots: Set<URL> = [URL(fileURLWithPath: "/")]
        let volumes = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: nil, options: [.skipHiddenVolumes]) ?? []
        roots.formUnion(volumes)
        FIFinderSyncController.default().directoryURLs = roots
    }

    // MARK: 工具栏

    override var toolbarItemName: String { "Dropline" }
    override var toolbarItemToolTip: String {
        isChinese ? "上传到 Dropline" : "Upload to Dropline"
    }
    override var toolbarItemImage: NSImage {
        NSImage(systemSymbolName: "arrow.up.circle", accessibilityDescription: "Dropline")
            ?? NSImage(size: NSSize(width: 1, height: 1))
    }

    // MARK: 右键菜单

    /// 主 App 写在本扩展容器里的配置。每次弹菜单都读一次，改完立即生效。
    private func sharedValue(_ fileName: String) -> String? {
        let url = URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/Application Support/Dropline/\(fileName)")
        guard let raw = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        return raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 取值：icon（带图标）/ text（不带图标）/ hidden（不显示），缺省为 icon
    private var menuMode: String {
        guard let value = sharedValue("finder-menu.txt"),
              ["icon", "text", "hidden"].contains(value) else { return "icon" }
        return value
    }

    /// 界面语言。主 App 写的是解析后的结果；文件还不存在时（扩展先跑起来）
    /// 退回自己判断系统语言，同样是「中文用中文，其余一律英文」。
    private var isChinese: Bool {
        if let value = sharedValue("finder-language.txt") { return value == "zh" }
        return (Locale.preferredLanguages.first ?? "en").hasPrefix("zh")
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        // 只在选中文件/文件夹、或在文件夹空白处右键时提供
        switch menuKind {
        case .contextualMenuForItems, .contextualMenuForContainer, .toolbarItemMenu:
            break
        default:
            return nil
        }
        let mode = menuMode
        guard mode != "hidden" else { return nil }

        let menu = NSMenu(title: "")
        let item = NSMenuItem(title: isChinese ? "使用 Dropline 上传" : "Upload with Dropline",
                              action: #selector(uploadSelection(_:)),
                              keyEquivalent: "")
        item.target = self
        if mode == "icon" {
            item.image = NSImage(systemSymbolName: "arrow.up.circle", accessibilityDescription: nil)
        }
        menu.addItem(item)
        return menu
    }

    /// 扩展是沙盒进程，不能把选中的文件直接「移交」给另一个 App
    /// （`NSWorkspace.open(urls, withApplicationAt:)` 会报 does not have permission）。
    /// 这里只把路径清单写进自己的临时目录，再用 URL scheme 叫主 App 自己去读——
    /// 主 App 未沙盒化，读取任意路径没有限制。
    @objc func uploadSelection(_ sender: AnyObject?) {
        let urls = FIFinderSyncController.default().selectedItemURLs() ?? []
        guard !urls.isEmpty else { return }

        let listURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("dropline-\(UUID().uuidString).paths")
        let payload = urls.map(\.path).joined(separator: "\n")
        guard (try? payload.write(to: listURL, atomically: true, encoding: .utf8)) != nil else { return }

        var comps = URLComponents()
        comps.scheme = "dropline"
        comps.host = "upload"
        comps.queryItems = [URLQueryItem(name: "list", value: listURL.path)]
        if let url = comps.url {
            // activates = false：只把清单递过去，不把主 App 拉到前台。
            // 上传进度看菜单栏图标就够了，用户的视线应该留在访达里。
            let config = NSWorkspace.OpenConfiguration()
            config.activates = false
            NSWorkspace.shared.open(url, configuration: config)
        }
    }
}
