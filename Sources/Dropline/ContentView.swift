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
                                    Button("Open in Browser".t) {
                                        if let u = URL(string: url) { NSWorkspace.shared.open(u) }
                                    }
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
                                state.lastMessage = "Link copied".t
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                            .buttonStyle(.borderless)
                        }
                        .contextMenu {
                            Button("Copy Link".t) { state.copy(text: rec.url) }
                            Button("Copy as Markdown".t) { state.copy(text: "![\(rec.filename)](\(rec.url))") }
                            Button("Open in Browser".t) {
                                if let u = URL(string: rec.url) { NSWorkspace.shared.open(u) }
                            }
                            Divider()
                            Button("Clear History".t) { state.clearHistory() }
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
                    Text("Waiting…".t).font(.caption).foregroundStyle(.secondary)
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
                    state.lastMessage = "Link copied".t
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
