import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var state: AppState
    @State private var isTargeted = false
    @State private var tab: Tab = .queue

    enum Tab: String, CaseIterable, Identifiable {
        case queue = "Upload Queue"
        case history = "History"
        var id: String { rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            dropZone
                .padding(16)
            Divider()
            Group {
                switch tab {
                case .queue: queueList
                case .history: historyList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // 用 safeAreaInset 而不是并排放：否则列表内容会滚到分段控件下面，首行被遮住
            .safeAreaInset(edge: .top, spacing: 0) {
                VStack(spacing: 0) {
                    Picker("", selection: $tab) {
                        ForEach(Tab.allCases) { Text($0.rawValue.t).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    // 同上：选项只有文案变化时 SwiftUI 不会重建，换 id 强制刷新
                    .id(state.language)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    Divider()
                }
                .background(.bar)
            }
        }
        .frame(minWidth: 560, minHeight: 560)
    }

    // MARK: 顶部

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.up.doc.on.clipboard")
                .font(.title2)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 1) {
                Text("Dropline").font(.headline)
                Text("Drag · Panel · Right-click".t).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Picker("Host".t, selection: Binding(
                get: { state.activeProfile?.id ?? UUID() },
                set: { state.activeProfileID = $0; state.saveProfiles() }
            )) {
                ForEach(state.profiles) { p in
                    Text(p.name).tag(p.id)
                }
            }
            .frame(maxWidth: 220)

            // SettingsLink 是新系统上唯一可靠的打开设置窗口的方式
            if #available(macOS 14, *) {
                SettingsLink {
                    Image(systemName: "gearshape")
                }
                .help("Settings".t)
            } else {
                Button {
                    state.openSettings()
                } label: {
                    Image(systemName: "gearshape")
                }
                .help("Settings".t)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: 拖拽区

    private var dropZone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                .foregroundStyle(isTargeted ? Color.accentColor : Color.secondary.opacity(0.45))
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isTargeted ? Color.accentColor.opacity(0.08) : Color.secondary.opacity(0.05))
                )
            VStack(spacing: 8) {
                Image(systemName: isTargeted ? "square.and.arrow.down.fill" : "square.and.arrow.up")
                    .font(.system(size: 30, weight: .light))
                Text(isTargeted ? "Release to upload".t : "Drop images, videos, or any file here".t)
                    .font(.callout)
                HStack(spacing: 12) {
                    Button("Choose Files…".t) { state.pickFiles() }
                    Button("Upload from Clipboard".t) { pasteFromClipboard() }
                }
                .padding(.top, 2)
            }
            .foregroundStyle(isTargeted ? Color.accentColor : Color.primary.opacity(0.8))
        }
        .frame(height: 150)
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers)
            return true
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) {
        for provider in providers {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url, url.isFileURL else { return }
                Task { @MainActor in state.enqueue([url]) }
            }
        }
    }

    /// 支持直接粘贴截图 / 复制的文件。
    private func pasteFromClipboard() {
        let pb = NSPasteboard.general
        if let urls = pb.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           !urls.filter({ $0.isFileURL }).isEmpty {
            state.enqueue(urls.filter { $0.isFileURL })
            return
        }
        if let image = pb.data(forType: .png) ?? pb.data(forType: .tiff) {
            let tmp = FileManager.default.temporaryDirectory
                .appendingPathComponent("clipboard-\(Int(Date().timeIntervalSince1970)).png")
            let png: Data?
            if pb.data(forType: .png) != nil {
                png = image
            } else {
                png = NSBitmapImageRep(data: image)?.representation(using: .png, properties: [:])
            }
            if let png, (try? png.write(to: tmp)) != nil {
                state.enqueue([tmp])
                return
            }
        }
        state.lastMessage = "No image or file in the clipboard".t
    }

    // MARK: 队列

    private var queueList: some View {
        Group {
            if state.items.isEmpty {
                emptyHint("No uploads yet".t)
            } else {
                List {
                    ForEach(state.items) { item in
                        UploadRow(item: item)
                            .contextMenu {
                                if case .done(let url) = item.status {
                                    Button("Copy Link".t) { state.copy(text: url) }
                                    Button("Copy as Markdown".t) {
                                        state.copy(text: "![\(item.fileURL.lastPathComponent)](\(url))")
                                    }
                                    Button("Open in Browser".t) { NSWorkspace.shared.openIfValid(url) }
                                    Divider()
                                }
                                Button("Remove from Queue".t) { state.remove(item.id) }
                                Button("Clear Finished".t) { state.clearFinished() }
                                    .disabled(!state.items.contains { $0.isFinished })
                            }
                    }
                }
                .listStyle(.inset)
            }
        }
    }

    // MARK: 历史

    private var historyList: some View {
        Group {
            if state.history.isEmpty {
                emptyHint("No history yet".t)
            } else {
                List {
                    ForEach(state.history) { rec in
                        HistoryRow(record: rec)
                    }
                }
                .listStyle(.inset)
            }
        }
    }

    private func emptyHint(_ text: String) -> some View {
        VStack {
            Spacer()
            Text(text).foregroundStyle(.secondary).font(.callout)
            Spacer()
        }
    }

}

