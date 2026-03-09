//
//  HTTPMethod.swift
//  KiwiCare
//
//  Created by Vincent Hu on 09/03/2026.
//

import Foundation

// MARK: - HTTPMethod

/// Strongly-typed HTTP methods used by APIClient.
/// Avoids raw string literals scattered across the codebase.
enum HTTPMethod: String {
    case get    = "GET"
    case post   = "POST"
    case put    = "PUT"
    case patch  = "PATCH"
    case delete = "DELETE"
}
