//
//  AuthValidator.swift
//  KiwiCare
//
//  Created by Vincent Hu on 09/03/2026.
//

import Foundation

// MARK: - ValidationError

/// Client-side validation errors thrown before any network request is made.
enum ValidationError: LocalizedError {
    case emptyName
    case emptyEmail
    case invalidEmail
    case shortPassword

    var errorDescription: String? {
        switch self {
        case .emptyName:       return "Name cannot be empty."
        case .emptyEmail:      return "Email cannot be empty."
        case .invalidEmail:    return "Please enter a valid email address."
        case .shortPassword:   return "Password must be at least 8 characters."
        }
    }
}

// MARK: - AuthValidator

/// Stateless validator for authentication input.
/// Called by `AuthService` before making any network request.
enum AuthValidator {

    /// Validates email and password for login.
    static func validateLogin(email: String, password: String) throws {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty       else { throw ValidationError.emptyEmail }
        guard trimmed.contains("@") else { throw ValidationError.invalidEmail }
        guard password.count >= 8   else { throw ValidationError.shortPassword }
    }

    /// Validates all fields for registration.
    static func validateRegister(name: String, email: String, password: String) throws {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ValidationError.emptyName
        }
        try validateLogin(email: email, password: password)
    }
}
