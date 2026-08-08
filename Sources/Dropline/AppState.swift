import Foundation
import AppKit
import SwiftUI

// MARK: - 队列项

struct UploadItem: Identifiable {
    enum Status: Equatable {
        case waiting, uploading, done(String), failed(String)
    }
    let id = UUID()
    let fileURL: URL
    var byteCount: Int64
    var progress: Double = 0
    var status: Status = .waiting

    var isFinished: Bool {
        if case .done = status { return true }
        if case .failed = status { return true }
        return false
    }
}

// MARK: - 全局状态

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var profiles: [UploaderProfile] = []
    @Published var activeProfileID: UUID?
    @Published var items: [UploadItem] = []
    @Published var history: [UploadRecord] = []
    @Published var lastMessage: String = ""

    @Published var autoCopyURL: Bool = true {
        didSet { UserDefaults.standard.set(autoCopyURL, forKey: "autoCopyURL") }
    }
    @Published var markdownCopy: Bool = false {
        didSet { UserDefaults.standard.set(markdownCopy, forKey: "markdownCopy") }
    }
    @Published var hideDockIcon: Bool = false {
        didSet {
            UserDefaults.standard.set(hideDockIcon, forKey: "hideDockIcon")
            NSApplication.shared.setActivationPolicy(hideDockIcon ? .accessory : .regular)
        }
    }
    @Published var maxConcurrent: Int = 3 {
        didSet { UserDefaults.standard.set(maxConcurrent, forKey: "maxConcurrent") }
    }
    @Published var notifyOnFinish: Bool = true {
        didSet { UserDefaults.standard.set(notifyOnFinish, forKey: "notifyOnFinish") }
    }
    @Published var finderMenuMode: FinderMenuMode = .default {
        didSet {
            UserDefaults.standard.set(finderMenuMode.rawValue, forKey: "finderMenuMode")
            syncFinderExtension()
        }
    }
    /// 界面外观。改动后立刻作用于所有窗口，无需重启。
    @Published var appearance: AppAppearance = .system {
        didSet {
            UserDefaults.standard.set(appearance.rawValue, forKey: "appearance")
            appearance.apply()
        }
    }
    /// 界面语言。改动后要立刻同步给 L10n（界面靠 @Published 重绘）和访达扩展。
    @Published var language: AppLanguage = .system {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "language")
            L10n.language = language
            syncPreferredLanguages()
            syncFinderExtension()
        }
    }

    private func syncFinderExtension() {
        FinderMenuMode.writeShared(mode: finderMenuMode, language: L10n.resolved)
    }

    /// Sparkle 的更新说明是 appcast 里若干条带 xml:lang 的 <description>，它用
    /// NSBundle.preferredLocalizationsFromArray: 挑一条 —— 读的是 AppleLanguages。
    /// 所以要把界面语言写进去，更新弹窗才会跟着 App 内的选择走，而不是只看系统语言。
    ///
    /// 注意：CFBundle 的语言列表在进程启动时就定下来了，写完**下次启动**才生效。
    /// 也就是说刚切完语言就去查更新，那一次弹窗仍是上一个语言。
    private func syncPreferredLanguages() {
        let d = UserDefaults.standard
        switch language {
        case .system:  d.removeObject(forKey: "AppleLanguages")   // 交还给系统列表
        case .english: d.set(["en"], forKey: "AppleLanguages")
        case .chinese: d.set(["zh-Hans", "en"], forKey: "AppleLanguages")
        }
    }

    /// 菜单栏进度：nil 表示空闲；否则是所有未完成任务的平均进度
    var trayProgress: Double? {
        let pending = items.filter { !$0.isFinished }
        guard !pending.isEmpty else { return nil }
        return pending.reduce(0) { $0 + $1.progress } / Double(pending.count)
    }

    var pendingCount: Int { items.filter { !$0.isFinished }.count }

    private let profilesKey = "profiles.v1"
    private let activeKey = "activeProfile.v1"
    private let historyKey = "history.v1"
    private var running = 0

    private init() {
        load()
    }

    var activeProfile: UploaderProfile? {
        profiles.first { $0.id == activeProfileID } ?? profiles.first
    }

    // MARK: 持久化

    private func load() {
        let d = UserDefaults.standard
        if let data = d.data(forKey: profilesKey),
           let decoded = try? JSONDecoder().decode([UploaderProfile].self, from: data) {
            profiles = decoded
        } else {
            profiles = [ProfilePresets.blankHTTP]
        }
        if let s = d.string(forKey: activeKey), let uuid = UUID(uuidString: s) {
            activeProfileID = uuid
        }
        if activeProfileID == nil { activeProfileID = profiles.first?.id }
        if let data = d.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([UploadRecord].self, from: data) {
            history = decoded
        }
        // 偏好项（首次运行取默认值：自动复制链接开启）
        autoCopyURL = d.object(forKey: "autoCopyURL") as? Bool ?? true
        markdownCopy = d.bool(forKey: "markdownCopy")
        hideDockIcon = d.bool(forKey: "hideDockIcon")
        maxConcurrent = d.object(forKey: "maxConcurrent") as? Int ?? 3
        notifyOnFinish = d.object(forKey: "notifyOnFinish") as? Bool ?? true
        finderMenuMode = (d.string(forKey: "finderMenuMode").flatMap(FinderMenuMode.init(rawValue:)))
            ?? .default
        // 赋值必然触发 didSet，外观在这里就已经应用上了（首个窗口还没创建，不会闪）
        appearance = (d.string(forKey: "appearance").flatMap(AppAppearance.init(rawValue:))) ?? .system
        // 语言要在其它文案被读到之前先定下来
        language = (d.string(forKey: "language").flatMap(AppLanguage.init(rawValue:))) ?? .system
        L10n.language = language
        syncPreferredLanguages()
        // 启动时同步一次：扩展容器可能刚被系统创建，或被用户清理过
        syncFinderExtension()
    }

    func saveProfiles() {
        let d = UserDefaults.standard
        if let data = try? JSONEncoder().encode(profiles) { d.set(data, forKey: profilesKey) }
        d.set(activeProfileID?.uuidString, forKey: activeKey)
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }

    func clearHistory() {
        history = []
        saveHistory()
    }

    // MARK: 配置增删

    func addProfile(_ p: UploaderProfile) {
        var new = p
        new.id = UUID()
        profiles.append(new)
        activeProfileID = new.id
        saveProfiles()
    }

    func deleteProfile(_ id: UUID) {
        Keychain.delete(account: Keychain.secretAccount(for: id))
        profiles.removeAll { $0.id == id }
        if activeProfileID == id { activeProfileID = profiles.first?.id }
        saveProfiles()
    }

    // MARK: 上传

    func enqueue(_ urls: [URL]) {
        guard activeProfile != nil else {
            lastMessage = "Add an upload profile in Settings first".t
            NSSound.beep()
            openSettings()
            return
        }
        let expanded = urls.flatMap { expand($0) }
        guard !expanded.isEmpty else { return }
        for url in expanded {
            let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)??.int64Value ?? 0
            items.insert(UploadItem(fileURL: url, byteCount: size), at: 0)
        }
        pump()
    }

    /// 目录展开为其中的文件（一层递归）。
    private func expand(_ url: URL) -> [URL] {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) else { return [] }
        guard isDir.boolValue else { return [url] }
        let children = (try? FileManager.default.contentsOfDirectory(
            at: url, includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles, .skipsPackageDescendants])) ?? []
        return children.flatMap { expand($0) }
    }

    private func pump() {
        guard let profile = activeProfile else { return }
        while running < max(1, maxConcurrent),
              let idx = items.lastIndex(where: { if case .waiting = $0.status { return true }; return false }) {
            running += 1
            items[idx].status = .uploading
            let item = items[idx]
            Task { await self.run(item: item, profile: profile) }
        }
    }

    private func run(item: UploadItem, profile: UploaderProfile) async {
        let id = item.id
        do {
            let url = try await UploadService.upload(fileURL: item.fileURL, profile: profile) { p in
                Task { @MainActor in AppState.shared.updateProgress(id: id, p) }
            }
            finish(id: id, result: .success(url), item: item, profile: profile)
        } catch {
            finish(id: id, result: .failure(error), item: item, profile: profile)
        }
    }

    func updateProgress(id: UUID, _ p: Double) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        items[i].progress = p
    }

    private func finish(id: UUID, result: Result<String, Error>, item: UploadItem, profile: UploaderProfile) {
        running = max(0, running - 1)
        if let i = items.firstIndex(where: { $0.id == id }) {
            switch result {
            case .success(let url):
                items[i].status = .done(url)
                items[i].progress = 1
            case .failure(let err):
                items[i].status = .failed(err.localizedDescription)
            }
        }
        if case .success(let url) = result {
            history.insert(UploadRecord(filename: item.fileURL.lastPathComponent,
                                        url: url,
                                        profileName: profile.name,
                                        date: Date(),
                                        byteCount: item.byteCount), at: 0)
            if history.count > 300 { history.removeLast(history.count - 300) }
            saveHistory()
            if autoCopyURL { copy(text: formatted(url: url, filename: item.fileURL.lastPathComponent)) }
            lastMessage = autoCopyURL
                ? "Uploaded %@, link copied".t(item.fileURL.lastPathComponent)
                : "Uploaded %@".t(item.fileURL.lastPathComponent)
            if notifyOnFinish {
                Notifier.shared.uploadSucceeded(filename: item.fileURL.lastPathComponent, url: url)
            }
        } else if case .failure(let err) = result {
            lastMessage = "Upload failed: %@".t(err.localizedDescription)
            NSSound.beep()
            if notifyOnFinish {
                Notifier.shared.uploadFailed(filename: item.fileURL.lastPathComponent,
                                             reason: err.localizedDescription)
            }
        }
        pump()
    }

    func formatted(url: String, filename: String) -> String {
        markdownCopy ? "![\(filename)](\(url))" : url
    }

    func copy(text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }

    func clearFinished() {
        items.removeAll { $0.isFinished }
    }

    func remove(_ id: UUID) {
        items.removeAll { $0.id == id }
    }

    // MARK: 面板

    func pickFiles() {
        NSApp.activate(ignoringOtherApps: true)
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.message = "Choose images, videos, or any file to upload".t
        panel.prompt = "Upload".t
        if panel.runModal() == .OK {
            enqueue(panel.urls)
        }
    }

    /// 打开设置窗口。
    /// `showSettingsWindow:` 在较新的 macOS 上已不可靠，这里加上「点击应用菜单里的设置项」兜底。
    func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        for name in ["showSettingsWindow:", "showPreferencesWindow:"] {
            if NSApp.sendAction(Selector((name)), to: nil, from: nil) { return }
        }
        if let appMenu = NSApp.mainMenu?.item(at: 0)?.submenu {
            for item in appMenu.items {
                let t = item.title
                let isSettings = t.hasPrefix("Settings") || t.hasPrefix("Preferences")
                    || t.contains("设置") || t.contains("偏好") || t.contains("Settings")
                if isSettings, let action = item.action {
                    NSApp.sendAction(action, to: item.target, from: item)
                    return
                }
            }
        }
        lastMessage = "Open Settings from the menu bar: Dropline → Settings… (⌘,)".t
    }
}

extension Int64 {
    var humanSize: String {
        ByteCountFormatter.string(fromByteCount: self, countStyle: .file)
    }
}
