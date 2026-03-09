//
//  MockAuthService.swift
//  KiwiCare
//
//  Created by Vincent Hu on 09/03/2026.
//

import Foundation

// MARK: - MockAuthService

/// A test double for `AuthServiceProtocol`.
/// Used in unit tests and SwiftUI `#Preview` blocks — never in production.
///
/// Usage:
/// ```swift
/// let mock = MockAuthService()
/// mock.shouldFail = true   // simulate failure
/// mock.stubbedUser = .mock // customise returned user
/// ```
#if DEBUG
final class MockAuthService: AuthServiceProtocol {

    // MARK: - Test Controls

    /// Set to `true` to simulate a network or auth failure.
    var shouldFail = false

    /// The user returned on any successful auth call.
    var stubbedUser: User = .mock

    // MARK: - Call Counters (assert in tests)

    private(set) var loginCallCount       = 0
    private(set) var registerCallCount    = 0
    private(set) var appleLoginCallCount  = 0

    // MARK: - AuthServiceProtocol

    func login(email: String, password: String) async throws -> AuthResponse {
        loginCallCount += 1
        if shouldFail { throw NetworkError.unauthorized }
        return AuthResponse(accessToken: "mock-token", user: stubbedUser)
    }

    func register(name: String, email: String, password: String, phone: String?) async throws -> AuthResponse {
        registerCallCount += 1
        if shouldFail { throw NetworkError.serverError(statusCode: 409, message: "Email already exists.") }
        return AuthResponse(accessToken: "mock-token", user: stubbedUser)
    }

    func loginWithApple(identityToken: String, fullName: String?) async throws -> AuthResponse {
        appleLoginCallCount += 1
        if shouldFail { throw NetworkError.unauthorized }
        return AuthResponse(accessToken: "mock-token", user: stubbedUser)
    }

    func fetchProfile() async throws -> User {
        if shouldFail { throw NetworkError.unauthorized }
        return stubbedUser
    }
}
#endif

// MARK: - User + Mock

extension User {
    /// A pre-built mock user for tests and SwiftUI previews.
    static let mock = User(
        id: "mock-id-001",
        email: "test@kiwicare.com",
        name: "Test User",
        phone: "+6421000000",
        balance: 100,
        avatar: nil,
        role: .customer
    )
}
