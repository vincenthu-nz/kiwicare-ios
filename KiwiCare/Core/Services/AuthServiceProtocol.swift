//
//  AuthServiceProtocol.swift
//  KiwiCare
//
//  Created by Vincent Hu on 09/03/2026.
//

import Foundation

// MARK: - AuthServiceProtocol

/// Defines the contract for all authentication operations.
///
/// ViewModels depend on this protocol (not on the concrete `AuthService`),
/// which makes it straightforward to inject a `MockAuthService` in tests and previews.
protocol AuthServiceProtocol {

    /// Authenticates a user with email and password.
    func login(email: String, password: String) async throws -> AuthResponse

    /// Creates a new user account.
    func register(name: String, email: String, password: String, phone: String?) async throws -> AuthResponse

    /// Authenticates or registers a user via Apple Sign In identity token.
    func loginWithApple(identityToken: String, fullName: String?) async throws -> AuthResponse

    /// Fetches the currently authenticated user's profile.
    func fetchProfile() async throws -> User
}
