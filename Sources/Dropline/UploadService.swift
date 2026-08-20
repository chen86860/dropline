import Foundation

enum UploadError: LocalizedError {
    case invalidEndpoint(String)
    case http(Int, String)
    case badResponse(String)
    case misconfigured(String)

    var errorDescription: String? {
        switch self {
        case .invalidEndpoint(let s): return "Invalid upload URL: %@".t(s)
        case .http(let code, let body):
            let snippet = body.count > 300 ? String(body.prefix(300)) + "…" : body
            return "HTTP \(code)\(snippet.isEmpty ? "" : "：\(snippet)")"
        case .badResponse(let s): return s
        case .misconfigured(let s): return "Incomplete configuration: %@".t(s)
        }
    }
}

/// 进度回调用的 URLSession 代理。
final class ProgressDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    private let onProgress: @Sendable (Double) -> Void
    init(onProgress: @escaping @Sendable (Double) -> Void) { self.onProgress = onProgress }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didSendBodyData bytesSent: Int64,
                    totalBytesSent: Int64,
                    totalBytesExpectedToSend total: Int64) {
        guard total > 0 else { return }
        onProgress(min(1.0, Double(totalBytesSent) / Double(total)))
    }
}

enum UploadService {

    static let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 60
        cfg.timeoutIntervalForResource = 60 * 60   // 大视频
        cfg.waitsForConnectivity = true
        return URLSession(configuration: cfg)
    }()

    /// 上传单个文件，返回最终可访问的 URL 字符串。
    static func upload(fileURL: URL,
                       profile: UploaderProfile,
                       progress: @escaping @Sendable (Double) -> Void) async throws -> String {
        let secret = Keychain.value(profileID: profile.id, slot: SecretSlot.authSecret)
        var ctx = Templating.context(for: fileURL)
        ctx["key"] = Templating.render(profile.keyTemplate, ctx)

        switch profile.mode {
        case .multipart, .binary:
            return try await httpUpload(fileURL: fileURL, profile: profile, secret: secret, ctx: ctx, progress: progress)
        case .s3:
            return try await s3Upload(fileURL: fileURL, profile: profile, secret: secret, ctx: ctx, progress: progress)
        }
    }

    // MARK: - 通用 HTTP 上传

    private static func httpUpload(fileURL: URL,
                                   profile: UploaderProfile,
                                   secret: String,
                                   ctx: [String: String],
                                   progress: @escaping @Sendable (Double) -> Void) async throws -> String {
        let rendered = Templating.render(profile.endpoint, ctx)
        guard var comps = URLComponents(string: rendered), comps.scheme != nil else {
            throw UploadError.invalidEndpoint(rendered.isEmpty ? "(empty)".t : rendered)
        }
        if profile.authKind == .query, !profile.authKeyName.isEmpty {
            var items = comps.queryItems ?? []
            items.append(URLQueryItem(name: profile.authKeyName, value: secret))
            comps.queryItems = items
        }
        guard let url = comps.url else { throw UploadError.invalidEndpoint(rendered) }

        var req = URLRequest(url: url)
        req.httpMethod = profile.httpMethod.uppercased()

        for h in profile.headers where !h.key.isEmpty {
            req.setValue(Templating.render(h.value, ctx), forHTTPHeaderField: h.key)
        }
        applyAuth(profile: profile, secret: secret, to: &req)

        var bodyFile: URL
        var cleanup = false
        if profile.mode == .multipart {
            let boundary = "DroplineBoundary-\(UUID().uuidString)"
            req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            bodyFile = try makeMultipartBody(fileURL: fileURL, profile: profile, ctx: ctx, boundary: boundary)
            cleanup = true
        } else {
            if req.value(forHTTPHeaderField: "Content-Type") == nil {
                req.setValue(mimeType(for: fileURL), forHTTPHeaderField: "Content-Type")
            }
            bodyFile = fileURL
        }
        defer { if cleanup { try? FileManager.default.removeItem(at: bodyFile) } }

        let delegate = ProgressDelegate(onProgress: progress)
        let (data, response) = try await session.upload(for: req, fromFile: bodyFile, delegate: delegate)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else {
            throw UploadError.http(code, String(data: data, encoding: .utf8) ?? "")
        }

        let result = try Templating.extract(path: profile.responseURLPath, from: data)
        return finalURL(result: result, profile: profile, ctx: ctx)
    }

    private static func applyAuth(profile: UploaderProfile, secret: String, to req: inout URLRequest) {
        switch profile.authKind {
        case .none, .query:
            break
        case .bearer:
            req.setValue("Bearer \(secret)", forHTTPHeaderField: "Authorization")
        case .basic:
            let raw = "\(profile.authKeyName):\(secret)"
            req.setValue("Basic \(Data(raw.utf8).base64EncodedString())", forHTTPHeaderField: "Authorization")
        case .header:
            let name = profile.authKeyName.isEmpty ? "Authorization" : profile.authKeyName
            req.setValue(secret, forHTTPHeaderField: name)
        }
    }

    /// 把 multipart body 写到临时文件，避免大视频撑爆内存。
    private static func makeMultipartBody(fileURL: URL,
                                          profile: UploaderProfile,
                                          ctx: [String: String],
                                          boundary: String) throws -> URL {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("dropline-\(UUID().uuidString).body")
        FileManager.default.createFile(atPath: tmp.path, contents: nil)
        let handle = try FileHandle(forWritingTo: tmp)
        defer { try? handle.close() }

        func write(_ s: String) throws { try handle.write(contentsOf: Data(s.utf8)) }

        for f in profile.formFields where !f.key.isEmpty {
            try write("--\(boundary)\r\n")
            try write("Content-Disposition: form-data; name=\"\(f.key)\"\r\n\r\n")
            try write(Templating.render(f.value, ctx) + "\r\n")
        }

        let field = profile.fileFieldName.isEmpty ? "file" : profile.fileFieldName
        let remoteName = (ctx["key"]?.isEmpty == false)
            ? (ctx["key"]! as NSString).lastPathComponent
            : fileURL.lastPathComponent
        try write("--\(boundary)\r\n")
        try write("Content-Disposition: form-data; name=\"\(field)\"; filename=\"\(remoteName)\"\r\n")
        try write("Content-Type: \(mimeType(for: fileURL))\r\n\r\n")

        let input = try FileHandle(forReadingFrom: fileURL)
        defer { try? input.close() }
        while let chunk = try input.read(upToCount: 1 << 20), !chunk.isEmpty {
            try handle.write(contentsOf: chunk)
        }
        try write("\r\n--\(boundary)--\r\n")
        return tmp
    }

    // MARK: - S3 兼容上传

    private static func s3Upload(fileURL: URL,
                                 profile: UploaderProfile,
                                 secret: String,
                                 ctx: [String: String],
                                 progress: @escaping @Sendable (Double) -> Void) async throws -> String {
        guard !profile.s3Bucket.isEmpty else { throw UploadError.misconfigured("missing Bucket".t) }
        guard !profile.s3AccessKeyID.isEmpty, !secret.isEmpty else {
            throw UploadError.misconfigured("missing Access Key ID / Secret Access Key".t)
        }
        let key = ctx["key"].flatMap { $0.isEmpty ? nil : $0 } ?? fileURL.lastPathComponent
        let region = profile.s3Region.isEmpty ? "auto" : profile.s3Region
        let endpointBase = profile.s3Endpoint.isEmpty
            ? "https://s3.\(region).amazonaws.com"
            : profile.s3Endpoint.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        let req = try S3Signer.signedPutRequest(
            endpointBase: endpointBase,
            bucket: profile.s3Bucket,
            key: key,
            region: region,
            accessKeyID: profile.s3AccessKeyID,
            secretAccessKey: secret,
            fileURL: fileURL,
            contentType: mimeType(for: fileURL)
        )

        let delegate = ProgressDelegate(onProgress: progress)
        let (data, response) = try await session.upload(for: req, fromFile: fileURL, delegate: delegate)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else {
            throw UploadError.http(code, String(data: data, encoding: .utf8) ?? "")
        }

        var ctx2 = ctx
        ctx2["key"] = key
        let base = profile.s3PublicBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: " /"))
        let result = base.isEmpty
            ? "\(endpointBase)/\(profile.s3Bucket)/\(key)"
            : "\(base)/\(key)"
        return finalURL(result: result, profile: profile, ctx: ctx2)
    }

    // MARK: - 结果 URL

    private static func finalURL(result: String, profile: UploaderProfile, ctx: [String: String]) -> String {
        guard !profile.urlTemplate.trimmingCharacters(in: .whitespaces).isEmpty else { return result }
        var c = ctx
        c["result"] = result
        return Templating.render(profile.urlTemplate, c)
    }

    static func mimeType(for url: URL) -> String {
        if let t = UTTypeMIME(url) { return t }
        return "application/octet-stream"
    }
}

#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
private func UTTypeMIME(_ url: URL) -> String? {
    UTType(filenameExtension: url.pathExtension)?.preferredMIMEType
}
#else
private func UTTypeMIME(_ url: URL) -> String? { nil }
#endif
