//
//  ZBAPIError.swift
//  ZBNetworkKit
//
//  Created by Zuhaib Imtiaz on 02/03/2025.
//

import Foundation

public enum ZBAPIError: Error, Equatable {
    public struct ZBErrorModel: Equatable {
        var code: Int
        var message: String
        var response: HTTPURLResponse?
        var request: URLRequest?
    }
    case networkError(String)
    case unauthorized
    case invalidRequest
    case tokenRefreshFailed
    case sslPinningFailed
    case decodingError(String)
    case timeout
    case cancelled
    case custom(model: ZBErrorModel)
    
    public var localizedDescription: String {
        switch self {
        case .networkError(let message): return message
        case .unauthorized: return "Unauthorized access"
        case .invalidRequest: return "Invalid Request"
        case .tokenRefreshFailed: return "Failed to refresh token"
        case .sslPinningFailed: return "SSL pinning validation failed"
        case .decodingError(let message): return "Decoding error: \(message)"
        case .timeout: return "Time Out"
        case .cancelled: return "Request Cancelled"
        case .custom(let model): return model.message
        }
    }
}
