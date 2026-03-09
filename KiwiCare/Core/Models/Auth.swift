//
//  Auth.swift
//  KiwiCare
//
//  Created by Vincent Hu on 09/03/2026.
//

import Foundation

// MARK: - Request Models

/// Payload for POST /auth/login
struct LoginRequest: Encodable {
    let email: String
    let password: String
}

/// Payload for POST /auth/register/mobile
struct RegisterRequest: Encodable {
    let email: String
    let password: String
    let name: String
    let phone: String?
}

/// Payload for POST /auth/login/apple
struct AppleLoginRequest: Encodable {
    let identityToken: String
    let fullName: String?
}

// MARK: - Response Models

/// Returned by login and register endpoints.
struct AuthResponse: Decodable {
    let accessToken: String
    let user: User
}
