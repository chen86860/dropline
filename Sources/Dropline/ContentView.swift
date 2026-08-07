import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var state: AppState
    @State private var isTargeted = false
    @State private var tab: Tab = .queue

    enum Tab: String, CaseIterable, Identifiable {
        case queue = "上传队列"
        case history = "历史记录"
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
                        ForEach(Tab.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
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
                Text("拖拽 · 面板 · 右键上传").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Picker("图床", selection: Binding(
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
                .help("设置")
            } else {
                Button {
                    state.openSettings()
                } label: {
                    Image(systemName: "gearshape")
                }
                .help("设置")
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
                Text(isTargeted ? "松手即可上传" : "把图片 / 视频 / 任意文件拖到这里")
                    .font(.callout)
                HStack(spacing: 12) {
                    Button("选择文件…") { state.pickFiles() }
                    Button("从剪贴板上传") { pasteFromClipboard() }
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
        state.lastMessage = "剪贴板里没有可上传的图片或文件"
    }

    // MARK: 队列

    private var queueList: some View {
        Group {
            if state.items.isEmpty {
                emptyHint("暂无上传任务")
            } else {
                List {
                    ForEach(state.items) { item in
                        UploadRow(item: item)
                            .contextMenu {
                                if case .done(let url) = item.status {
                                    Button("复制链接") { state.copy(text: url) }
                                    Button("复制 Markdown") {
                                        state.copy(text: "![\(item.fileURL.lastPathComponent)](\(url))")
                                    }
                                    Button("在浏览器打开") {
                                        if let u = URL(string: url) { NSWorkspace.shared.open(u) }
                                    }
                                    Divider()
                                }
                                Button("从队列移除") { state.remove(item.id) }
                                Button("清除已完成") { state.clearFinished() }
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
                emptyHint("还没有上传记录")
            } else {
                List {
                    ForEach(state.history) { rec in
                        HStack(spacing: 10) {
                            Image(systemName: "link")
                                .foregroundStyle(.secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(rec.filename).lineLimit(1)
                                Text(rec.url).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                            Spacer()
                            Text(rec.date, style: .time).font(.caption2).foregroundStyle(.tertiary)
                            Button {
                                state.copy(text: state.formatted(url: rec.url, filename: rec.filename))
                                state.lastMessage = "已复制链接"
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                            .buttonStyle(.borderless)
                        }
                        .contextMenu {
                            Button("复制链接") { state.copy(text: rec.url) }
                            Button("复制 Markdown") { state.copy(text: "![\(rec.filename)](\(rec.url))") }
                            Button("在浏览器打开") {
                                if let u = URL(string: rec.url) { NSWorkspace.shared.open(u) }
                            }
                            Divider()
                            Button("清空历史") { state.clearHistory() }
                        }
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

// MARK: - 队列行

struct UploadRow: View {
    @EnvironmentObject var state: AppState
    let item: UploadItem

    var body: some View {
        HStack(spacing: 10) {
            icon
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(item.fileURL.lastPathComponent).lineLimit(1)
                    Text(item.byteCount.humanSize).font(.caption2).foregroundStyle(.tertiary)
                }
                switch item.status {
                case .waiting:
                    Text("等待中…").font(.caption).foregroundStyle(.secondary)
                case .uploading:
                    ProgressView(value: item.progress).progressViewStyle(.linear)
                case .done(let url):
                    Text(url).font(.caption).foregroundStyle(.secondary).lineLimit(1).textSelection(.enabled)
                case .failed(let msg):
                    Text(msg).font(.caption).foregroundStyle(.red).lineLimit(2)
                }
            }
            Spacer()
            if case .done(let url) = item.status {
                Button {
                    state.copy(text: state.formatted(url: url, filename: item.fileURL.lastPathComponent))
                    state.lastMessage = "已复制链接"
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder private var icon: some View {
        switch item.status {
        case .waiting:   Image(systemName: "clock").foregroundStyle(.secondary)
        case .uploading: ProgressView().controlSize(.small)
        case .done:      Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        case .failed:    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
        }
    }
}
