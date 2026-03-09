//
//  NetworkError.swift
//  KiwiCare
//
//  Created by Vincent Hu on 09/03/2026.
//

import Foundation

// MARK: - NetworkError

/// All possible errors that can be thrown by the network layer.
enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case decodingFailed(Error)
    case serverError(statusCode: Int, message: String?)
    case unauthorized
    case unknown(Error)

    // MARK: LocalizedError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL."
        case .noData:
            return "No data received from server."
        case .decodingFailed(let err):
            return "Decoding error: \(err.localizedDescription)"
        case .serverError(let code, let msg):
            return msg ?? "Server error (\(code))."
        case .unauthorized:
            return "Session expired. Please log in again."
        case .unknown(let err):
            return err.localizedDescription
        }
    }
}
