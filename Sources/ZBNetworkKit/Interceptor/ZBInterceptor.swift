//
//  ZBInterceptor.swift
//  ZBNetworkKit
//
//  Created by Zuhaib Imtiaz on 09/03/2025.
//
import Foundation

/// A protocol defining methods for intercepting and modifying HTTP requests and responses.
/// Implementers can modify requests before they are sent and responses before they are processed.
public protocol ZBInterceptor {
    
    /// Modifies the URL request before it is sent.
    /// - Parameter request: The `URLRequest` to modify (passed as inout).
    func onRequest(_ request: inout URLRequest) throws
    
    /// Modifies the response data and handles the response or error after the request is completed.
    /// - Parameters:
    ///   - data: The response data to modify (passed as inout).
    ///   - response: The `URLResponse` received from the request, if any.
    ///   - error: The `Error` encountered during the request, if any.
    func onResponse(_ data: inout Data, _ response: URLResponse?, _ error: Error?) throws
}

/// Default implementation of the `Interceptor` protocol, providing no-op (no operation) behavior.
public extension ZBInterceptor {
    
    /// Default implementation for modifying the URL request (does nothing).
    /// - Parameter request: The `URLRequest` to modify (passed as inout).
    func onRequest(_ request: inout URLRequest) throws {
        // No-op by default: no modifications are made to the request.
    }
    
    /// Default implementation for modifying the response data (does nothing).
    /// - Parameters:
    ///   - data: The response data to modify (passed as inout).
    ///   - response: The `URLResponse` received from the request, if any.
    ///   - error: The `Error` encountered during the request, if any.
    func onResponse(_ data: inout Data, _ response: URLResponse?, _ error: Error?) throws {
        // No-op by default: no modifications are made to the response data.
    }
}
