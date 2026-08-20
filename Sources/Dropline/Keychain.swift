import Foundation
import Security

/// 机密字段的槽位名。备份文件里也用同一套槽位名，两边不用各维护一份映射。
enum SecretSlot {
    /// 认证密钥 / S3 Secret Access Key
    static let authSecret = "secret"
    static let s3AccessKeyID = "s3AccessKeyID"
    static let fieldPrefix = "field."
    /// 自定义 Header / 表单字段里被标记为机密的那一项
    static func field(_ id: UUID) -> String { "\(fieldPrefix)\(id.uuidString)" }
}

/// 全部机密存在**一条**钥匙串条目里（account = `secrets.v1`），
/// 内容是 `{profileID: {slot: 值}}` 的 JSON —— 跟备份文件的 `secrets` 字段同构。
///
/// 为什么不是一个槽位一条：钥匙串条目的 ACL 是各自独立的，每条都要单独授权。
/// App 的代码签名一变（ad-hoc 构建每次都变）授权就失效，有几条就挨着弹几次。
/// 合成一条之后最多只弹一次。
///
/// 另外进程内留一份内存镜像：一次启动只真正读一次钥匙串，
/// 之后每次上传、每次打开配置编辑器都走内存。
enum Keychain {
    static let service = "dev.emmmm.Dropline"
    private static let blobAccount = "secrets.v1"

    private static let lock = NSLock()
    private static var cache: [String: [String: String]]?

    // MARK: - 读写单个槽位

    static func value(profileID: UUID, slot: String) -> String {
        lock.lock(); defer { lock.unlock() }
        return loaded()[profileID.uuidString]?[slot] ?? ""
    }

    static func set(_ value: String, profileID: UUID, slot: String) {
        lock.lock(); defer { lock.unlock() }
        var store = loaded()
        var slots = store[profileID.uuidString] ?? [:]
        if value.isEmpty {
            slots.removeValue(forKey: slot)
        } else {
            slots[slot] = value
        }
        store[profileID.uuidString] = slots.isEmpty ? nil : slots
        commit(store)
    }

    // MARK: - 按配置成组读写

    /// 一个配置名下的全部机密（槽位 → 值），导出备份时用
    static func secrets(forProfile id: UUID) -> [String: String] {
        lock.lock(); defer { lock.unlock() }
        return loaded()[id.uuidString] ?? [:]
    }

    /// 合并写入（导入备份时用）
    static func store(_ secrets: [String: String], forProfile id: UUID) {
        lock.lock(); defer { lock.unlock() }
        var store = loaded()
        var slots = store[id.uuidString] ?? [:]
        for (slot, value) in secrets where !value.isEmpty { slots[slot] = value }
        store[id.uuidString] = slots.isEmpty ? nil : slots
        commit(store)
    }

    /// 写入给定槽位，并回收这个配置下已经不再需要的机密槽位
    /// （字段被删掉、或「机密」开关被取消）。
    ///
    /// 认证密钥（`secret`）由配置编辑器单独维护，不在 `UploaderProfile` 里，
    /// 每次都会被当成「多余槽位」，所以要显式排除在回收之外。
    static func sync(_ secrets: [String: String], forProfile id: UUID) {
        lock.lock(); defer { lock.unlock() }
        var store = loaded()
        var slots = store[id.uuidString] ?? [:]
        let authSecret = slots[SecretSlot.authSecret]
        slots = secrets.filter { !$0.value.isEmpty }
        slots[SecretSlot.authSecret] = authSecret
        store[id.uuidString] = slots.isEmpty ? nil : slots
        commit(store)
    }

    static func deleteAll(forProfile id: UUID) {
        lock.lock(); defer { lock.unlock() }
        var store = loaded()
        store.removeValue(forKey: id.uuidString)
        commit(store)
    }

    // MARK: - 汇总条目

    /// 调用前必须已持锁
    private static func loaded() -> [String: [String: String]] {
        if let cache { return cache }
        var store = readBlob() ?? [:]
        // 1.4.x 用过「一个槽位一条」的布局，遇到就并进来
        let merged = mergeLegacyItems(into: &store)
        cache = store
        // 删旧条目是单向的，所以不只看写入返回码 —— 回读一遍，
        // 确认汇总条目能解出来且内容对得上，才敢动旧的。对不上就留着，下次启动重来。
        if !merged.isEmpty, writeBlob(store), readBlob() == store {
            for account in merged { deleteItem(account: account) }
        }
        return store
    }

    /// 调用前必须已持锁。内容没变就不写 —— 配置编辑器每敲一个键都会存盘。
    private static func commit(_ store: [String: [String: String]]) {
        guard store != cache else { return }
        cache = store
        _ = writeBlob(store)
    }

    private static func readBlob() -> [String: [String: String]]? {
        guard let data = readItem(account: blobAccount) else { return nil }
        return try? JSONDecoder().decode([String: [String: String]].self, from: data)
    }

    @discardableResult
    private static func writeBlob(_ store: [String: [String: String]]) -> Bool {
        guard let data = try? JSONEncoder().encode(store) else { return false }
        return writeItem(data, account: blobAccount)
    }

    // MARK: - 老布局迁移

    /// 把 `<profileID>.<slot>` 那些独立条目并进汇总表，返回成功读到的 account。
    /// 读不出来的（比如用户点了「拒绝」）留着不动，下次启动再试，不静默丢密钥。
    private static func mergeLegacyItems(into store: inout [String: [String: String]]) -> [String] {
        var merged: [String] = []
        for account in allAccounts() where account != blobAccount {
            guard let dot = account.firstIndex(of: "."),
                  let id = UUID(uuidString: String(account[account.startIndex..<dot]))
            else { continue }
            let slot = String(account[account.index(after: dot)...])
            guard let data = readItem(account: account),
                  let value = String(data: data, encoding: .utf8), !value.isEmpty
            else { continue }
            // 汇总表里已有的优先，避免迁移重跑时把新值覆盖回旧值
            if store[id.uuidString]?[slot] == nil {
                store[id.uuidString, default: [:]][slot] = value
            }
            merged.append(account)
        }
        return merged
    }

    private static func allAccounts() -> [String] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll,
        ]
        var out: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &out) == errSecSuccess,
              let items = out as? [[String: Any]] else { return [] }
        return items.compactMap { $0[kSecAttrAccount as String] as? String }
    }

    // MARK: - 裸条目读写

    private static func readItem(account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var out: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &out) == errSecSuccess else { return nil }
        return out as? Data
    }

    private static func writeItem(_ data: Data, account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        let attrs: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        let status = SecItemUpdate(query as CFDictionary, attrs as CFDictionary)
        if status == errSecItemNotFound {
            var insert = query
            insert.merge(attrs) { a, _ in a }
            return SecItemAdd(insert as CFDictionary, nil) == errSecSuccess
        }
        return status == errSecSuccess
    }

    private static func deleteItem(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
