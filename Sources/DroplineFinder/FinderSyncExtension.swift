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
    override var toolbarItemToolTip: String { "上传到 Dropline" }
    override var toolbarItemImage: NSImage {
        NSImage(systemSymbolName: "arrow.up.circle", accessibilityDescription: "Dropline")
            ?? NSImage(size: NSSize(width: 1, height: 1))
    }

    // MARK: 右键菜单

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        // 只在选中文件/文件夹、或在文件夹空白处右键时提供
        switch menuKind {
        case .contextualMenuForItems, .contextualMenuForContainer, .toolbarItemMenu:
            break
        default:
            return nil
        }
        let menu = NSMenu(title: "")
        let item = NSMenuItem(title: "使用 Dropline 上传",
                              action: #selector(uploadSelection(_:)),
                              keyEquivalent: "")
        item.target = self
        item.image = NSImage(systemSymbolName: "arrow.up.circle", accessibilityDescription: nil)
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
            NSWorkspace.shared.open(url)
        }
    }
}
