import AppKit

/// Finder 右键 →「服务」→「使用 Dropline 上传」。
/// 在 Info.plist 的 NSServices 中以 NSMessage = uploadFromService 注册。
final class ServiceProvider: NSObject {

    @objc func uploadFromService(_ pboard: NSPasteboard,
                                 userData: String?,
                                 error: AutoreleasingUnsafeMutablePointer<NSString>) {
        var urls: [URL] = []

        if let objects = pboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            urls = objects.filter { $0.isFileURL }
        }
        if urls.isEmpty,
           let paths = pboard.propertyList(forType: .init("NSFilenamesPboardType")) as? [String] {
            urls = paths.map { URL(fileURLWithPath: $0) }
        }

        guard !urls.isEmpty else {
            error.pointee = "没有可上传的文件" as NSString
            return
        }

        Task { @MainActor in
            AppState.shared.enqueue(urls)
            if !AppState.shared.hideDockIcon {
                AppDelegate.showMainWindow()
            }
        }
    }
}
