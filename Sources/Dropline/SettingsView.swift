import SwiftUI
import AppKit

struct SettingsView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        TabView {
            ProfilesSettings()
                .tabItem { Label("图床配置", systemImage: "externaldrive.badge.icloud") }
            GeneralSettings()
                .tabItem { Label("通用", systemImage: "gearshape") }
            HelpSettings()
                .tabItem { Label("右键上传", systemImage: "cursorarrow.click.2") }
            AboutSettings()
                .tabItem { Label("关于", systemImage: "info.circle") }
        }
        .frame(width: 700, height: 560)
    }
}

// MARK: - 通用

struct GeneralSettings: View {
    @EnvironmentObject var state: AppState
    @EnvironmentObject var updater: UpdaterModel

    var body: some View {
        Form {
            Section {
                Toggle("上传完成后自动把链接复制到剪贴板", isOn: $state.autoCopyURL)
                Toggle("复制为 Markdown 格式 ![name](url)", isOn: $state.markdownCopy)
                    .disabled(!state.autoCopyURL)
                Toggle("上传完成后发送系统通知", isOn: $state.notifyOnFinish)
                Toggle("隐藏 Dock 图标（仅保留菜单栏图标）", isOn: $state.hideDockIcon)
                Picker("同时上传数量", selection: $state.maxConcurrent) {
                    ForEach([1, 2, 3, 5, 8], id: \.self) { Text("\($0)").tag($0) }
                }
                .frame(maxWidth: 240)
            }

            Section("软件更新") {
                Toggle("自动检查更新", isOn: $updater.automaticallyChecks)
                Toggle("自动下载并安装更新", isOn: $updater.automaticallyDownloads)
                    .disabled(!updater.automaticallyChecks)
                HStack {
                    Text("当前版本")
                    Spacer()
                    Text(updater.versionString).foregroundStyle(.secondary)
                }
                HStack {
                    Text("上次检查")
                    Spacer()
                    if let d = updater.lastCheck {
                        Text(d.formatted(date: .abbreviated, time: .shortened))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("从未").foregroundStyle(.secondary)
                    }
                }
                HStack {
                    Button("现在检查更新") { updater.checkForUpdates() }
                        .disabled(!updater.canCheck)
                    Spacer()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - 关于

struct AboutSettings: View {
    @EnvironmentObject var updater: UpdaterModel

    private let repoURL = "https://github.com/chen86860/dropline"

    private var bundleID: String { Bundle.main.bundleIdentifier ?? "—" }
    private var copyright: String {
        Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String ?? ""
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 10) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 96, height: 96)
                    Text("Dropline").font(.system(size: 24, weight: .semibold))
                    Text("拖进去，链接就在剪贴板里")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Text("版本 \(updater.versionString)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                .padding(.top, 24)

                HStack(spacing: 10) {
                    Button("检查更新…") { updater.checkForUpdates() }
                        .disabled(!updater.canCheck)
                    Button("项目主页") { open(repoURL) }
                    Button("反馈问题") { open("\(repoURL)/issues") }
                }

                Form {
                    LabeledContent("Bundle ID") {
                        Text(bundleID).textSelection(.enabled).foregroundStyle(.secondary)
                    }
                    LabeledContent("更新源") {
                        Text(updater.feedURL)
                            .textSelection(.enabled)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    LabeledContent("系统要求") {
                        Text("macOS 13+ · Apple Silicon").foregroundStyle(.secondary)
                    }
                    LabeledContent("技术栈") {
                        Text("Swift · SwiftUI · AppKit").foregroundStyle(.secondary)
                    }
                    LabeledContent("自动更新") {
                        Link("Sparkle", destination: URL(string: "https://sparkle-project.org")!)
                    }
                }
                .formStyle(.grouped)
                .frame(maxHeight: 240)

                if !copyright.isEmpty {
                    Text(copyright).font(.caption2).foregroundStyle(.tertiary)
                }
                Spacer(minLength: 12)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func open(_ string: String) {
        if let url = URL(string: string) { NSWorkspace.shared.open(url) }
    }
}

// MARK: - 右键 / 服务说明

struct HelpSettings: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Label("在 Finder 里右键上传", systemImage: "cursorarrow.click.2").font(.headline)
                Text("""
                选中任意文件（可多选）→ 右键 → 「服务 / Services」→ 「使用 Dropline 上传」。

                如果菜单里暂时没有出现该项：
                1. 确保 Dropline.app 已放入「应用程序」文件夹并至少启动过一次；
                2. 打开「系统设置 → 键盘 → 键盘快捷键 → 服务 → 文件与文件夹」，勾选「使用 Dropline 上传」（也可在此设置快捷键）；
                3. 仍未出现时，在终端执行：
                   /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /Applications/Dropline.app
                """)
                .font(.callout)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

                Divider()
                Label("其他上传方式", systemImage: "sparkles").font(.headline)
                Text("""
                • 把文件拖到主窗口的虚线区域，或直接拖到 Dock 图标上；
                • 主窗口点击「选择文件…」打开系统面板；
                • 主窗口点击「从剪贴板上传」，可直接上传截图；
                • 菜单栏（系统托盘）图标 → 「选择文件上传…」，并可查看/复制最近链接。
                """)
                .font(.callout)
                .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - 图床配置

struct ProfilesSettings: View {
    @EnvironmentObject var state: AppState
    @State private var selection: UUID?

    var body: some View {
        HSplitView {
            VStack(spacing: 0) {
                List(selection: $selection) {
                    ForEach(state.profiles) { p in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 5) {
                                if p.id == state.activeProfileID {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green).font(.caption)
                                }
                                Text(p.name)
                            }
                            Text(p.subtitle).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                        }
                        .tag(p.id)
                    }
                }
                Divider()
                HStack(spacing: 6) {
                    Menu {
                        ForEach(Array(ProfilePresets.all.enumerated()), id: \.offset) { _, preset in
                            Button(preset.0) {
                                state.addProfile(preset.1)
                                selection = state.profiles.last?.id
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 28)

                    Button {
                        if let id = selection { state.deleteProfile(id); selection = state.profiles.first?.id }
                    } label: { Image(systemName: "minus") }
                        .buttonStyle(.borderless)
                        .disabled(selection == nil)

                    Spacer()

                    Button("设为默认") {
                        if let id = selection { state.activeProfileID = id; state.saveProfiles() }
                    }
                    .buttonStyle(.link)
                    .disabled(selection == nil || selection == state.activeProfileID)
                }
                .padding(8)
            }
            .frame(minWidth: 190, idealWidth: 210, maxWidth: 260)

            Group {
                if let id = selection ?? state.activeProfileID,
                   let idx = state.profiles.firstIndex(where: { $0.id == id }) {
                    ProfileEditor(profile: $state.profiles[idx])
                        .id(id)
                } else {
                    VStack {
                        Spacer()
                        Text("左下角「+」新建一个图床配置").foregroundStyle(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .onAppear { if selection == nil { selection = state.activeProfileID } }
    }
}

// MARK: - 配置编辑器

struct ProfileEditor: View {
    @EnvironmentObject var state: AppState
    @Binding var profile: UploaderProfile

    @State private var secret: String = ""
    @State private var testing = false
    @State private var testResult: String = ""
    @State private var testOK = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Form {
                    Section {
                        TextField("名称", text: $profile.name)
                        Picker("上传方式", selection: $profile.mode) {
                            ForEach(UploadMode.allCases) { Text($0.label).tag($0) }
                        }
                    }

                    if profile.mode == .s3 {
                        s3Section
                    } else {
                        httpSection
                        authSection
                        responseSection
                    }

                    Section("远端文件名 / 对象 Key 模板") {
                        TextField("keyTemplate", text: $profile.keyTemplate, prompt: Text("{{date}}/{{uuid}}.{{ext}}"))
                        Text("可用变量：{{filename}} {{base}} {{ext}} {{uuid}} {{date}} {{datetime}} {{timestamp}} {{rand}}")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .formStyle(.grouped)

                HStack {
                    Button {
                        Task { await runTest() }
                    } label: {
                        if testing { ProgressView().controlSize(.small) } else { Text("测试上传") }
                    }
                    .disabled(testing)

                    if !testResult.isEmpty {
                        Text(testResult)
                            .font(.caption)
                            .foregroundStyle(testOK ? .green : .red)
                            .lineLimit(3)
                            .textSelection(.enabled)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .onAppear { secret = Keychain.get(account: Keychain.secretAccount(for: profile.id)) }
        .onChange(of: profile) { _ in state.saveProfiles() }
        .onChange(of: secret) { new in
            Keychain.set(new, account: Keychain.secretAccount(for: profile.id))
        }
    }

    // MARK: HTTP

    @ViewBuilder private var httpSection: some View {
        Section("请求") {
            TextField("上传地址", text: $profile.endpoint,
                      prompt: Text("https://example.com/api/upload"))
            Picker("方法", selection: $profile.httpMethod) {
                ForEach(["POST", "PUT", "PATCH"], id: \.self) { Text($0).tag($0) }
            }
            if profile.mode == .multipart {
                TextField("文件字段名", text: $profile.fileFieldName, prompt: Text("file"))
            }
            KeyValueEditor(title: "自定义请求头", items: $profile.headers)
            if profile.mode == .multipart {
                KeyValueEditor(title: "附加表单字段", items: $profile.formFields)
            }
        }
    }

    @ViewBuilder private var authSection: some View {
        Section("认证") {
            Picker("方式", selection: $profile.authKind) {
                ForEach(AuthKind.allCases) { Text($0.label).tag($0) }
            }
            switch profile.authKind {
            case .none:
                EmptyView()
            case .bearer:
                SecureField("Token", text: $secret)
            case .basic:
                TextField("用户名", text: $profile.authKeyName)
                SecureField("密码", text: $secret)
            case .header:
                TextField("Header 名", text: $profile.authKeyName, prompt: Text("Authorization"))
                SecureField("Header 值", text: $secret)
            case .query:
                TextField("参数名", text: $profile.authKeyName, prompt: Text("token"))
                SecureField("参数值", text: $secret)
            }
            if profile.authKind != .none {
                Text("密钥保存在系统钥匙串，不会写入配置文件。")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder private var responseSection: some View {
        Section("响应解析") {
            TextField("JSON 取值路径", text: $profile.responseURLPath, prompt: Text("data.url（留空表示响应体本身就是 URL）"))
            TextField("最终 URL 模板（可选）", text: $profile.urlTemplate,
                      prompt: Text("https://cdn.example.com/{{result}}"))
            Text("模板中 {{result}} 为上一步解析出的值，也可使用 {{key}}、{{filename}} 等变量。")
                .font(.caption2).foregroundStyle(.secondary)
        }
    }

    // MARK: S3

    @ViewBuilder private var s3Section: some View {
        Section("对象存储") {
            TextField("Endpoint", text: $profile.s3Endpoint,
                      prompt: Text("留空 = AWS；R2: https://<account>.r2.cloudflarestorage.com"))
            TextField("Region", text: $profile.s3Region, prompt: Text("auto / us-east-1"))
            TextField("Bucket", text: $profile.s3Bucket)
            TextField("Access Key ID", text: $profile.s3AccessKeyID)
            SecureField("Secret Access Key", text: $secret)
            TextField("公开访问域名（可选）", text: $profile.s3PublicBaseURL,
                      prompt: Text("https://cdn.example.com"))
            Text("留空则使用 Endpoint/Bucket/Key 作为返回链接。密钥保存在系统钥匙串。")
                .font(.caption2).foregroundStyle(.secondary)
        }
    }

    // MARK: 测试

    private func runTest() async {
        testing = true
        testResult = ""
        defer { testing = false }

        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("dropline-test-\(UUID().uuidString.prefix(6)).png")
        guard let png = Self.testPNG(), (try? png.write(to: tmp)) != nil else {
            testResult = "无法生成测试图片"
            testOK = false
            return
        }
        defer { try? FileManager.default.removeItem(at: tmp) }

        do {
            let url = try await UploadService.upload(fileURL: tmp, profile: profile) { _ in }
            testOK = true
            testResult = "成功：\(url)"
        } catch {
            testOK = false
            testResult = error.localizedDescription
        }
    }

    /// 生成一张 1×1 的 PNG 作为测试载荷。
    private static func testPNG() -> Data? {
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 8, pixelsHigh: 8,
                                   bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                   isPlanar: false, colorSpaceName: .deviceRGB,
                                   bytesPerRow: 0, bitsPerPixel: 0)
        guard let rep else { return nil }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSColor.systemBlue.setFill()
        NSRect(x: 0, y: 0, width: 8, height: 8).fill()
        NSGraphicsContext.restoreGraphicsState()
        return rep.representation(using: .png, properties: [:])
    }
}

// MARK: - 键值对编辑器

struct KeyValueEditor: View {
    let title: String
    @Binding var items: [KeyValue]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.callout)
                Spacer()
                Button {
                    items.append(KeyValue())
                } label: { Image(systemName: "plus.circle") }
                    .buttonStyle(.borderless)
            }
            ForEach($items) { $item in
                HStack(spacing: 6) {
                    TextField("Key", text: $item.key)
                    TextField("Value", text: $item.value)
                    Button {
                        items.removeAll { $0.id == item.id }
                    } label: { Image(systemName: "minus.circle") }
                        .buttonStyle(.borderless)
                }
            }
            if items.isEmpty {
                Text("（无）").font(.caption2).foregroundStyle(.tertiary)
            }
        }
    }
}
