import AppKit
import UserNotifications

/// 上传结果的系统通知。点通知或点「复制链接」都会把 URL 放进剪贴板。
@MainActor
final class Notifier: NSObject, UNUserNotificationCenterDelegate {
    static let shared = Notifier()

    private let categoryID = "dropline.upload"
    private let copyActionID = "dropline.copy"
    private var authorized = false

    /// 未打包运行（比如直接跑二进制）时 UNUserNotificationCenter 不可用
    private var available: Bool { Bundle.main.bundleIdentifier != nil }

    func start() {
        guard available else { return }
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        let copy = UNNotificationAction(identifier: copyActionID, title: "Copy Link".t, options: [])
        center.setNotificationCategories([
            UNNotificationCategory(identifier: categoryID, actions: [copy],
                                   intentIdentifiers: [], options: [])
        ])
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            Task { @MainActor in self.authorized = granted }
        }
    }

    func uploadSucceeded(filename: String, url: String) {
        post(title: "Upload finished".t,
             body: filename,
             subtitle: url,
             userInfo: ["url": url])
    }

    func uploadFailed(filename: String, reason: String) {
        post(title: "Upload failed".t, body: filename, subtitle: reason, userInfo: [:])
    }

    private func post(title: String, body: String, subtitle: String, userInfo: [String: Any]) {
        guard available, authorized else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        content.body = body
        content.sound = .default
        content.categoryIdentifier = categoryID
        content.userInfo = userInfo
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// App 在前台时也要显示横幅
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification,
                                            withCompletionHandler handler: @escaping (UNNotificationPresentationOptions) -> Void) {
        handler([.banner, .sound])
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse,
                                            withCompletionHandler handler: @escaping () -> Void) {
        let url = response.notification.request.content.userInfo["url"] as? String
        Task { @MainActor in
            if let url, !url.isEmpty {
                let pb = NSPasteboard.general
                pb.clearContents()
                pb.setString(url, forType: .string)
                AppState.shared.lastMessage = "Link copied".t
            }
            handler()
        }
    }
}
