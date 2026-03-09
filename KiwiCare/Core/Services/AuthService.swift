//
//  AuthService.swift
//  KiwiCare
//
//  Created by Vincent Hu on 09/03/2026.
//

import Foundation

// MARK: - AuthService

/// Concrete implementation of `AuthServiceProtocol`.
/// - JWT token  → stored in Keychain (sensitive, never in UserDefaults)
/// - User profile → stored in UserDefaults as JSON for fast cold-start restoration.
///   The full `User` value is cached (id, name, email, phone, balance, avatar, role).
///   Do not store raw passwords or tokens here.
final class AuthService: AuthServiceProtocol {

    // MARK: - Dependencies

    private let apiClient: APIClient
    private let keychainService: KeychainService

    // MARK: - Private Constants

    private let userDefaultsKey = "com.kiwicare.currentUser"

    // MARK: - Init

    init(
        apiClient: APIClient = .shared,
        keychainService: KeychainService = .shared
    ) {
        self.apiClient = apiClient
        self.keychainService = keychainService
    }

    // MARK: - AuthServiceProtocol

    func login(email: String, password: String) async throws -> AuthResponse {
        try AuthValidator.validateLogin(email: email, password: password)
        let response: AuthResponse = try await apiClient.request(
            AuthEndpoint.login(LoginRequest(email: email, password: password))
        )
        persist(response)
        return response
    }

    func register(name: String, email: String, password: String, phone: String?) async throws -> AuthResponse {
        try AuthValidator.validateRegister(name: name, email: email, password: password)
        let response: AuthResponse = try await apiClient.request(
            AuthEndpoint.register(RegisterRequest(email: email, password: password, name: name, phone: phone))
        )
        persist(response)
        return response
    }

    func loginWithApple(identityToken: String, fullName: String?) async throws -> AuthResponse {
        let response: AuthResponse = try await apiClient.request(
            AuthEndpoint.loginWithApple(AppleLoginRequest(identityToken: identityToken, fullName: fullName))
        )
        persist(response)
        return response
    }

    func fetchProfile() async throws -> User {
        let user: User = try await apiClient.request(AuthEndpoint.profile)
        saveUser(user)
        return user
    }

    /// Restores the last saved user from UserDefaults, or `nil` if not found.
    /// Uses a plain `JSONDecoder` (no `.convertFromSnakeCase` strategy) because the data
    /// was written by our own `JSONEncoder` using explicit `CodingKeys` — keys are already
    /// in the exact format expected by `User.init(from:)`.
    func loadSavedUser() -> User? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return nil }
        return try? JSONDecoder().decode(User.self, from: data)
    }

    /// Removes both the token and the stored user (called on logout).
    func clearSession() {
        keychainService.deleteToken()
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}

// MARK: - Private Helpers

private extension AuthService {

    /// Saves the token to Keychain and the user profile to UserDefaults.
    func persist(_ response: AuthResponse) {
        keychainService.saveToken(response.accessToken)
        saveUser(response.user)
    }

    /// Encodes and stores the full `User` value in UserDefaults.
    /// Sensitive data (password, tokens) is never part of `User`, so this is safe.
    func saveUser(_ user: User) {
        guard let data = try? JSONEncoder().encode(user) else { return }
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }
}
