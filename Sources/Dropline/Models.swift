import Foundation

// MARK: - 键值对（用于自定义 Header / 表单字段）

struct KeyValue: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var key: String = ""
    var value: String = ""
    /// 打开后这一项的值存进钥匙串，不写入配置文件（自定义 Header / 表单里塞 Token 的场景）
    var isSecret: Bool = false

    init(id: UUID = UUID(), key: String = "", value: String = "", isSecret: Bool = false) {
        self.id = id
        self.key = key
        self.value = value
        self.isSecret = isSecret
    }

    /// 老版本存的 JSON 里没有 `isSecret`，合成的解码器碰到缺字段会让整份 profiles 解码失败，
    /// 那等于用户的配置一次性全丢。所以逐字段可选读取，缺什么就用默认值。
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        key = try c.decodeIfPresent(String.self, forKey: .key) ?? ""
        value = try c.decodeIfPresent(String.self, forKey: .value) ?? ""
        isSecret = try c.decodeIfPresent(Bool.self, forKey: .isSecret) ?? false
    }
}

// MARK: - 上传方式

enum UploadMode: String, Codable, CaseIterable, Identifiable {
    case multipart      // multipart/form-data，最常见的图床 API
    case binary         // 请求体直接放文件二进制（PUT/POST）
    case s3             // S3 / R2 / MinIO 等兼容 S3 的对象存储（SigV4）

    var id: String { rawValue }

    var label: String {
        switch self {
        case .multipart: return "Form upload (multipart/form-data)".t
        case .binary:    return "Binary upload (PUT/POST raw body)".t
        case .s3:        return "S3-compatible object storage (AWS/R2/MinIO)".t
        }
    }
}

// MARK: - 鉴权方式

enum AuthKind: String, Codable, CaseIterable, Identifiable {
    case none
    case bearer         // Authorization: Bearer <secret>
    case basic          // Authorization: Basic base64(user:secret)
    case header         // <authKeyName>: <secret>
    case query          // ?<authKeyName>=<secret>

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none:   return "None".t
        case .bearer: return "Bearer Token"
        case .basic:  return "Basic (username + password)".t
        case .header: return "Custom header".t
        case .query:  return "URL query parameter".t
        }
    }
}

// MARK: - 上传配置（一个「图床」= 一个 Profile）

struct UploaderProfile: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String = "New Profile"
    var mode: UploadMode = .multipart

    // 通用 HTTP
    /// 支持模板变量，例如 https://cdn.example.com/api/upload/{{date}}
    var endpoint: String = ""
    var httpMethod: String = "POST"
    var fileFieldName: String = "file"
    var formFields: [KeyValue] = []
    var headers: [KeyValue] = []

    // 鉴权
    var authKind: AuthKind = .none
    /// header 模式下是 Header 名；query 模式下是参数名；basic 模式下是用户名
    var authKeyName: String = ""
    // 密钥本身存在 Keychain，account = "\(id.uuidString).secret"

    // 响应解析
    /// JSON 取值路径，如 `data.url`、`files.0.url`；留空表示响应体本身就是 URL
    var responseURLPath: String = "data.url"
    /// 最终 URL 模板，可用 {{result}} {{key}} {{filename}} 等；留空表示直接用上一步的结果
    var urlTemplate: String = ""

    // 远端文件名 / 对象 key 模板
    var keyTemplate: String = "{{date}}/{{uuid}}.{{ext}}"

    // S3 专用
    var s3Endpoint: String = ""      // 留空则用 https://s3.<region>.amazonaws.com
    var s3Region: String = "auto"
    var s3Bucket: String = ""
    /// 机密字段：内存里是真值，落盘前被 `strippingSecrets()` 清掉，实际存在钥匙串
    var s3AccessKeyID: String = ""
    /// 公开访问前缀，如 https://cdn.example.com ；留空则用签名请求的 URL
    var s3PublicBaseURL: String = ""

    init() {}

    /// 同 `KeyValue`：容错解码，缺字段取默认值。
    /// 除了兼容老配置，导入外部备份文件时也靠它兜住版本差异。
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func s(_ k: CodingKeys, _ fallback: String = "") -> String {
            (try? c.decodeIfPresent(String.self, forKey: k)) ?? nil ?? fallback
        }
        id = (try? c.decodeIfPresent(UUID.self, forKey: .id)) ?? nil ?? UUID()
        name = s(.name, "New Profile")
        mode = (try? c.decodeIfPresent(UploadMode.self, forKey: .mode)) ?? nil ?? .multipart
        endpoint = s(.endpoint)
        httpMethod = s(.httpMethod, "POST")
        fileFieldName = s(.fileFieldName, "file")
        formFields = (try? c.decodeIfPresent([KeyValue].self, forKey: .formFields)) ?? nil ?? []
        headers = (try? c.decodeIfPresent([KeyValue].self, forKey: .headers)) ?? nil ?? []
        authKind = (try? c.decodeIfPresent(AuthKind.self, forKey: .authKind)) ?? nil ?? .none
        authKeyName = s(.authKeyName)
        responseURLPath = s(.responseURLPath, "data.url")
        urlTemplate = s(.urlTemplate)
        keyTemplate = s(.keyTemplate, "{{date}}/{{uuid}}.{{ext}}")
        s3Endpoint = s(.s3Endpoint)
        s3Region = s(.s3Region, "auto")
        s3Bucket = s(.s3Bucket)
        s3AccessKeyID = s(.s3AccessKeyID)
        s3PublicBaseURL = s(.s3PublicBaseURL)
    }

    var subtitle: String {
        switch mode {
        case .s3: return s3Bucket.isEmpty ? "S3-compatible storage".t : "s3://\(s3Bucket)"
        default:  return endpoint.isEmpty ? "No URL configured".t : endpoint
        }
    }
}

