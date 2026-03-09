//
//  AuthEndpoint.swift
//  KiwiCare
//
//  Created by Vincent Hu on 09/03/2026.
//

import Foundation

// MARK: - AuthEndpoint

/// All authentication-related API endpoints.
///
/// Each case carries its request body as an associated value, so every
/// piece of information needed to fire the request lives in one enum case.
///
/// ```swift
/// // In AuthService:
/// let response: AuthResponse = try await apiClient.request(
///     AuthEndpoint.login(LoginRequest(email: email, password: password))
/// )
/// ```
enum AuthEndpoint: EndpointType {
    case login(LoginRequest)
    case register(RegisterRequest)
    case loginWithApple(AppleLoginRequest)
    case profile

    // MARK: - EndpointType

    var path: String {
        switch self {
        case .login:          return "/auth/login/mobile"
        case .register:       return "/auth/register/mobile"
        case .loginWithApple: return "/auth/login/apple"
        case .profile:        return "/auth/profile"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .login, .register, .loginWithApple: return .post
        case .profile:                           return .get
        }
    }

    var body: (any Encodable)? {
        switch self {
        case .login(let req):          return req
        case .register(let req):       return req
        case .loginWithApple(let req): return req
        case .profile:                 return nil
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .profile: return true
        default:       return false
        }
    }
}
