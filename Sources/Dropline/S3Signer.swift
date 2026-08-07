import Foundation
import CryptoKit

/// AWS Signature Version 4（PUT Object），兼容 S3 / Cloudflare R2 / MinIO / 阿里云 OSS(S3 网关) 等。
enum S3Signer {

    static func signedPutRequest(endpointBase: String,
                                 bucket: String,
                                 key: String,
                                 region: String,
                                 accessKeyID: String,
                                 secretAccessKey: String,
                                 fileURL: URL,
                                 contentType: String) throws -> URLRequest {
        guard let baseComps = URLComponents(string: endpointBase), let host = baseComps.host else {
            throw UploadError.invalidEndpoint(endpointBase)
        }
        // 统一使用 path-style（endpoint/bucket/key），对自建与 R2 都成立。
        let basePath = baseComps.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var segments: [String] = []
        if !basePath.isEmpty { segments += basePath.split(separator: "/").map(String.init) }
        segments.append(bucket)
        segments += key.split(separator: "/").map(String.init)
        let canonicalURI = "/" + segments.map(uriEncode).joined(separator: "/")

        let scheme = baseComps.scheme ?? "https"
        let portPart = baseComps.port.map { ":\($0)" } ?? ""
        guard let url = URL(string: "\(scheme)://\(host)\(portPart)\(canonicalURI)") else {
            throw UploadError.invalidEndpoint(endpointBase)
        }

        let payloadHash = try fileSHA256(fileURL)
        let now = Date()
        let amzDate = format(now, "yyyyMMdd'T'HHmmss'Z'")
        let dateStamp = format(now, "yyyyMMdd")
        let hostHeader = "\(host)\(portPart)"

        // 参与签名的头（按字典序）
        // 不签 content-length：URLSession 会自行填充该头，签了容易因不一致而失败。
        let signedHeaderList = ["content-type", "host", "x-amz-content-sha256", "x-amz-date"]
        let headerValues: [String: String] = [
            "content-type": contentType,
            "host": hostHeader,
            "x-amz-content-sha256": payloadHash,
            "x-amz-date": amzDate,
        ]
        let canonicalHeaders = signedHeaderList.map { "\($0):\(headerValues[$0]!)\n" }.joined()
        let signedHeaders = signedHeaderList.joined(separator: ";")

        let canonicalRequest = [
            "PUT", canonicalURI, "", canonicalHeaders, signedHeaders, payloadHash,
        ].joined(separator: "\n")

        let scope = "\(dateStamp)/\(region)/s3/aws4_request"
        let stringToSign = [
            "AWS4-HMAC-SHA256",
            amzDate,
            scope,
            SHA256.hash(data: Data(canonicalRequest.utf8)).hexString,
        ].joined(separator: "\n")

        var signingKey = hmac(Data("AWS4\(secretAccessKey)".utf8), Data(dateStamp.utf8))
        signingKey = hmac(signingKey, Data(region.utf8))
        signingKey = hmac(signingKey, Data("s3".utf8))
        signingKey = hmac(signingKey, Data("aws4_request".utf8))
        let signature = hmac(signingKey, Data(stringToSign.utf8)).hexString

        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.setValue(contentType, forHTTPHeaderField: "Content-Type")
        req.setValue(payloadHash, forHTTPHeaderField: "x-amz-content-sha256")
        req.setValue(amzDate, forHTTPHeaderField: "x-amz-date")
        req.setValue(
            "AWS4-HMAC-SHA256 Credential=\(accessKeyID)/\(scope), SignedHeaders=\(signedHeaders), Signature=\(signature)",
            forHTTPHeaderField: "Authorization")
        return req
    }

    // MARK: - 工具

    private static func hmac(_ key: Data, _ message: Data) -> Data {
        Data(HMAC<SHA256>.authenticationCode(for: message, using: SymmetricKey(data: key)))
    }

    /// 流式计算文件 SHA256，避免把大视频整个读进内存。
    static func fileSHA256(_ url: URL) throws -> String {
        var hasher = SHA256()
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        while let chunk = try handle.read(upToCount: 4 << 20), !chunk.isEmpty {
            hasher.update(data: chunk)
        }
        return hasher.finalize().hexString
    }

    /// AWS 规定的 URI 编码（不编码 A-Z a-z 0-9 - _ . ~）。
    private static func uriEncode(_ s: String) -> String {
        var out = ""
        for byte in Array(s.utf8) {
            let c = Character(UnicodeScalar(byte))
            if (byte >= 65 && byte <= 90) || (byte >= 97 && byte <= 122) || (byte >= 48 && byte <= 57)
                || c == "-" || c == "_" || c == "." || c == "~" {
                out.append(c)
            } else {
                out += String(format: "%%%02X", byte)
            }
        }
        return out
    }

    private static func format(_ date: Date, _ fmt: String) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = fmt
        return f.string(from: date)
    }
}
