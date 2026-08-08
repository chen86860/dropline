import Foundation

/// 访达右键菜单的展示方式。
///
/// 扩展是沙盒进程，读不到主 App 的 UserDefaults；反过来主 App 未沙盒化，
/// 可以往扩展自己的容器里写文件。于是用容器内的两个小文件作为配置通道
/// （展示方式 + 界面语言），扩展每次弹菜单时读一次，改完立即生效、无需重启访达。
enum FinderMenuMode: String, CaseIterable, Identifiable, Codable {
    case icon       // 显示，带图标
    case text       // 显示，不带图标
    case hidden     // 不显示

    var id: String { rawValue }

    /// 选择器里的选项文案
    var label: String {
        switch self {
        case .icon:   return "Show (with icon)".t
        case .text:   return "Show (without icon)".t
        case .hidden: return "Don’t show".t
        }
    }

    /// 选中后显示在选择器下方的一句话说明
    var detail: String {
        switch self {
        case .icon:
            return "Shows “Upload with Dropline” at the top of the context menu, with an upload icon.".t
        case .text:
            return "Shows “Upload with Dropline” at the top of the context menu, without an icon, matching system items.".t
        case .hidden:
            return "Dropline stays out of the context menu. Drag & drop, the clipboard, the menu bar and the Services menu item all keep working.".t
        }
    }

    static let `default` = FinderMenuMode.icon

    // MARK: - 共享配置文件

    static let extensionBundleID = "dev.emmmm.Dropline.Finder"

    /// 扩展容器内的相对目录，两端必须一致
    static let relativeDirectory = "Library/Application Support/Dropline"
    static let modeFileName = "finder-menu.txt"
    static let languageFileName = "finder-language.txt"

    /// 主 App 侧：扩展容器里的绝对目录
    static var sharedDirectoryURL: URL? {
        let containerData = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Containers/\(extensionBundleID)/Data")
        // 容器要等扩展首次运行才会由系统创建；还不存在就先不写
        guard FileManager.default.fileExists(atPath: containerData.path) else { return nil }
        return containerData.appendingPathComponent(relativeDirectory)
    }

    /// 主 App 侧：把当前选择同步给扩展。
    /// 语言写的是**解析后**的结果（en / zh），扩展不必再去猜「跟随系统」是什么。
    static func writeShared(mode: FinderMenuMode, language: L10n.Resolved) {
        guard let dir = sharedDirectoryURL else { return }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? mode.rawValue.write(to: dir.appendingPathComponent(modeFileName),
                                 atomically: true, encoding: .utf8)
        try? (language == .zh ? "zh" : "en").write(to: dir.appendingPathComponent(languageFileName),
                                                   atomically: true, encoding: .utf8)
    }
}
