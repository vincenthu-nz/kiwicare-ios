//
//  KeychainService.swift
//  KiwiCare
//
//  Created by Vincent Hu on 09/03/2026.
//

import Foundation
import Security

// MARK: - KeychainService

/// Manages secure storage of the JWT access token using the iOS Keychain.
///
/// Security rules:
/// - Tokens MUST be stored here, never in UserDefaults or any plaintext store
/// - `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` prevents iCloud backup exposure
final class KeychainService {

    // MARK: - Singleton

    static let shared = KeychainService()
    private init() {}

    // MARK: - Private Constants

    private let tokenKey = "com.kiwicare.accessToken"

    // MARK: - Public Interface

    /// Returns `true` if a token is currently stored.
    var hasToken: Bool { retrieveToken() != nil }

    /// Saves the JWT token to the Keychain.
    /// Replaces any previously stored token automatically.
    @discardableResult
    func saveToken(_ token: String) -> Bool {
        deleteToken() // remove existing entry before writing

        guard let data = token.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String:          kSecClassGenericPassword,
            kSecAttrAccount as String:    tokenKey,
            kSecValueData as String:      data,
            // Only accessible while the device is unlocked; excluded from backups
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    /// Retrieves the stored JWT token, or `nil` if none exists.
    func retrieveToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data  = result as? Data,
              let token = String(data: data, encoding: .utf8)
        else { return nil }

        return token
    }

    /// Deletes the stored token. Called on logout or when a 401 is received.
    @discardableResult
    func deleteToken() -> Bool {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
