import Foundation

// MARK: - 键值对（用于自定义 Header / 表单字段）

struct KeyValue: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var key: String = ""
    var value: String = ""
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
    var s3AccessKeyID: String = ""
    /// 公开访问前缀，如 https://cdn.example.com ；留空则用签名请求的 URL
    var s3PublicBaseURL: String = ""

    var subtitle: String {
        switch mode {
        case .s3: return s3Bucket.isEmpty ? "S3-compatible storage".t : "s3://\(s3Bucket)"
        default:  return endpoint.isEmpty ? "No URL configured".t : endpoint
        }
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
        p.formFields = [KeyValue(key: "token", value: "")]
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
}
