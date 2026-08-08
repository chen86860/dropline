import AppKit
import SwiftUI

/// 主窗口由 AppKit 自己管，**不放进 SwiftUI 的 scene 树**。
///
/// 原因：`WindowGroup` 必定在进程启动时创建并摆出主窗口，时机还不受控。
/// 而 Finder 右键 / 服务菜单 / 拖到 Dock 这些后台上传只需要菜单栏的进度环，
/// 不该把窗口顶到前台 —— 从前的做法是先让 SwiftUI 弹出来、再抢着 orderOut，
/// 会闪一下，抢不过时还会整个窗口留在屏幕上。
///
/// 改成这样之后窗口只在 `show()` 被调用时才存在，后台上传路径上根本不碰它。
@MainActor
final class MainWindowController {
    static let shared = MainWindowController()

    private var window: NSWindow?

    private init() {}

    /// 显示（必要时创建）主窗口。仅由用户主动的入口调用：
    /// 正常启动、点 Dock 图标、菜单栏「打开主窗口」。
    func show() {
        let window = self.window ?? makeWindow()
        NSApp.setActivationPolicy(AppState.shared.hideDockIcon ? .accessory : .regular)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Dropline"
        window.contentView = NSHostingView(
            rootView: ContentView().environmentObject(AppState.shared)
        )
        // 关窗后 NSWindow 留着复用，下次 show() 能原样找回来（App 本身驻留菜单栏）
        window.isReleasedWhenClosed = false
        window.center()
        window.setFrameAutosaveName("DroplineMainWindow")
        self.window = window
        return window
    }
}