// MARK: - 共用行

/// 上传队列和历史记录的行骨架。两个列表本来就是同一个东西，
/// 分开写迟早会在 spacing / padding 上悄悄分叉，切标签页就看得出行高在跳。
///
/// 差异全部收敛成参数：
/// - `badge` / `dimmed`：只有队列有（历史没有角标，这也是两个列表的区分点）
/// - `byteCount`：只有队列显示文件大小
/// - `secondary`：第二行的内容 —— 队列是等待/进度条/结果/错误，历史是链接
/// - `linkURL`：有链接才出打开和复制按钮
struct FileRow<Secondary: View>: View {
    @EnvironmentObject var state: AppState

    let filename: String
    let source: ThumbnailSource
    var badge: UploadBadge?
    var dimmed = false
    var byteCount: Int64?
    let date: Date
    var linkURL: String?
    @ViewBuilder let secondary: Secondary

    var body: some View {
        HStack(spacing: 10) {
            FileThumbnail(filename: filename, source: source, badge: badge, dimmed: dimmed)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(filename).lineLimit(1)
                    // 取不到大小（老记录没存、或入队时 stat 失败）就不显示，
                    // 免得摆一个「0 字节」误导人
                    if let byteCount, byteCount > 0 {
                        Text(byteCount.humanSize).font(.caption2).foregroundStyle(.tertiary)
                    }
                }
                // 第二行统一垫一个隐藏的空 caption 撑出基准高度：进度条比一行文字矮，
                // 不垫的话队列行和历史行差着几个点，来回切标签就抖。
                // 用隐藏文字而不是写死点数，系统字号变了也跟得上；
                // 错误可能两行，ZStack 取最大高度，不会被截断。
                ZStack(alignment: .leading) {
                    Text(" ").font(.caption).hidden()
                    secondary
                }
            }
            Spacer(minLength: 8)
            Text(RelativeTime.label(for: date))
                .font(.caption2)
                .monospacedDigit()
                .foregroundStyle(.tertiary)
            if let linkURL {
                OpenLinkButton(url: linkURL)
                CopyLinkButton {
                    state.copy(text: state.formatted(url: linkURL, filename: filename))
                    state.lastMessage = "Link copied".t
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - 历史行

struct HistoryRow: View {
    @EnvironmentObject var state: AppState
    let record: UploadRecord

    var body: some View {
        FileRow(filename: record.filename,
                source: .remote(record.url),
                byteCount: record.byteCount,
                date: record.date,
                linkURL: record.url) {
            Text(record.url)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .textSelection(.enabled)
        }
        .contextMenu {
            Button("Copy Link".t) { state.copy(text: record.url) }
            Button("Copy as Markdown".t) { state.copy(text: "![\(record.filename)](\(record.url))") }
            Button("Open in Browser".t) { NSWorkspace.shared.openIfValid(record.url) }
            Divider()
            Button("Clear History".t) { state.clearHistory() }
        }
    }
}

// MARK: - 行内按钮

/// 用默认浏览器打开链接
struct OpenLinkButton: View {
    let url: String

    var body: some View {
        Button {
            NSWorkspace.shared.openIfValid(url)
        } label: {
            Image(systemName: "arrow.up.forward.app")
        }
        .buttonStyle(.borderless)
        .help("Open in Browser".t)
        .disabled(URL(string: url)?.scheme == nil)
    }
}

/// lucide 的 check 图标：viewBox 24×24，path `M20 6 9 17l-5-5`，
/// stroke-width 2 + 圆头圆角。按框等比缩放，线宽跟着一起缩。
struct LucideCheck: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24
        let originX = rect.minX + (rect.width - 24 * scale) / 2
        let originY = rect.minY + (rect.height - 24 * scale) / 2
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: originX + x * scale, y: originY + y * scale)
        }
        var path = Path()
        path.move(to: point(20, 6))
        path.addLine(to: point(9, 17))
        path.addLine(to: point(4, 12))
        return path
    }
}

