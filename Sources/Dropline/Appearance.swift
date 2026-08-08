import AppKit

/// 界面外观（浅色 / 深色）。默认跟随系统。
///
/// 手动指定时只覆盖 Dropline 自己：设在 `NSApplication.appearance` 上，
/// 主窗口、设置窗口和菜单栏弹出的菜单会一起跟着变，系统其它 App 不受影响。
/// 菜单栏那个图标是模板图（`isTemplate = true`），永远跟随菜单栏本身的明暗自动反色，
/// 不受这里影响 —— 这也是对的：深色菜单栏配白图标，与旁边的系统图标才一致。
enum AppAppearance: String, CaseIterable, Identifiable, Codable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "Follow System".t
        case .light:  return "Light".t
        case .dark:   return "Dark".t
        }
    }

    /// nil = 交还给系统（跟随系统设置，含系统里「自动」那档的日夜切换）
    var nsAppearance: NSAppearance? {
        switch self {
        case .system: return nil
        case .light:  return NSAppearance(named: .aqua)
        case .dark:   return NSAppearance(named: .darkAqua)
        }
    }

    /// 用 NSApplication.shared 而不是 NSApp：这会在 AppState 初始化那么早的时机
    /// 被调用，走 .shared 能保证实例已经建好。
    @MainActor
    func apply() {
        NSApplication.shared.appearance = nsAppearance
    }
}
