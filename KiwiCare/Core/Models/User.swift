//
//  User.swift
//  KiwiCare
//
//  Created by Vincent Hu on 09/03/2026.
//

import Foundation

// MARK: - User

/// Represents an authenticated user returned by the server.
/// Read-only value type — never mutate directly; go through the ViewModel.
struct User: Codable, Identifiable, Equatable {
    let id: String
    let email: String
    let name: String
    let phone: String?
    /// Stored as an integer on the backend. Tolerates a string representation
    /// (e.g. `"0"`) that some PostgreSQL drivers emit for numeric columns.
    let balance: Int?
    let avatar: String?
    /// `nil` when the backend excludes the field (e.g. via `@Exclude()`).
    let role: UserRole?

    // MARK: - Memberwise Init  (needed because we provide a custom Decodable init)

    init(
        id: String,
        email: String,
        name: String,
        phone: String? = nil,
        balance: Int? = nil,
        avatar: String? = nil,
        role: UserRole? = nil
    ) {
        self.id      = id
        self.email   = email
        self.name    = name
        self.phone   = phone
        self.balance = balance
        self.avatar  = avatar
        self.role    = role
    }

    // MARK: - CodingKeys

    private enum CodingKeys: String, CodingKey {
        case id, email, name, phone, balance, avatar, role
    }

    // MARK: - Decodable

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id      = try c.decode(String.self,              forKey: .id)
        email   = try c.decode(String.self,              forKey: .email)
        name    = try c.decode(String.self,              forKey: .name)
        phone   = try c.decodeIfPresent(String.self,     forKey: .phone)
        avatar  = try c.decodeIfPresent(String.self,     forKey: .avatar)
        role    = try c.decodeIfPresent(UserRole.self,   forKey: .role)

        // `balance` can arrive as a JSON number (0) or a JSON string ("0")
        // depending on the PostgreSQL driver / TypeORM version.
        if let intVal = try? c.decodeIfPresent(Int.self, forKey: .balance) {
            balance = intVal
        } else if let strVal = try? c.decodeIfPresent(String.self, forKey: .balance) {
            balance = Int(strVal)
        } else {
            balance = nil
        }
    }

    // MARK: - Encodable  (used when persisting to UserDefaults)

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,      forKey: .id)
        try c.encode(email,   forKey: .email)
        try c.encode(name,    forKey: .name)
        try c.encodeIfPresent(phone,   forKey: .phone)
        try c.encodeIfPresent(balance, forKey: .balance)
        try c.encodeIfPresent(avatar,  forKey: .avatar)
        try c.encodeIfPresent(role,    forKey: .role)
    }
}

// MARK: - UserRole

/// Must match the backend `UserRole` enum values exactly.
enum UserRole: String, Codable {
    case customer
    case provider
    case admin
}