// MARK: - 机密字段的拆装
//
// 内存里的 `profiles` 始终拿着真值，上传逻辑照常读；
// 只有在写进 UserDefaults / 备份文件之前才 `strippingSecrets()` 抹掉，
// 真值走 Keychain。反过来 `applySecrets` 把它们填回来。

extension UploaderProfile {
    /// 这份配置里所有该进钥匙串的字段：槽位 → 值。
    /// 认证密钥不在 `UploaderProfile` 里（编辑器直接读写钥匙串），所以不在这。
    var secretValues: [String: String] {
        var out: [String: String] = [:]
        if !s3AccessKeyID.isEmpty { out[SecretSlot.s3AccessKeyID] = s3AccessKeyID }
        for kv in headers + formFields where kv.isSecret && !kv.value.isEmpty {
            out[SecretSlot.field(kv.id)] = kv.value
        }
        return out
    }

    func strippingSecrets() -> UploaderProfile {
        var p = self
        p.s3AccessKeyID = ""
        let blank: (KeyValue) -> KeyValue = { kv in
            var k = kv
            if k.isSecret { k.value = "" }
            return k
        }
        p.headers = p.headers.map(blank)
        p.formFields = p.formFields.map(blank)
        return p
    }

    /// 一次性迁移用：凭字段名认出装凭据的 Header / 表单项，替用户勾上「机密」。
    /// 认错了也只是多存一层钥匙串，用户点开锁就能改回来，所以宁可宽一点。
    mutating func markLikelySecretFields() {
        let hints = ["token", "secret", "password", "passwd", "apikey", "api-key", "api_key",
                     "auth", "signature", "credential", "accesskey", "access-key", "access_key"]
        let mark: (KeyValue) -> KeyValue = { kv in
            var k = kv
            let name = k.key.lowercased()
            if hints.contains(where: name.contains) { k.isSecret = true }
            return k
        }
        headers = headers.map(mark)
        formFields = formFields.map(mark)
    }

    /// 用钥匙串（或备份文件）里的值填回机密字段。
    /// 空值不覆盖 —— 老配置的明文还留在 plist 里而钥匙串还没有时，靠这条保住它，
    /// 随后的 `saveProfiles()` 会把它迁进钥匙串并抹掉明文。
    mutating func applySecrets(_ values: [String: String]) {
        if let v = values[SecretSlot.s3AccessKeyID], !v.isEmpty { s3AccessKeyID = v }
        let fill: (KeyValue) -> KeyValue = { kv in
            var k = kv
            if k.isSecret, let v = values[SecretSlot.field(kv.id)], !v.isEmpty { k.value = v }
            return k
        }
        headers = headers.map(fill)
        formFields = formFields.map(fill)
    }
}

// MARK: - 内置预设

enum ProfilePresets {
    static var all: [(String, UploaderProfile)] {
        [
            ("Blank · Custom HTTP".t, blankHTTP),
            ("Blank · Custom binary PUT".t, blankBinary),
            ("Amazon S3", awsS3),
            ("Cloudflare R2", r2),
            ("Aliyun OSS (S3-compatible)".t, aliyunOSS),
            ("Tencent COS (S3-compatible)".t, tencentCOS),
            ("MinIO / self-hosted S3".t, minio),
            ("SM.MS", smms),
            ("Imgur", imgur),
            ("Lsky Pro / Chevereto", chevereto),
            ("EasyImage / PicGo custom".t, easyimage),
        ]
    }

