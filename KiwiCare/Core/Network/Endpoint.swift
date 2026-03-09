//
//  Endpoint.swift
//  KiwiCare
//
//  Created by Vincent Hu on 09/03/2026.
//

import Foundation

// MARK: - EndpointType

/// Contract every API endpoint must satisfy.
///
/// Each feature creates its own enum that conforms to this protocol,
/// carrying the request body as an associated value — so path, method,
/// body, and auth requirement are all in one place.
///
/// Usage:
/// ```swift
/// let endpoint = AuthEndpoint.login(LoginRequest(email: email, password: password))
/// let response: AuthResponse = try await apiClient.request(endpoint)
/// ```
protocol EndpointType {
    /// Path component appended to `APIConfig.baseURL`, e.g. `"/auth/login/mobile"`.
    var path: String { get }

    /// HTTP method for this request.
    var method: HTTPMethod { get }

    /// Optional JSON body. `nil` for requests that carry no body.
    var body: (any Encodable)? { get }

    /// Whether to attach the `Authorization: Bearer <token>` header.
    var requiresAuth: Bool { get }
}

// MARK: - APIConfig

/// Build-time API configuration.
/// `API_BASE_URL` is injected via xcconfig → Info.plist at build time.
enum APIConfig {
    static var baseURL: String {
        let base = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String
            ?? "http://192.168.88.7:9080"
        return "\(base)/api"
    }
}
