//
//  ZBAPIError.swift
//  ZBNetworkKit
//
//  Created by Zuhaib Imtiaz on 02/03/2025.
//

import Foundation

// Defines a public enum `APIError` that conforms to the `Error` protocol for use in error handling
// and `Equatable` protocol to allow comparison between `APIError` instances.
public enum ZBAPIError: Error, Equatable {
    
    // A nested struct `ErrorModel` to encapsulate detailed error information.
    // Conforms to `Equatable` for comparison and `Sendable` for safe use in concurrent contexts (e.g., Swift concurrency).
    public struct ZBErrorModel: Equatable, Sendable {
        // The error code, typically an HTTP status code or custom code.
        var code: Int
        // A human-readable message describing the error.
        var message: String
        // Optional `HTTPURLResponse` to store the HTTP response associated with the error, if any.
        var response: HTTPURLResponse?
        // Optional `URLRequest` to store the request that caused the error, if any.
        var request: URLRequest?
        
        public init(
            code: Int,
            message: String,
            response: HTTPURLResponse? = nil,
            request: URLRequest? = nil
        ) {
            self.code = code
            self.message = message
            self.response = response
            self.request = request
        }
    }
    
    // Enum cases representing specific error scenarios that may occur during API interactions.
    
    // Represents a network-related error with a descriptive message.
    case networkError(String)
    
    // Indicates an unauthorized access error (e.g., HTTP 401).
    case unauthorized
    
    // Indicates an invalid request error (e.g., HTTP 400).
    case invalidRequest
    
    // Indicates an invalid response error .
    case invalidResponse
    
    // Indicates failure to refresh an authentication token.
    case tokenRefreshFailed
    
    // Indicates failure in SSL pinning validation for secure connections.
    case sslPinningFailed
    
    // Represents a decoding error (e.g., JSON parsing failure) with a descriptive message.
    case decodingError(String)
    
    // Indicates a timeout error when the request exceeds the allowed time.
    case timeout
    
    // Indicates the request was cancelled before completion.
    case cancelled
    

    case noData
    
    case noURL
    
    // A custom error case that uses the `ErrorModel` struct to provide detailed error information.
    case custom(model: ZBErrorModel)
    
    // A computed property that provides a human-readable description of the error.
    // Conforms to the `Error` protocol's `localizedDescription` requirement.
    public var localizedDescription: String {
        // Uses a switch statement to handle each enum case and return an appropriate description.
        switch self {
        // For `networkError`, returns the associated message.
        case .networkError(let message):
            return message
            
        // For `unauthorized`, returns a static string indicating unauthorized access.
        case .unauthorized:
            return "Unauthorized access"
            
        // For `invalidRequest`, returns a static string indicating an invalid request.
        case .invalidRequest:
            return "Invalid Request"
            
        // For `tokenRefreshFailed`, returns a static string indicating token refresh failure.
        case .tokenRefreshFailed:
            return "Failed to refresh token"
            
        // For `sslPinningFailed`, returns a static string indicating SSL pinning failure.
        case .sslPinningFailed:
            return "SSL pinning validation failed"
            
        // For `decodingError`, includes the associated message in the description.
        case .decodingError(let message):
            return "Decoding error: \(message)"
            
        // For `timeout`, returns a static string indicating a timeout.
        case .timeout:
            return "Time Out"
            
        // For `cancelled`, returns a static string indicating the request was cancelled.
        case .cancelled:
            return "Request Cancelled"
            
        // For `custom`, returns the message from the associated `ErrorModel`.
        case .custom(let model):
            return model.message
        
        case .invalidResponse:
            return "Invalid Response"

        case .noData:
            return "No Data"

        case .noURL:
            return "No URL"

        }
    }
}
