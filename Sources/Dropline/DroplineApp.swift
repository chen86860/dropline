import SwiftUI
import AppKit

@main
struct DroplineApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var state = AppState.shared
    @StateObject private var updater = UpdaterModel()

    // 主窗口不在这里 —— 见 MainWindowController。scene 树里只留菜单栏与设置，
    // 这样进程启动（含被 Finder 扩展的 dropline:// 唤起）时不会有任何窗口被创建。
    var body: some Scene {
        // 系统托盘（菜单栏）：上传中显示进度环
        MenuBarExtra {
            MenuBarContent()
                .environmentObject(state)
                .environmentObject(updater)
        } label: {
            Image(nsImage: TrayIcon.image(progress: state.trayProgress))
        }
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…".t) { updater.checkForUpdates() }
                    .disabled(!updater.canCheck)
            }
            CommandGroup(replacing: .newItem) {
                Button("Upload Files…".t) { state.pickFiles() }
                    .keyboardShortcut("o", modifiers: .command)
            }
            CommandGroup(after: .pasteboard) {
                Button("Copy Latest Link".t) {
                    if let last = state.history.first {
                        state.copy(text: state.formatted(url: last.url, filename: last.filename))
                        state.lastMessage = "Link copied".t
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
    }
}

// MARK: - 托盘菜单

struct MenuBarContent: View {
    @EnvironmentObject var state: AppState
    @EnvironmentObject var updater: UpdaterModel

    var body: some View {
        Button("Choose Files to Upload…".t) { state.pickFiles() }
            .keyboardShortcut("o", modifiers: [.command, .shift])

        Button("Upload File in Clipboard".t) {
            let pb = NSPasteboard.general
            if let urls = pb.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
                let files = urls.filter { $0.isFileURL }
                if !files.isEmpty { state.enqueue(files); return }
            }
            state.lastMessage = "No file in the clipboard".t
            NSSound.beep()
        }

        if !state.profiles.isEmpty {
            Divider()
            Picker("Host".t, selection: Binding(
                get: { state.activeProfile?.id ?? UUID() },
                set: { state.activeProfileID = $0; state.saveProfiles() }
            )) {
                ForEach(state.profiles) { Text($0.name).tag($0.id) }
            }
        }

        if !state.items.isEmpty {
            Divider()
            let active = state.items.filter { !$0.isFinished }.count
            Text(active > 0 ? "Uploading %d file(s)…".t(active) : "All uploads finished".t)
        }

        if !state.history.isEmpty {
            Divider()
            Text("Recent Uploads".t)
            ForEach(state.history.prefix(5)) { rec in
                Button(rec.filename) {
                    state.copy(text: state.formatted(url: rec.url, filename: rec.filename))
                    state.lastMessage = "Link copied".t
                }
            }
        }

        Divider()
        Button("Open Main Window".t) { MainWindowController.shared.show() }
        if #available(macOS 14, *) {
            SettingsLink { Text("Settings…".t) }
                .keyboardShortcut(",", modifiers: .command)
        } else {
            Button("Settings…".t) { state.openSettings() }
                .keyboardShortcut(",", modifiers: .command)
        }
        Button("Check for Updates…".t) { updater.checkForUpdates() }
            .disabled(!updater.canCheck)
        Divider()
        Button("Quit Dropline".t) { NSApp.terminate(nil) }
            .keyboardShortcut("q", modifiers: .command)
    }
}

// MARK: - AppDelegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let serviceProvider = ServiceProvider()

    /// 最近一次后台上传请求的时间。用来在「刚启动」和「刚被 reopen」这两个瞬间
    /// 判断这次事件是用户想要窗口，还是 Finder 扩展 / 服务菜单在悄悄递文件进来。
    private static var lastUploadRequest = Date.distantPast

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 注册 Finder 右键「服务」
        NSApp.servicesProvider = serviceProvider
        NSUpdateDynamicServices()

        Notifier.shared.start()

        if AppState.shared.hideDockIcon {
            NSApp.setActivationPolicy(.accessory)
        }

        maybeShowWindowAfterLaunch()
    }

    /// 正常启动（用户双击 App）要摆出主窗口；被 dropline:// 或文件唤起的那次启动不要。
    ///
    /// 先看启动事件本身：`kAEOpenApplication` 之外的（GetURL / odoc）一律不开窗。
    /// 万一系统仍报成普通启动，再用「短暂延迟 + 上传请求到了就作罢」兜一层——
    /// URL 事件通常紧跟在 didFinishLaunching 之后到达。
    private func maybeShowWindowAfterLaunch() {
        let launchEvent = NSAppleEventManager.shared().currentAppleEvent?.eventID
        guard launchEvent == nil || launchEvent == AEEventID(kAEOpenApplication) else { return }

        let launchedAt = Date()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            guard Self.lastUploadRequest < launchedAt else { return }
            MainWindowController.shared.show()
        }
    }

    /// 拖到 Dock 图标上传；也接收 Finder 扩展发来的 dropline://upload?list=…
    func application(_ application: NSApplication, open urls: [URL]) {
        var files = urls.filter { $0.isFileURL }
        for url in urls where url.scheme == "dropline" {
            files += Self.filesFromListURL(url)
        }
        Task { @MainActor in
            // 先记账再看有没有文件：清单里的文件恰好都不在了（被移动/删除）也算一次
            // 后台请求，否则紧随其后的 reopen 会误判成「用户要窗口」而弹窗。
            Self.noteBackgroundUpload()
            guard !files.isEmpty else { return }
            AppState.shared.enqueue(files)
        }
    }

    /// 后台触发的上传（Finder 右键 / 服务 / 拖到 Dock）不抢前台：
    /// 进度看菜单栏图标的进度环就够了。主窗口不在 scene 树里，这里无需再去收窗口，
    /// 只记一个时间戳给启动 / reopen 两处判断用。
    @MainActor
    static func noteBackgroundUpload() {
        lastUploadRequest = Date()
    }

    /// 读取扩展写下的路径清单，读完即删
    private static func filesFromListURL(_ url: URL) -> [URL] {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let path = comps.queryItems?.first(where: { $0.name == "list" })?.value,
              let content = try? String(contentsOfFile: path, encoding: .utf8)
        else { return [] }
        try? FileManager.default.removeItem(atPath: path)
        return content
            .split(separator: "\n")
            .map { URL(fileURLWithPath: String($0)) }
            .filter { FileManager.default.fileExists(atPath: $0.path) }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false   // 关窗后仍驻留菜单栏
    }

    /// 点 Dock 图标 / 再次 open 时把主窗口找回来。
    /// 否则关掉主窗口后 App 只剩菜单栏，看起来像「卡死点不动」。
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard !flag else { return true }
        // Finder 扩展那句 NSWorkspace.open 也会走到这里，而承载文件清单的 URL 事件
        // 可能比 reopen 稍晚一点到。推迟一下再决定：这期间收到上传请求就不开窗。
        let reopenedAt = Date()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            guard Self.lastUploadRequest < reopenedAt else { return }
            MainWindowController.shared.show()
        }
        return true
    }
}
