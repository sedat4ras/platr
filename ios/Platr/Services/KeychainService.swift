// Platr iOS — KeychainService
// [iOSSwiftAgent]
// Secure storage for JWT tokens using the iOS Keychain.
// Never store tokens in UserDefaults — Keychain only.

import Foundation
import Security

enum KeychainKey: String {
    case accessToken  = "platr.accessToken"
    case refreshToken = "platr.refreshToken"
    case userId       = "platr.userId"
}

final class KeychainService {
    static let shared = KeychainService()
    private init() {}

    // MARK: - Save

    @discardableResult
    func save(_ value: String, for key: KeychainKey) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        // Delete any existing item first
        delete(key)

        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String:   data,
            // Accessible only when device is unlocked; NOT backed up to iCloud
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    // MARK: - Read

    func read(_ key: KeychainKey) -> String? {
        let query: [String: Any] = [
            kSecClass as String:            kSecClassGenericPassword,
            kSecAttrAccount as String:      key.rawValue,
            kSecReturnData as String:       true,
            kSecMatchLimit as String:       kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8)
        else { return nil }

        return string
    }

    // MARK: - Delete

    @discardableResult
    func delete(_ key: KeychainKey) -> Bool {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }

    // MARK: - Clear all (logout)

    func clearAll() {
        KeychainKey.allCases.forEach { delete($0) }
    }
}

extension KeychainKey: CaseIterable {}
