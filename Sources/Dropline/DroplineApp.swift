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

        // 系统托盘（菜单栏）：上传中显示进度环
        MenuBarExtra {
            MenuBarContent()
                .environmentObject(state)
                .environmentObject(updater)
        } label: {
            Image(nsImage: TrayIcon.image(progress: state.trayProgress))
        }
    }
}

// MARK: - 托盘菜单

struct MenuBarContent: View {
    @EnvironmentObject var state: AppState
    @EnvironmentObject var updater: UpdaterModel
    @Environment(\.openWindow) private var openWindow

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
        Button("Open Main Window".t) {
            if !AppDelegate.showMainWindow() {
                openWindow(id: "main")
            }
        }
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

    /// 最近一次后台上传请求 / 用户主动要窗口的时间，用来判断「这个窗口是谁要的」
    private static var lastUploadRequest = Date.distantPast
    private static var lastWindowRequest = Date.distantPast
    private static var launchTime = Date.distantPast
    /// 抑制期内的窗口观察器，见 suppressMainWindow()
    private static var windowWatcher: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.launchTime = Date()

        // 注册 Finder 右键「服务」
        NSApp.servicesProvider = serviceProvider
        NSUpdateDynamicServices()

        Notifier.shared.start()

        if AppState.shared.hideDockIcon {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    /// 拖到 Dock 图标上传；也接收 Finder 扩展发来的 dropline://upload?list=…
    func application(_ application: NSApplication, open urls: [URL]) {
        var files = urls.filter { $0.isFileURL }
        for url in urls where url.scheme == "dropline" {
            files += Self.filesFromListURL(url)
        }
        guard !files.isEmpty else { return }
        Task { @MainActor in
            Self.uploadRequestedInBackground()
            AppState.shared.enqueue(files)
        }
    }

    /// 后台触发的上传（Finder 右键 / 服务 / 拖到 Dock）不抢前台：进度看菜单栏图标的进度环就够了。
    ///
    /// 难点在于「主窗口不是我们打开的」，有两条路都会把它摆出来，而且都绕不过去：
    /// 一是冷启动 —— SwiftUI 的 WindowGroup 必定在启动时创建并显示主窗口，时机还不保证；
    /// 二是 NSWorkspace.open 顺带触发的 reopen —— 它和用户点 Dock 图标是同一个事件，分不出来。
    /// 所以不去猜窗口是谁开的，只认一条规则：**上传请求到达时没开着的主窗口，接下来几秒也不该冒出来**。
    @MainActor
    static func uploadRequestedInBackground() {
        lastUploadRequest = Date()

        // 用户本来就开着主窗口的话别去动它。例外是冷启动：刚启动那几秒里「已经开着」的
        // 主窗口是 SwiftUI 自己摆出来的，恰恰是要收掉的那个。
        let isLaunching = Date().timeIntervalSince(launchTime) < 3
        guard isLaunching || !mainWindows.contains(where: \.isVisible) else { return }
        suppressMainWindow()
    }

    /// 收起主窗口，并在随后几秒里盯着：它一出现就再收一次。
    /// 窗口只是 orderOut，NSWindow 还在，之后「打开主窗口」能原样找回来。
    @MainActor
    private static func suppressMainWindow() {
        orderOutMainWindows()
        guard windowWatcher == nil else { return }

        windowWatcher = NotificationCenter.default.addObserver(
            forName: NSWindow.didUpdateNotification, object: nil, queue: .main
        ) { _ in
            Task { @MainActor in orderOutMainWindows() }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if let watcher = windowWatcher {
                NotificationCenter.default.removeObserver(watcher)
                windowWatcher = nil
            }
        }
    }

    @MainActor
    private static func orderOutMainWindows() {
        // 抑制期内用户主动要了窗口（点 Dock、菜单栏「打开主窗口」）就让位
        guard lastWindowRequest < lastUploadRequest else { return }
        for window in mainWindows where window.isVisible {
            window.orderOut(nil)
        }
    }

    /// 主窗口候选：排除设置窗口、面板，以及菜单栏那种不能成为主窗口的窗口。
    /// 没配置图床时 enqueue 会打开设置窗口，那个必须留着。
    @MainActor
    private static var mainWindows: [NSWindow] {
        NSApp.windows.filter {
            $0.canBecomeMain && !($0 is NSPanel)
                && $0.identifier?.rawValue.localizedCaseInsensitiveContains("settings") != true
        }
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
        // 可能比 reopen 稍晚一点到。推迟一下再决定：这期间收到上传请求就不开窗，
        // 免得窗口先弹出来再被收回去闪一下。
        let reopenedAt = Date()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            guard Self.lastUploadRequest < reopenedAt else { return }
            AppDelegate.showMainWindow()
        }
        return true
    }

    /// 复用已存在的主窗口；SwiftUI 只是把它 order out，NSWindow 还在。
    @MainActor
    @discardableResult
    static func showMainWindow() -> Bool {
        lastWindowRequest = Date()
        NSApp.setActivationPolicy(AppState.shared.hideDockIcon ? .accessory : .regular)
        NSApp.activate(ignoringOtherApps: true)
        let candidates = NSApp.windows.filter { $0.canBecomeMain && !($0 is NSPanel) }
        let preferred = candidates.first { $0.identifier?.rawValue.contains("main") == true }
        guard let window = preferred ?? candidates.first else { return false }
        window.makeKeyAndOrderFront(nil)
        return true
    }
}
