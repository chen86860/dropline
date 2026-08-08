import SwiftUI
import AppKit

struct SettingsView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        TabView {
            GeneralSettings()
                .tabItem { Label("General".t, systemImage: "gearshape") }
            ProfilesSettings()
                .tabItem { Label("Hosts".t, systemImage: "externaldrive.badge.icloud") }
            AboutSettings()
                .tabItem { Label("About".t, systemImage: "info.circle") }
        }
        .frame(width: 700, height: 560)
        // .tabItem 的文案/图标换了以后 SwiftUI 不会就地更新，会串成上一份甚至重复；
        // 语言一变就整个重建 TabView。顺带也把各页 Picker 的选项一起刷新掉，
        // 所以下面各页不用再单独挂 id（挂在 Form 行上还会弄丢行背景）。
        .id(state.language)
    }
}

// MARK: - 通用

struct GeneralSettings: View {
    @EnvironmentObject var state: AppState
    @EnvironmentObject var updater: UpdaterModel

    var body: some View {
        Form {
            Section {
                Toggle("Copy the link to the clipboard when an upload finishes".t,
                       isOn: $state.autoCopyURL)
                Toggle("Copy as Markdown ![name](url)".t, isOn: $state.markdownCopy)
                    .disabled(!state.autoCopyURL)
                Toggle("Send a system notification when an upload finishes".t,
                       isOn: $state.notifyOnFinish)
                Toggle("Hide the Dock icon (menu bar only)".t, isOn: $state.hideDockIcon)
                // 不加 frame(maxWidth:)：Form 会把各行的控件对齐到同一列，
                // 一旦给不同的行设不同宽度，弹出按钮就会参差不齐
                Picker("Concurrent uploads".t, selection: $state.maxConcurrent) {
                    ForEach([1, 2, 3, 5, 8], id: \.self) { Text("\($0)").tag($0) }
                }
            }

            Section {
                Picker("Show as".t, selection: $state.finderMenuMode) {
                    ForEach(FinderMenuMode.allCases) { Text($0.label).tag($0) }
                }
            } header: {
                Text("Finder Context Menu".t)
            } footer: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(state.finderMenuMode.detail)
                    Text("Takes effect immediately. If the item is missing, turn Dropline on in System Settings → General → Login Items & Extensions → Finder Extensions.".t)
                    Text("You can also drop files on the window or the Dock icon, upload from the clipboard, or use the menu bar icon.".t)
                }
                .font(.caption).foregroundStyle(.secondary)
            }

