//
//  AuthViewModel.swift
//  KiwiCare
//
//  Created by Vincent Hu on 09/03/2026.
//

import Foundation
import AuthenticationServices
import Combine

// MARK: - AuthViewModel

/// Manages authentication state and coordinates login / register operations.
///
/// Architecture notes:
/// - Depends on `AuthServiceProtocol`, not the concrete `AuthService`, enabling mock injection
/// - All published state is updated on the `@MainActor` to keep UI updates on the main thread
/// - Passwords are NEVER stored; they are passed directly to the service and discarded
@MainActor
final class AuthViewModel: ObservableObject {

    // MARK: - Published State

    /// The currently authenticated user, or `nil` if not logged in.
    @Published private(set) var currentUser: User?

    /// `true` while a network request is in flight.
    @Published private(set) var isLoading = false

    /// Holds a user-facing error message when an operation fails.
    @Published var errorMessage: String?

    /// `true` once the user has a valid session token.
    @Published private(set) var isAuthenticated: Bool

    // MARK: - Dependencies

    private let authService: any AuthServiceProtocol
    private let keychainService: KeychainService

    // MARK: - Init

    /// - Parameters:
    ///   - authService: Pass `nil` to use the real `AuthService`; inject `MockAuthService` in tests.
    ///   - keychainService: Defaults to the shared singleton.
    ///
    /// Default values are resolved inside the body (not as parameter defaults) to satisfy
    /// Swift 6 `@MainActor` isolation requirements.
    init(
        authService: (any AuthServiceProtocol)? = nil,
        keychainService: KeychainService? = nil
    ) {
        let keychain          = keychainService ?? .shared
        let service           = authService ?? AuthService()
        self.authService      = service
        self.keychainService  = keychain
        self.isAuthenticated  = keychain.hasToken
        // Restore cached user profile from UserDefaults so UI is
        // populated immediately without an extra network call
        self.currentUser = (service as? AuthService)?.loadSavedUser()
    }

    // MARK: - Public Methods

    /// Authenticates with email and password.
    ///
    /// Runs `AuthValidator.validateLogin` before making any network call so that
    /// validation errors are surfaced even when a `MockAuthService` is injected.
    func login(email: String, password: String) async {
        await perform {
            try AuthValidator.validateLogin(email: email, password: password)
            let response = try await self.authService.login(email: email, password: password)
            self.handleAuthSuccess(response)
        }
    }

    /// Creates a new user account.
    ///
    /// Runs `AuthValidator.validateRegister` before making any network call.
    func register(name: String, email: String, password: String, phone: String?) async {
        await perform {
            try AuthValidator.validateRegister(name: name, email: email, password: password)
            let response = try await self.authService.register(
                name: name,
                email: email,
                password: password,
                phone: phone
            )
            self.handleAuthSuccess(response)
        }
    }

    /// Handles the Apple Sign In credential returned by `ASAuthorizationController`.
    /// The identity token is forwarded to the backend; the raw token is never persisted locally.
    func loginWithApple(credential: ASAuthorizationAppleIDCredential) async {
        guard let tokenData = credential.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8)
        else {
            errorMessage = "Failed to read Apple identity token."
            return
        }

        let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")

        await perform {
            let response = try await self.authService.loginWithApple(
                identityToken: identityToken,
                fullName: fullName.isEmpty ? nil : fullName
            )
            self.handleAuthSuccess(response)
        }
    }

    /// Clears the session — removes token from Keychain and resets all state.
    func logout() {
        (authService as? AuthService)?.clearSession()
        keychainService.deleteToken() // fallback for mock service in tests
        currentUser     = nil
        isAuthenticated = false
    }

    /// Clears the current error message (called after the user dismisses an alert).
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Private Helpers

private extension AuthViewModel {

    /// Wraps an async throwing operation with loading state and unified error handling.
    func perform(_ work: @escaping () async throws -> Void) async {
        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await work()
        } catch let error as ValidationError {
            // Client-side validation errors from AuthValidator (no network call was made)
            errorMessage = error.errorDescription
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Persists the token and updates published state after a successful auth call.
    func handleAuthSuccess(_ response: AuthResponse) {
        currentUser     = response.user
        isAuthenticated = true
    }
}
