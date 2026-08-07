import Foundation
import CryptoKit

/// `{{var}}` 模板渲染 + JSON 取值路径。
enum Templating {

    /// 为一个待上传文件构造模板变量表。
    static func context(for fileURL: URL, extra: [String: String] = [:]) -> [String: String] {
        let filename = fileURL.lastPathComponent
        let ext = fileURL.pathExtension.lowercased()
        let base = fileURL.deletingPathExtension().lastPathComponent
        let now = Date()

        let day = DateFormatter()
        day.dateFormat = "yyyy/MM/dd"
        day.timeZone = .current

        let compact = DateFormatter()
        compact.dateFormat = "yyyyMMddHHmmss"
        compact.timeZone = .current

        var ctx: [String: String] = [
            "filename": filename,
            "base": sanitize(base),
            "ext": ext,
            "uuid": UUID().uuidString.lowercased().replacingOccurrences(of: "-", with: ""),
            "date": day.string(from: now),
            "datetime": compact.string(from: now),
            "timestamp": String(Int(now.timeIntervalSince1970)),
            "rand": String(UUID().uuidString.prefix(6)).lowercased(),
        ]
        ctx.merge(extra) { _, new in new }
        return ctx
    }

    static func render(_ template: String, _ ctx: [String: String]) -> String {
        var out = template
        for (k, v) in ctx {
            out = out.replacingOccurrences(of: "{{\(k)}}", with: v)
            out = out.replacingOccurrences(of: "{{ \(k) }}", with: v)
        }
        return out
    }

    /// 去掉文件名里对 URL 不友好的字符（保留 ASCII 字母数字、-_. 与 CJK）。
    static func sanitize(_ s: String) -> String {
        let scalars = s.unicodeScalars.map { u -> Unicode.Scalar in
            let isASCIIAlnum = (u.value >= 48 && u.value <= 57)
                || (u.value >= 65 && u.value <= 90)
                || (u.value >= 97 && u.value <= 122)
            let isPunct = u == "-" || u == "_" || u == "."
            let isCJK = u.value >= 0x4E00 && u.value <= 0x9FFF
            return (isASCIIAlnum || isPunct || isCJK) ? u : "-"
        }
        return String(String.UnicodeScalarView(scalars))
    }

    /// 按 `a.b.0.c` 的路径从 JSON 里取值。路径为空时返回响应体原文。
    static func extract(path: String, from data: Data) throws -> String {
        let trimmedPath = path.trimmingCharacters(in: .whitespaces)
        if trimmedPath.isEmpty {
            let raw = String(data: data, encoding: .utf8) ?? ""
            return raw.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard let root = try? JSONSerialization.jsonObject(with: data) else {
            throw UploadError.badResponse("响应不是合法 JSON，无法按路径 `\(trimmedPath)` 取值")
        }
        var node: Any? = root
        for comp in trimmedPath.split(separator: ".") {
            if let dict = node as? [String: Any] {
                node = dict[String(comp)]
            } else if let arr = node as? [Any], let i = Int(comp), arr.indices.contains(i) {
                node = arr[i]
            } else {
                node = nil
            }
            if node == nil {
                throw UploadError.badResponse("响应中找不到路径 `\(trimmedPath)`")
            }
        }
        if let s = node as? String { return s }
        if let n = node as? NSNumber { return n.stringValue }
        throw UploadError.badResponse("路径 `\(trimmedPath)` 对应的值不是字符串")
    }
}

extension Data {
    var hexString: String { map { String(format: "%02x", $0) }.joined() }
}

extension Digest {
    var hexString: String { Data(self).hexString }
}