    static var blankHTTP: UploaderProfile {
        var p = UploaderProfile()
        p.name = "Custom Upload".t
        p.mode = .multipart
        p.responseURLPath = "url"
        return p
    }

    static var blankBinary: UploaderProfile {
        var p = UploaderProfile()
        p.name = "Custom PUT Upload".t
        p.mode = .binary
        p.httpMethod = "PUT"
        p.endpoint = "https://your-domain.com/files/{{key}}"
        p.responseURLPath = ""
        p.urlTemplate = "https://your-domain.com/files/{{key}}"
        return p
    }

    private static func s3Base(_ name: String, region: String, endpoint: String) -> UploaderProfile {
        var p = UploaderProfile()
        p.name = name
        p.mode = .s3
        p.responseURLPath = ""
        p.keyTemplate = "images/{{date}}/{{uuid}}.{{ext}}"
        p.s3Region = region
        p.s3Endpoint = endpoint
        return p
    }

    static var awsS3: UploaderProfile { s3Base("Amazon S3", region: "us-east-1", endpoint: "") }

    static var r2: UploaderProfile {
        s3Base("Cloudflare R2", region: "auto",
               endpoint: "https://<ACCOUNT_ID>.r2.cloudflarestorage.com")
    }

    static var aliyunOSS: UploaderProfile {
        s3Base("Aliyun OSS".t, region: "oss-cn-hangzhou",
               endpoint: "https://oss-cn-hangzhou.aliyuncs.com")
    }

    static var tencentCOS: UploaderProfile {
        s3Base("Tencent COS".t, region: "ap-guangzhou",
               endpoint: "https://cos.ap-guangzhou.myqcloud.com")
    }

    static var minio: UploaderProfile {
        s3Base("MinIO", region: "us-east-1", endpoint: "http://127.0.0.1:9000")
    }

    static var easyimage: UploaderProfile {
        var p = UploaderProfile()
        p.name = "EasyImage"
        p.mode = .multipart
        p.endpoint = "https://your-domain.com/api/index.php"
        p.fileFieldName = "image"
        p.authKind = .none
        p.formFields = [KeyValue(key: "token", value: "", isSecret: true)]
        p.responseURLPath = "url"
        return p
    }

    static var smms: UploaderProfile {
        var p = UploaderProfile()
        p.name = "SM.MS"
        p.mode = .multipart
        p.endpoint = "https://sm.ms/api/v2/upload"
        p.fileFieldName = "smfile"
        p.authKind = .header
        p.authKeyName = "Authorization"
        p.responseURLPath = "data.url"
        return p
    }

    static var imgur: UploaderProfile {
        var p = UploaderProfile()
        p.name = "Imgur"
        p.mode = .multipart
        p.endpoint = "https://api.imgur.com/3/image"
        p.fileFieldName = "image"
        p.authKind = .header
        p.authKeyName = "Authorization"   // 值填 Client-ID xxxxxxxx
        p.responseURLPath = "data.link"
        return p
    }

    static var chevereto: UploaderProfile {
        var p = UploaderProfile()
        p.name = "Lsky Pro / Chevereto"
        p.mode = .multipart
        p.endpoint = "https://your-domain.com/api/v1/upload"
        p.fileFieldName = "file"
        p.authKind = .bearer
        p.headers = [KeyValue(key: "Accept", value: "application/json")]
        p.responseURLPath = "data.links.url"
        return p
    }
}

// MARK: - 历史记录

struct UploadRecord: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var filename: String
    var url: String
    var profileName: String
    var date: Date
    var byteCount: Int64

    init(id: UUID = UUID(), filename: String, url: String,
         profileName: String, date: Date, byteCount: Int64) {
        self.id = id
        self.filename = filename
        self.url = url
        self.profileName = profileName
        self.date = date
        self.byteCount = byteCount
    }

    /// 同 `UploaderProfile`：逐字段可选读取。合成的解码器缺一个字段就让整份
    /// history.v1 解码失败 —— 那等于所有历史记录一次性清空，这条必须挡住。
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decodeIfPresent(UUID.self, forKey: .id)) ?? nil ?? UUID()
        filename = (try? c.decodeIfPresent(String.self, forKey: .filename)) ?? nil ?? ""
        url = (try? c.decodeIfPresent(String.self, forKey: .url)) ?? nil ?? ""
        profileName = (try? c.decodeIfPresent(String.self, forKey: .profileName)) ?? nil ?? ""
        date = (try? c.decodeIfPresent(Date.self, forKey: .date)) ?? nil ?? Date()
        byteCount = (try? c.decodeIfPresent(Int64.self, forKey: .byteCount)) ?? nil ?? 0
    }
}
