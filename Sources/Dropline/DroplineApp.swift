import SwiftUI
import AppKit

@main
struct DroplineApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var state = AppState.shared
    @StateObject private var updater = UpdaterModel()

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environmentObject(state)
        }
        .defaultSize(width: 620, height: 620)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("检查更新…") { updater.checkForUpdates() }
                    .disabled(!updater.canCheck)
            }
            CommandGroup(replacing: .newItem) {
                Button("上传文件…") { state.pickFiles() }
                    .keyboardShortcut("o", modifiers: .command)
            }
            CommandGroup(after: .pasteboard) {
                Button("复制最近链接") {
                    if let last = state.history.first {
                        state.copy(text: state.formatted(url: last.url, filename: last.filename))
                        state.lastMessage = "已复制链接"
                    }
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .disabled(state.history.isEmpty)
            }
        }

        Settings {
            SettingsView()
                .environmentObject(state)
                .environmentObject(updater)
        }

        // 系统托盘（菜单栏）
        MenuBarExtra("Dropline", systemImage: "arrow.up.circle") {
            MenuBarContent()
                .environmentObject(state)
                .environmentObject(updater)
        }
    }
}

// MARK: - 托盘菜单

struct MenuBarContent: View {
    @EnvironmentObject var state: AppState
    @EnvironmentObject var updater: UpdaterModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("选择文件上传…") { state.pickFiles() }
            .keyboardShortcut("o", modifiers: [.command, .shift])

        Button("上传剪贴板中的文件") {
            let pb = NSPasteboard.general
            if let urls = pb.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
                let files = urls.filter { $0.isFileURL }
                if !files.isEmpty { state.enqueue(files); return }
            }
            state.lastMessage = "剪贴板里没有文件"
            NSSound.beep()
        }

        if !state.items.isEmpty {
            Divider()
            let active = state.items.filter { !$0.isFinished }.count
            Text(active > 0 ? "正在上传 \(active) 个文件…" : "队列已全部完成")
        }

        if !state.history.isEmpty {
            Divider()
            Text("最近上传")
            ForEach(state.history.prefix(8)) { rec in
                Button(rec.filename) {
                    state.copy(text: state.formatted(url: rec.url, filename: rec.filename))
                    state.lastMessage = "已复制链接"
                }
            }
        }

        Divider()
        Button("打开主窗口") {
            if !AppDelegate.showMainWindow() {
                openWindow(id: "main")
            }
        }
        if #available(macOS 14, *) {
            SettingsLink { Text("设置…") }
                .keyboardShortcut(",", modifiers: .command)
        } else {
            Button("设置…") { state.openSettings() }
                .keyboardShortcut(",", modifiers: .command)
        }
        Button("检查更新…") { updater.checkForUpdates() }
            .disabled(!updater.canCheck)
        Divider()
        Button("退出 Dropline") { NSApp.terminate(nil) }
            .keyboardShortcut("q", modifiers: .command)
    }
}

// MARK: - AppDelegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let serviceProvider = ServiceProvider()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 注册 Finder 右键「服务」
        NSApp.servicesProvider = serviceProvider
        NSUpdateDynamicServices()

        if AppState.shared.hideDockIcon {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    /// 拖到 Dock 图标上传
    func application(_ application: NSApplication, open urls: [URL]) {
        Task { @MainActor in
            AppState.shared.enqueue(urls.filter { $0.isFileURL })
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false   // 关窗后仍驻留菜单栏
    }

    /// 点 Dock 图标 / 再次 open 时把主窗口找回来。
    /// 否则关掉主窗口后 App 只剩菜单栏，看起来像「卡死点不动」。
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { AppDelegate.showMainWindow() }
        return true
    }

    /// 复用已存在的主窗口；SwiftUI 只是把它 order out，NSWindow 还在。
    @MainActor
    @discardableResult
    static func showMainWindow() -> Bool {
        NSApp.setActivationPolicy(AppState.shared.hideDockIcon ? .accessory : .regular)
        NSApp.activate(ignoringOtherApps: true)
        let candidates = NSApp.windows.filter { $0.canBecomeMain && !($0 is NSPanel) }
        let preferred = candidates.first { $0.identifier?.rawValue.contains("main") == true }
        guard let window = preferred ?? candidates.first else { return false }
        window.makeKeyAndOrderFront(nil)
        return true
    }
}
