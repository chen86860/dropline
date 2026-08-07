import Foundation

/// 访达右键菜单的展示方式。
///
/// 扩展是沙盒进程，读不到主 App 的 UserDefaults；反过来主 App 未沙盒化，
/// 可以往扩展自己的容器里写文件。于是用容器内的一个小文件作为配置通道，
/// 扩展每次弹菜单时读一次，改完立即生效、无需重启访达。
enum FinderMenuMode: String, CaseIterable, Identifiable, Codable {
    case icon       // 显示，带图标
    case text       // 显示，不带图标
    case hidden     // 不显示

    var id: String { rawValue }

    var label: String {
        switch self {
        case .icon:   return "显示（带图标）"
        case .text:   return "显示（纯文字）"
        case .hidden: return "不显示"
        }
    }

    static let `default` = FinderMenuMode.icon

    // MARK: - 共享配置文件

    static let extensionBundleID = "dev.emmmm.Dropline.Finder"

    /// 扩展容器内的相对路径，两端必须一致
    static let relativePath = "Library/Application Support/Dropline/finder-menu.txt"

    /// 主 App 侧：扩展容器里的绝对路径
    static var sharedFileURL: URL? {
        let containerData = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Containers/\(extensionBundleID)/Data")
        // 容器要等扩展首次运行才会由系统创建；还不存在就先不写
        guard FileManager.default.fileExists(atPath: containerData.path) else { return nil }
        return containerData.appendingPathComponent(relativePath)
    }

    /// 主 App 侧：把当前选择同步给扩展
    static func writeShared(_ mode: FinderMenuMode) {
        guard let url = sharedFileURL else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                 withIntermediateDirectories: true)
        try? mode.rawValue.write(to: url, atomically: true, encoding: .utf8)
    }
}