            Section {
                Picker("Interface language".t, selection: $state.language) {
                    ForEach(AppLanguage.allCases) { Text($0.label).tag($0) }
                }
            } header: {
                Text("Language".t)
            } footer: {
                Text("Takes effect immediately, no restart needed.".t)
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section("Software Update".t) {
                Toggle("Check for updates automatically".t, isOn: $updater.automaticallyChecks)
                Toggle("Download and install updates automatically".t,
                       isOn: $updater.automaticallyDownloads)
                    .disabled(!updater.automaticallyChecks)
                HStack {
                    Text("Current version".t)
                    Spacer()
                    Text(updater.versionString).foregroundStyle(.secondary)
                }
                HStack {
                    Text("Last checked".t)
                    Spacer()
                    if let d = updater.lastCheck {
                        Text(d.formatted(date: .abbreviated, time: .shortened))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Never".t).foregroundStyle(.secondary)
                    }
                }
                HStack {
                    Button("Check Now".t) { updater.checkForUpdates() }
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
    /// 只为语言切换时跟着重绘（本页文案全走 .t）
    @EnvironmentObject var state: AppState

    private let repoURL = "https://github.com/chen86860/dropline"

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
                    Text("Drop it in, the link is on your clipboard".t)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Text("Version %@".t(updater.versionString))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                .padding(.top, 24)

                HStack(spacing: 10) {
                    Button("Check for Updates…".t) { updater.checkForUpdates() }
                        .disabled(!updater.canCheck)
                    Button("Project Home".t) { open(repoURL) }
                    Button("Report an Issue".t) { open("\(repoURL)/issues") }
                }

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

                    Button("Set as Default".t) {
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
                        Text("Create a host profile with “+” at the bottom left".t).foregroundStyle(.secondary)
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
                        TextField("Name".t, text: $profile.name)
                        Picker("Upload method".t, selection: $profile.mode) {
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

                    Section("Remote filename / object key template".t) {
                        TextField("keyTemplate", text: $profile.keyTemplate, prompt: Text("{{date}}/{{uuid}}.{{ext}}"))
                        Text("Variables: {{filename}} {{base}} {{ext}} {{uuid}} {{date}} {{datetime}} {{timestamp}} {{rand}}".t)
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .formStyle(.grouped)

                HStack {
                    Button {
                        Task { await runTest() }
                    } label: {
                        if testing { ProgressView().controlSize(.small) } else { Text("Test Upload".t) }
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
        Section("Request".t) {
            TextField("Upload URL".t, text: $profile.endpoint,
                      prompt: Text("https://example.com/api/upload"))
            Picker("Method".t, selection: $profile.httpMethod) {
                ForEach(["POST", "PUT", "PATCH"], id: \.self) { Text($0).tag($0) }
            }
            if profile.mode == .multipart {
                TextField("File field name".t, text: $profile.fileFieldName, prompt: Text("file"))
            }
            KeyValueEditor(title: "Custom headers".t, items: $profile.headers)
            if profile.mode == .multipart {
                KeyValueEditor(title: "Extra form fields".t, items: $profile.formFields)
            }
        }
    }

    @ViewBuilder private var authSection: some View {
        Section("Authentication".t) {
            Picker("Kind".t, selection: $profile.authKind) {
                ForEach(AuthKind.allCases) { Text($0.label).tag($0) }
            }
            switch profile.authKind {
            case .none:
                EmptyView()
            case .bearer:
                SecureField("Token", text: $secret)
            case .basic:
                TextField("Username".t, text: $profile.authKeyName)
                SecureField("Password".t, text: $secret)
            case .header:
                TextField("Header name".t, text: $profile.authKeyName, prompt: Text("Authorization"))
                SecureField("Header value".t, text: $secret)
            case .query:
                TextField("Parameter name".t, text: $profile.authKeyName, prompt: Text("token"))
                SecureField("Parameter value".t, text: $secret)
            }
            if profile.authKind != .none {
                Text("The secret is stored in the system keychain, never in the config file.".t)
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder private var responseSection: some View {
        Section("Response".t) {
            TextField("JSON path".t, text: $profile.responseURLPath,
                      prompt: Text("data.url (empty means the body itself is the URL)".t))
            TextField("Final URL template (optional)".t, text: $profile.urlTemplate,
                      prompt: Text("https://cdn.example.com/{{result}}"))
            Text("{{result}} is the value parsed above; {{key}}, {{filename}} and friends also work.".t)
                .font(.caption2).foregroundStyle(.secondary)
        }
    }

    // MARK: S3

    @ViewBuilder private var s3Section: some View {
        Section("Object Storage".t) {
            TextField("Endpoint", text: $profile.s3Endpoint,
                      prompt: Text("Empty = AWS; R2: https://<account>.r2.cloudflarestorage.com".t))
            TextField("Region", text: $profile.s3Region, prompt: Text("auto / us-east-1"))
            TextField("Bucket", text: $profile.s3Bucket)
            TextField("Access Key ID", text: $profile.s3AccessKeyID)
            SecureField("Secret Access Key", text: $secret)
            TextField("Public base URL (optional)".t, text: $profile.s3PublicBaseURL,
                      prompt: Text("https://cdn.example.com"))
            Text("Empty means the Endpoint/Bucket/Key URL is returned. The secret is stored in the system keychain.".t)
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
            testResult = "Could not generate a test image".t
            testOK = false
            return
        }
        defer { try? FileManager.default.removeItem(at: tmp) }

        do {
            let url = try await UploadService.upload(fileURL: tmp, profile: profile) { _ in }
            testOK = true
            testResult = "Success: %@".t(url)
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
                Text("(none)".t).font(.caption2).foregroundStyle(.tertiary)
            }
        }
    }
}
