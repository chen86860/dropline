import SwiftUI
import UniformTypeIdentifiers

// MARK: - 文件类型

/// 按扩展名认文件类型，给历史记录配图标。认不出来的回落到链接图标（也就是原来的样子）。
enum FileKind: Equatable {
    case image, video, audio, pdf, code, text, archive, spreadsheet, presentation, font, other

    static func of(filename: String) -> FileKind {
        let ext = (filename as NSString).pathExtension.lowercased()
        guard !ext.isEmpty else { return .other }

        // 先问系统的 UTType，常见格式基本都认得
        if let t = UTType(filenameExtension: ext) {
            if t.conforms(to: .image)        { return .image }
            if t.conforms(to: .movie)        { return .video }
            if t.conforms(to: .audio)        { return .audio }
            if t.conforms(to: .pdf)          { return .pdf }
            if t.conforms(to: .sourceCode)   { return .code }
            if t.conforms(to: .archive)      { return .archive }
            if t.conforms(to: .spreadsheet)  { return .spreadsheet }
            if t.conforms(to: .presentation) { return .presentation }
            if t.conforms(to: .font)         { return .font }
            if t.conforms(to: .text)         { return .text }
        }
        // UTType 认不出来的再兜一层：新图片格式在旧系统上没注册，
        // 前端那堆源码后缀系统也多半不认
        return extras[ext] ?? .other
    }

    private static let extras: [String: FileKind] = [
        "webp": .image, "avif": .image, "jxl": .image, "heic": .image, "heif": .image, "ico": .image,
        "mkv": .video, "webm": .video, "flv": .video, "m4v": .video,
        "flac": .audio, "opus": .audio, "ogg": .audio, "wma": .audio,
        "tsx": .code, "jsx": .code, "vue": .code, "svelte": .code, "astro": .code,
        "rs": .code, "go": .code, "kt": .code, "toml": .code, "yml": .code, "yaml": .code,
        "7z": .archive, "zst": .archive, "xz": .archive, "dmg": .archive,
        "md": .text, "mdx": .text, "log": .text, "srt": .text,
    ]

    var symbol: String {
        switch self {
        case .image:        return "photo"
        case .video:        return "film"
        case .audio:        return "waveform"
        case .pdf:          return "doc.richtext"
        case .code:         return "chevron.left.forwardslash.chevron.right"
        case .text:         return "doc.text"
        case .archive:      return "doc.zipper"
        case .spreadsheet:  return "tablecells"
        case .presentation: return "rectangle.on.rectangle"
        case .font:         return "textformat"
        case .other:        return "link"       // 认不出来时保持原来的链接图标
        }
    }

    var tint: Color {
        switch self {
        case .image:        return .green
        case .video:        return .purple
        case .audio:        return .pink
        case .pdf:          return .red
        case .code:         return .blue
        case .archive:      return .orange
        case .spreadsheet:  return .teal
        case .presentation: return .orange
        case .font:         return .indigo
        case .text, .other: return .secondary
        }
    }
}

// MARK: - 缩略图

/// 缩略图从哪来：队列里文件还在本地，直接读盘；历史里只剩 URL，只能回源。
enum ThumbnailSource: Hashable {
    case local(URL)
    case remote(String)

    var cacheKey: String {
        switch self {
        case .local(let url):  return "file://\(url.path)"
        case .remote(let s):   return s
        }
    }
}

/// 取到的缩略图缩到 56px 存内存，失败的记下来不再重试。
@MainActor
final class ThumbnailLoader {
    static let shared = ThumbnailLoader()

