import Foundation
import CryptoKit
import CommonCrypto

// MARK: - 备份文件格式
//
// 配置本体是明文 JSON（方便自己核对、改完再导回来），
// 机密字段单独放在 `secrets` 里 —— 要么整块不导出，要么用口令加密成 `encryptedSecrets`。
// 两者互斥，导出的文件里绝不会出现明文密钥。

struct EncryptedBlob: Codable {
    var kdf: String
    var iterations: Int
    var salt: Data
    /// AES-GCM 的 combined 形式：nonce || ciphertext || tag
    var combined: Data
}

struct ProfileBackup: Codable {
    static let formatID = "dropline.profiles"
    static let currentVersion = 1

    var format: String = ProfileBackup.formatID
    var version: Int = ProfileBackup.currentVersion
    var exportedAt: Date = Date()
    var appVersion: String = ""
    /// 已抹掉机密字段的配置
    var profiles: [UploaderProfile] = []
    var activeProfileID: UUID?
    /// profileID.uuidString → (槽位 → 值)。不导出密钥时为 nil
    var secrets: [String: [String: String]]?
    /// 加了口令时，上面那份 JSON 的密文；与 `secrets` 互斥
    var encryptedSecrets: EncryptedBlob?

    var carriesSecrets: Bool { secrets != nil || encryptedSecrets != nil }

    init() {}

    /// 别人手改过的文件、跨版本的文件都要能读进来，缺字段一律走默认值
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        format = (try? c.decodeIfPresent(String.self, forKey: .format)) ?? nil ?? ""
        version = (try? c.decodeIfPresent(Int.self, forKey: .version)) ?? nil ?? 0
        exportedAt = (try? c.decodeIfPresent(Date.self, forKey: .exportedAt)) ?? nil ?? Date()
        appVersion = (try? c.decodeIfPresent(String.self, forKey: .appVersion)) ?? nil ?? ""
        profiles = try c.decode([UploaderProfile].self, forKey: .profiles)
        activeProfileID = (try? c.decodeIfPresent(UUID.self, forKey: .activeProfileID)) ?? nil
        secrets = (try? c.decodeIfPresent([String: [String: String]].self, forKey: .secrets)) ?? nil
        encryptedSecrets = (try? c.decodeIfPresent(EncryptedBlob.self, forKey: .encryptedSecrets)) ?? nil
    }
}

enum BackupError: LocalizedError {
    case notABackup
    case needsPassword
    case wrongPassword
    case unreadable(String)

    var errorDescription: String? {
        switch self {
        case .notABackup:      return "Not a Dropline profile backup".t
        case .needsPassword:   return "This backup is password-protected".t
        case .wrongPassword:   return "Wrong password, or the file has been modified".t
        case .unreadable(let s): return "Could not read the backup: %@".t(s)
        }
    }
}

// MARK: - 读写

enum ProfileBackupService {

    static func encoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }

    private static func decoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    /// 打包一份备份。`password` 为空表示不加密 —— 此时只有在 `includeSecrets` 关掉时才允许，
    /// 调用方负责保证这一点（UI 上「包含密钥」必须配口令）。
    static func make(profiles: [UploaderProfile],
                     activeProfileID: UUID?,
                     includeSecrets: Bool,
                     password: String) throws -> Data {
        var backup = ProfileBackup()
        backup.appVersion = Bundle.main
            .object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        backup.profiles = profiles.map { $0.strippingSecrets() }
        backup.activeProfileID = activeProfileID

        if includeSecrets {
            var all: [String: [String: String]] = [:]
            for p in profiles {
                let s = Keychain.secrets(forProfile: p.id)
                if !s.isEmpty { all[p.id.uuidString] = s }
            }
            if password.isEmpty {
                backup.secrets = all
            } else {
                let plain = try JSONEncoder().encode(all)
                backup.encryptedSecrets = try seal(plain, password: password)
            }
        }
        return try encoder().encode(backup)
    }

    static func read(_ data: Data) throws -> ProfileBackup {
        let backup: ProfileBackup
        do {
            backup = try decoder().decode(ProfileBackup.self, from: data)
        } catch {
            throw BackupError.notABackup
        }
        guard backup.format == ProfileBackup.formatID else { throw BackupError.notABackup }
        return backup
    }

    /// 取出备份里的密钥。加密的备份必须给口令，口令不对会抛 `wrongPassword`。
    static func secrets(from backup: ProfileBackup, password: String?) throws -> [String: [String: String]] {
        if let blob = backup.encryptedSecrets {
            guard let password, !password.isEmpty else { throw BackupError.needsPassword }
            let plain = try open(blob, password: password)
            guard let dict = try? JSONDecoder().decode([String: [String: String]].self, from: plain) else {
                throw BackupError.wrongPassword
            }
            return dict
        }
        return backup.secrets ?? [:]
    }

    // MARK: - 口令加密

    private static let iterations = 310_000

    private static func seal(_ data: Data, password: String) throws -> EncryptedBlob {
        var salt = Data(count: 16)
        let ok = salt.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 16, $0.baseAddress!) }
        guard ok == errSecSuccess else { throw BackupError.unreadable("RNG") }
        let key = try derive(password: password, salt: salt, iterations: iterations)
        let box = try AES.GCM.seal(data, using: key)
        guard let combined = box.combined else { throw BackupError.unreadable("AES-GCM") }
        return EncryptedBlob(kdf: "PBKDF2-HMAC-SHA256", iterations: iterations,
                             salt: salt, combined: combined)
    }

    private static func open(_ blob: EncryptedBlob, password: String) throws -> Data {
        let key = try derive(password: password, salt: blob.salt, iterations: blob.iterations)
        guard let box = try? AES.GCM.SealedBox(combined: blob.combined),
              let plain = try? AES.GCM.open(box, using: key) else {
            throw BackupError.wrongPassword
        }
        return plain
    }

    private static func derive(password: String, salt: Data, iterations: Int) throws -> SymmetricKey {
        var out = [UInt8](repeating: 0, count: 32)
        let outCount = out.count
        let pw = Array(password.utf8)
        guard !pw.isEmpty else { throw BackupError.needsPassword }
        let status = salt.withUnsafeBytes { saltBuf -> Int32 in
            pw.withUnsafeBufferPointer { pwBuf in
                pwBuf.baseAddress!.withMemoryRebound(to: CChar.self, capacity: pw.count) { pwChars in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        pwChars, pw.count,
                        saltBuf.bindMemory(to: UInt8.self).baseAddress, salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(iterations),
                        &out, outCount
                    )
                }
            }
        }
        guard status == kCCSuccess else { throw BackupError.unreadable("PBKDF2") }
        return SymmetricKey(data: Data(out))
    }
}
