import Foundation
import Combine
import Sparkle

/// Sparkle 自动更新的薄封装，供 SwiftUI 直接绑定。
@MainActor
final class UpdaterModel: ObservableObject {
    private let controller: SPUStandardUpdaterController

    /// Sparkle 忙于检查/下载时为 false，用来禁用「检查更新」按钮
    @Published private(set) var canCheck = false
    @Published private(set) var lastCheck: Date?

    @Published var automaticallyChecks: Bool {
        didSet { controller.updater.automaticallyChecksForUpdates = automaticallyChecks }
    }

    @Published var automaticallyDownloads: Bool {
        didSet { controller.updater.automaticallyDownloadsUpdates = automaticallyDownloads }
    }

    init() {
        controller = SPUStandardUpdaterController(startingUpdater: true,
                                                  updaterDelegate: nil,
                                                  userDriverDelegate: nil)
        automaticallyChecks = controller.updater.automaticallyChecksForUpdates
        automaticallyDownloads = controller.updater.automaticallyDownloadsUpdates
        lastCheck = controller.updater.lastUpdateCheckDate
        controller.updater.publisher(for: \.canCheckForUpdates).assign(to: &$canCheck)
    }

    func checkForUpdates() {
        controller.updater.checkForUpdates()
        lastCheck = controller.updater.lastUpdateCheckDate ?? Date()
    }

    var feedURL: String {
        Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String ?? "(未配置)"
    }

    var versionString: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return v == b ? v : "\(v) (\(b))"
    }
}