    private let cache = NSCache<NSString, NSImage>()
    private var failed: Set<String> = []

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.requestCachePolicy = .returnCacheDataElseLoad
        cfg.urlCache = URLCache(memoryCapacity: 8 << 20, diskCapacity: 64 << 20)
        cfg.timeoutIntervalForRequest = 15
        return URLSession(configuration: cfg)
    }()

    private init() { cache.countLimit = 300 }

    func thumbnail(_ source: ThumbnailSource) async -> NSImage? {
        let key = source.cacheKey
        if let hit = cache.object(forKey: key as NSString) { return hit }
        if failed.contains(key) { return nil }

        let data: Data?
        switch source {
        case .local(let url):  data = await Self.readLocal(url)
        case .remote(let s):   data = await fetchRemote(s)
        }
        guard let data, let image = NSImage(data: data), image.size.width > 0 else {
            failed.insert(key)
            return nil
        }
        let small = Self.downscale(image, to: 56)
        cache.setObject(small, forKey: key as NSString)
        return small
    }

    /// nonisolated：后台读盘那段也要用
    nonisolated static let sizeLimit = 24 << 20

    /// 读盘放到后台，别让一张大图卡住主线程。NSImage 不是 Sendable，所以只把 Data 传回来。
    private static func readLocal(_ url: URL) async -> Data? {
        await Task.detached(priority: .utility) {
            let size = (try? FileManager.default
                .attributesOfItem(atPath: url.path)[.size] as? NSNumber)??.intValue ?? 0
            guard size > 0, size < sizeLimit else { return nil }
            return try? Data(contentsOf: url)
        }.value
    }

    private func fetchRemote(_ urlString: String) async -> Data? {
        guard let url = URL(string: urlString), url.scheme?.hasPrefix("http") == true else {
            return nil
        }
        guard let (data, response) = try? await session.data(from: url) else { return nil }
        let code = (response as? HTTPURLResponse)?.statusCode ?? 200
        guard (200..<300).contains(code), data.count < Self.sizeLimit else { return nil }
        return data
    }

    /// 按短边缩放到 side，长边裁掉 —— 行里是个正方形小格子，填满比留白好看
    private static func downscale(_ image: NSImage, to side: CGFloat) -> NSImage {
        let size = image.size
        guard size.width > side || size.height > side else { return image }
        let scale = max(side / size.width, side / size.height)
        let scaled = CGSize(width: size.width * scale, height: size.height * scale)
        let out = NSImage(size: CGSize(width: side, height: side))
        out.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: CGRect(x: (side - scaled.width) / 2, y: (side - scaled.height) / 2,
                              width: scaled.width, height: scaled.height),
                   from: .zero, operation: .copy, fraction: 1)
        out.unlockFocus()
        return out
    }
}

// MARK: - 行首图标

/// 队列行右下角的状态角标。历史行没有角标 —— 有没有角标就是两个列表的区分点。
enum UploadBadge {
    case waiting, uploading, done, failed

    var symbol: String {
        switch self {
        case .waiting:   return "clock.fill"
        case .uploading: return "arrow.up.circle.fill"
        case .done:      return "checkmark.circle.fill"
        case .failed:    return "exclamationmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .waiting:   return .secondary
        case .uploading: return .accentColor
        case .done:      return .green
        case .failed:    return .orange
        }
    }
}

/// 图片类型显示缩略图，其余（以及缩略图取不到时）显示类型图标。
/// 队列和历史共用，差别只在 `badge`。
struct FileThumbnail: View {
    let filename: String
    let source: ThumbnailSource
    var badge: UploadBadge?
    var dimmed = false

    @State private var image: NSImage?

    private var kind: FileKind { FileKind.of(filename: filename) }

    var body: some View {
        ZStack {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                RoundedRectangle(cornerRadius: 5)
                    .fill(kind.tint.opacity(0.14))
                Image(systemName: kind.symbol)
                    .font(.system(size: 13))
                    .foregroundStyle(kind.tint)
            }
        }
        .frame(width: 28, height: 28)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .opacity(dimmed ? 0.55 : 1)
        .overlay(alignment: .bottomTrailing) {
            if let badge {
                Image(systemName: badge.symbol)
                    .symbolRenderingMode(.palette)
                    // 白描边压在缩略图上才认得出来
                    .foregroundStyle(Color(nsColor: .windowBackgroundColor), badge.color)
                    .font(.system(size: 12))
                    .offset(x: 4, y: 4)
            }
        }
        // 行是懒加载的，只有真正滚到眼前的图片才会去取
        .task(id: source) {
            guard kind == .image, image == nil else { return }
            image = await ThumbnailLoader.shared.thumbnail(source)
        }
    }
}
