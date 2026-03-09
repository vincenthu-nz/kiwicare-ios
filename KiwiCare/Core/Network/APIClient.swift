//
//  APIClient.swift
//  KiwiCare
//
//  Created by Vincent Hu on 09/03/2026.
//

import Foundation

// MARK: - APIClient

/// A lightweight HTTP client built on URLSession with async/await support.
///
/// Design goals:
/// - No third-party dependencies — pure URLSession
/// - URLSession is injected so tests can swap in a mock session
/// - JWT is read from Keychain (never UserDefaults)
/// - Snake_case ↔ camelCase conversion handled automatically
/// - Accepts any `EndpointType`, keeping all request metadata in one place
final class APIClient {

    // MARK: - Singleton

    static let shared = APIClient()

    // MARK: - Private Properties

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    // MARK: - Init

    /// - Parameter session: Defaults to `.shared`; inject a mock session for unit tests.
    init(session: URLSession = .shared) {
        self.session = session

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy  = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder = encoder
    }

    // MARK: - Public Methods

    /// Performs a request described by an `EndpointType` and decodes the JSON response into `T`.
    ///
    /// - Parameter endpoint: Any value conforming to `EndpointType` (e.g. `AuthEndpoint.login(...)`).
    /// - Returns: Decoded value of type `T`.
    /// - Throws: `NetworkError`
    func request<T: Decodable>(_ endpoint: some EndpointType) async throws -> T {
        let urlRequest = try buildRequest(from: endpoint)
        return try await execute(urlRequest)
    }

    /// Performs a request that returns no response body (e.g. DELETE).
    func requestVoid(_ endpoint: some EndpointType) async throws {
        let urlRequest = try buildRequest(from: endpoint)
        let (data, response) = try await session.data(for: urlRequest)
        try validate(response: response, data: data)
    }
}

// MARK: - Private Helpers

private extension APIClient {

    func buildRequest(from endpoint: some EndpointType) throws -> URLRequest {
        guard let url = URL(string: APIConfig.baseURL + endpoint.path) else {
            throw NetworkError.invalidURL
        }

        var request        = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Attach Bearer token from Keychain — NEVER from UserDefaults
        if endpoint.requiresAuth, let token = KeychainService.shared.retrieveToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = endpoint.body {
            request.httpBody = try encoder.encode(body)
        }

        return request
    }

    func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)

        #if DEBUG
        if let raw = String(data: data, encoding: .utf8) {
            print("📦 [APIClient] raw response:\n\(raw)")
        }
        #endif

        // Try decoding with the standard { data, code, msg } envelope first.
        // If the envelope itself is missing (e.g. the route bypasses TransformInterceptor),
        // fall back to decoding T directly so we get a more useful error.
        do {
            return try decoder.decode(APIEnvelope<T>.self, from: data).data
        } catch let envelopeError {
            #if DEBUG
            print("⚠️ [APIClient] envelope decode failed, trying direct decode — \(Self.describe(envelopeError))")
            #endif

            do {
                return try decoder.decode(T.self, from: data)
            } catch let directError {
                #if DEBUG
                print("❌ [APIClient] direct decode also failed for \(T.self) — \(Self.describe(directError))")
                #endif
                // Surface the envelope error (the primary path) to the caller.
                throw NetworkError.decodingFailed(envelopeError)
            }
        }
    }

    #if DEBUG
    /// Converts a `DecodingError` into a short, human-readable string showing
    /// the failing key path and the reason, so you don't have to parse the
    /// default verbose description in the console.
    private static func describe(_ error: Error) -> String {
        guard let de = error as? DecodingError else { return error.localizedDescription }
        switch de {
        case .keyNotFound(let key, let ctx):
            let path = ctx.codingPath.map(\.stringValue).joined(separator: ".")
            return "keyNotFound: '\(key.stringValue)' at path '\(path.isEmpty ? "<root>" : path)'"
        case .typeMismatch(let type, let ctx):
            let path = ctx.codingPath.map(\.stringValue).joined(separator: ".")
            return "typeMismatch: expected \(type) at path '\(path.isEmpty ? "<root>" : path)' — \(ctx.debugDescription)"
        case .valueNotFound(let type, let ctx):
            let path = ctx.codingPath.map(\.stringValue).joined(separator: ".")
            return "valueNotFound: \(type) at path '\(path.isEmpty ? "<root>" : path)'"
        case .dataCorrupted(let ctx):
            return "dataCorrupted: \(ctx.debugDescription)"
        @unknown default:
            return error.localizedDescription
        }
    }
    #endif

    func validate(response: URLResponse, data: Data?) throws {
        guard let http = response as? HTTPURLResponse else { return }

        switch http.statusCode {
        case 200...299:
            return
        case 401:
            // Clear the stored token on 401 so the user is forced to re-authenticate
            KeychainService.shared.deleteToken()
            throw NetworkError.unauthorized
        default:
            // Attempt to extract the server-side error message from the response body
            var message: String?
            if let data,
               let body = try? JSONDecoder().decode(ServerErrorBody.self, from: data) {
                message = body.message
            }
            throw NetworkError.serverError(statusCode: http.statusCode, message: message)
        }
    }
}

// MARK: - Supporting Types

/// Generic API response wrapper returned by backend services.
/// Example response format:
/// {
///   "code": 0,
///   "msg": "success",
///   "data": T
/// }
///
/// The actual payload is contained in the `data` field.
private struct APIEnvelope<T: Decodable>: Decodable {
    let data: T
}

/// Maps the backend default error response shape.
private struct ServerErrorBody: Decodable {
    let message: String?
    let statusCode: Int?
}