/// 复制后短暂变成对号，给一个「确实复制到了」的反馈
struct CopyLinkButton: View {
    let action: () -> Void

    /// 对号和复制图标共用的边长；不定宽的话一复制整行就会横向抖一下
    private let side: CGFloat = 16

    @State private var copied = false

    var body: some View {
        Button {
            action()
            copied = true
            Task {
                try? await Task.sleep(nanoseconds: 1_400_000_000)
                copied = false
            }
        } label: {
            Group {
                if copied {
                    LucideCheck()
                        .stroke(style: StrokeStyle(lineWidth: 2 * side / 24,
                                                   lineCap: .round, lineJoin: .round))
                        .foregroundStyle(Color.green)
                } else {
                    Image(systemName: "doc.on.doc")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .frame(width: side, height: side)
        }
        .buttonStyle(.borderless)
        .help(copied ? "Link copied".t : "Copy Link".t)
    }
}

extension NSWorkspace {
    func openIfValid(_ string: String) {
        if let url = URL(string: string), url.scheme != nil { open(url) }
    }
}

// MARK: - 队列行

struct UploadRow: View {
    let item: UploadItem

    private var filename: String { item.fileURL.lastPathComponent }

    var body: some View {
        FileRow(filename: filename,
                source: .local(item.fileURL),
                badge: badge,
                dimmed: item.status == .waiting,
                byteCount: item.byteCount,
                date: item.timestamp,
                linkURL: doneURL) {
            statusLine
        }
    }

    private var doneURL: String? {
        if case .done(let url) = item.status { return url }
        return nil
    }

    /// 第二行：等待文案 / 进度条 / 结果链接 / 错误。撑高度的活由 FileRow 统一干了。
    @ViewBuilder private var statusLine: some View {
        switch item.status {
        case .waiting:
            Text("Waiting…".t).font(.caption).foregroundStyle(.secondary)
        case .uploading:
            // 不用 ProgressView(.linear)：它自带的垂直余量比一行 caption 还高，
            // 会把行撑起来，「上传中 → 完成」时整行抖一下。
            // 自绘成 4pt 胶囊，高度确定且小于基准行高，行高完全由基准撑着。
            Capsule()
                .fill(Color.secondary.opacity(0.25))
                .frame(height: 4)
                .overlay(alignment: .leading) {
                    GeometryReader { geo in
                        Capsule()
                            .fill(Color.accentColor)
                            .frame(width: geo.size.width * min(max(item.progress, 0), 1))
                    }
                }
        case .done(let url):
            Text(url).font(.caption).foregroundStyle(.secondary).lineLimit(1).textSelection(.enabled)
        case .failed(let msg):
            Text(msg).font(.caption).foregroundStyle(.red).lineLimit(2)
        }
    }

    private var badge: UploadBadge {
        switch item.status {
        case .waiting:   return .waiting
        case .uploading: return .uploading
        case .done:      return .done
        case .failed:    return .failed
        }
    }
}
