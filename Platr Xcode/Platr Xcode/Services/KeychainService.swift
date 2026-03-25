// Platr iOS — KeychainService
// nonisolated: Security framework C API'leri MainActor'e ihtiyaç duymaz

import Foundation
import Security

enum KeychainKey: String, CaseIterable {
    case accessToken  = "platr.accessToken"
    case refreshToken = "platr.refreshToken"
    case userId       = "platr.userId"
}

final class KeychainService: Sendable {
    static let shared = KeychainService()
    private init() {}

    // MARK: - Save

    @discardableResult
    nonisolated func save(_ value: String, for key: KeychainKey) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        delete(key)
        let query: [String: Any] = [
            kSecClass as String:          kSecClassGenericPassword,
            kSecAttrAccount as String:    key.rawValue,
            kSecValueData as String:      data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    // MARK: - Read

    nonisolated func read(_ key: KeychainKey) -> String? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8)
        else { return nil }
        return string
    }

    // MARK: - Delete

    @discardableResult
    nonisolated func delete(_ key: KeychainKey) -> Bool {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }

    // MARK: - Clear all

    nonisolated func clearAll() {
        KeychainKey.allCases.forEach { delete($0) }
    }
}
