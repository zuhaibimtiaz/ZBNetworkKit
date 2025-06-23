//
//  ZBEndpointProvider.swift
//  ZBNetworkKit
//
//  Created by Zuhaib Imtiaz on 02/03/2025.
//

import Foundation

/// A protocol defining the properties required to construct an API request.
/// Conforming types provide details such as scheme, base URL, HTTP method, and optional parameters.
public protocol ZBEndpointProvider {
    /// The URL scheme for the request (e.g., "https").
    var scheme: String { get }
    
    /// The base URL for the API (e.g., "api.example.com").
    var baseURL: String { get }
    
    /// The path component of the URL (e.g., "/users").
    var path: String { get }
    
    /// The HTTP method for the request (e.g., GET, POST).
    var method: RequestMethod { get }
    
    /// Optional query items to append to the URL.
    var queryItems: [URLQueryItem]? { get }
    
    /// Optional HTTP headers to include in the request.
    var headers: [String: String]? { get }
    
    /// Optional dictionary of parameters to include in the request body.
    var parameters: [String: Any]? { get }
    
    /// Optional Encodable object to encode as the request body.
    var encodedParams: Encodable? { get }
    
    /// Optional multipart form data for the request.
    var multipart: ZBMultipartRequest? { get }
    
    /// Optional raw data to upload in the request body.
    var uploadData: Data? { get }
    
    /// Indicates whether an access token is required for the request.
    var accessTokenRequired: Bool { get }
    
    /// Optional timeout interval for the request in seconds.
    var timeoutInterval: TimeInterval? { get }
    
    /// Interceptors to modify the request before it is sent.
    var interceptors: [ZBInterceptor] { get }
    
    /// Indicates whether to bypass all interceptors except logging (if enabled).
    var avoidAllInterceptor: Bool { get }
}

/// An enum representing HTTP methods used in API requests.
/// Uses raw `String` values for direct mapping to HTTP method names.
public enum RequestMethod: String {
    case DELETE, GET, PATCH, POST, PUT
}

/// Default implementation of the `EndpointProvider` protocol, providing default values and the `buildURLRequest` method.
public extension ZBEndpointProvider {
    /// The default URL scheme for requests.
    var scheme: String { "https" }
    
    /// The default base URL, retrieved from shared `NetworkConfiguration`.
    var baseURL: String { ZBNetworkConfiguration.shared.baseURL }
    
    /// Default query items (none).
    var queryItems: [URLQueryItem]? { nil }
    
    /// Default headers (none).
    var headers: [String: String]? { nil }
    
    /// Default parameters (none).
    var parameters: [String: Any]? { nil }
    
    /// Default Encodable parameters (none).
    var encodedParams: Encodable? { nil }
    
    /// Default multipart form data (none).
    var multipart: ZBMultipartRequest? { nil }
    
    /// Default upload data (none).
    var uploadData: Data? { nil }
    
    /// Default access token requirement (false).
    var accessTokenRequired: Bool { false }
    
    /// Default timeout interval (60 seconds).
    var timeoutInterval: TimeInterval? { 60 }
    
    /// Default interceptors, including `LoggingInterceptor` if logging is enabled in `NetworkConfiguration`.
    var interceptors: [ZBInterceptor] {
        ZBNetworkConfiguration.shared.isLogging ? [ZBLoggingInterceptor()] : []
    }
    
    /// Default interceptor bypass setting (false, meaning interceptors are applied).
    var avoidAllInterceptor: Bool { false }
    
    /// Constructs a `URLRequest` based on the properties of the conforming type.
    /// - Returns: A configured `URLRequest` ready for network execution.
    /// - Throws: `APIError.invalidRequest` if the URL cannot be constructed.
    func buildURLRequest() throws -> URLRequest {
        // Initialize URL components with scheme, host, path, and query items.
        var components = URLComponents()
        components.scheme = scheme
        components.host = baseURL
        components.path = path
        components.queryItems = queryItems
        
        // Ensure the URL is valid, otherwise throw an error.
        guard let url = components.url else {
            throw ZBAPIError.invalidRequest
        }
        
        // Create the URLRequest with the constructed URL and HTTP method.
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        // Set timeout interval, falling back to default from `NetworkConfiguration`.
        request.timeoutInterval = timeoutInterval ?? ZBNetworkConfiguration.shared.defaultTimeout
        
        // Configure headers and body for the request.
        self.configureHeaderFields(for: &request)
        try self.configureHTTPBody(for: &request)
        
        // Apply interceptors to modify the request, unless bypassed.
        if !avoidAllInterceptor {
            try self.interceptors.forEach { try $0.onRequest(&request) }
        }
        if !avoidAllInterceptor,
           ZBNetworkConfiguration.shared.isLogging {
            try ZBLoggingInterceptor().onRequest(&request)
        }
        
        return request
    }
    
    /// Configures the header fields for the given `URLRequest`.
    /// - Parameter request: The `URLRequest` to configure (passed as inout).
    private func configureHeaderFields(for request: inout URLRequest) {
        // Start with default headers from `NetworkConfiguration`.
        var combinedHeaders = ZBNetworkConfiguration.shared.defaultHeaders
        // Merge custom headers, prioritizing custom values in case of conflicts.
        if let customHeaders = headers {
            combinedHeaders?.merge(customHeaders) { (_, new) in new }
        }
        
        // Apply all headers to the request.
        combinedHeaders?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        // Add Authorization header with Bearer token if required and available.
        if accessTokenRequired,
           let token = ZBTokenManager.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }
    
    /// Configures the HTTP body for the given `URLRequest` based on parameters, encoded params, multipart, or upload data.
    /// - Parameter request: The `URLRequest` to configure (passed as inout).
    /// - Throws: An error if JSON serialization or encoding fails.
    private func configureHTTPBody(for request: inout URLRequest) throws {
        if let multipart = multipart {
            // Configure multipart form data with appropriate headers and body.
            request.setValue(multipart.headerValue, forHTTPHeaderField: "Content-Type")
            request.setValue("\(multipart.length)", forHTTPHeaderField: "Content-Length")
            request.httpBody = multipart.httpBody
        } else if let params = parameters {
            // Serialize dictionary parameters to JSON and set Content-Type.
            request.httpBody = try JSONSerialization.data(withJSONObject: params)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        } else if let encoded = encodedParams {
            // Encode Encodable object to JSON and set Content-Type.
            request.httpBody = try JSONEncoder().encode(encoded)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        } else if let uploadData = uploadData {
            // Set raw upload data and Content-Type for binary data.
            request.httpBody = uploadData
            request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        }
    }
}
