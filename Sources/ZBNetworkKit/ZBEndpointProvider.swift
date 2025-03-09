//
//  ZBEndpointProvider.swift
//  ZBNetworkKit
//
//  Created by Zuhaib Imtiaz on 02/03/2025.
//

import Foundation

public protocol ZBEndpointProvider {
    var scheme: String { get }
    var baseURL: String { get }
    var path: String { get }
    var method: RequestMethod { get }
    var queryItems: [URLQueryItem]? { get }
    var headers: [String: String]? { get }
    var parameters: [String: Any]? { get }
    var encodedParams: Encodable? { get }
    var multipart: ZBMultipartRequest? { get }
    var uploadData: Data? { get }
    var accessTokenRequired: Bool { get }
    var timeoutInterval: TimeInterval? { get }
    var interceptors: [ZBInterceptor] { get }
    var avoidAllInterceptor: Bool { get }
    func buildURLRequest() throws -> URLRequest
}

public enum RequestMethod: String {
    case DELETE, GET, PATCH, POST, PUT
}

public extension ZBEndpointProvider {
    var scheme: String { "https" }
    var baseURL: String { ZBNetworkConfiguration.shared.baseURL }
    var queryItems: [URLQueryItem]? { nil }
    var headers: [String: String]? { nil }
    var parameters: [String: Any]? { nil }
    var encodedParams: Encodable? { nil }
    var multipart: ZBMultipartRequest? { nil }
    var uploadData: Data? { nil }
    var accessTokenRequired: Bool { false }
    var timeoutInterval: TimeInterval? { 60 }
    var interceptors: [ZBInterceptor] {
        ZBNetworkConfiguration.shared.isLogging ? [ZBLoggingInterceptor()] : []
    }
    var avoidAllInterceptor: Bool { false }
    
    func buildURLRequest() throws -> URLRequest {
        var components = URLComponents()
        components.scheme = scheme
        components.host = baseURL
        components.path = path
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw ZBAPIError.invalidRequest
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = timeoutInterval ?? ZBNetworkConfiguration.shared.defaultTimeout

        
        self.configureHeaderFields(for: &request)
        try self.configureHTTPBody(for: &request)
        if !avoidAllInterceptor {
            self.interceptors.forEach { $0.onRequest(&request) }
        } else if ZBNetworkConfiguration.shared.isLogging {
            ZBLoggingInterceptor().onRequest(&request)
        }
        return request
    }
    
    private func configureHeaderFields(for request: inout URLRequest) {
        var combinedHeaders = ZBNetworkConfiguration.shared.defaultHeaders
        if let customHeaders = headers {
            combinedHeaders?.merge(customHeaders) { (_, new) in new }
        }
        
        combinedHeaders?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        // Add Authorization header if required
        if accessTokenRequired,
            let token = ZBTokenManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }
    
    private func configureHTTPBody(for request: inout URLRequest) throws {
        if let multipart = multipart {
            request.setValue(multipart.headerValue, forHTTPHeaderField: "Content-Type")
            request.setValue("\(multipart.length)", forHTTPHeaderField: "Content-Length")
            request.httpBody = multipart.httpBody
        } else if let params = parameters {
            request.httpBody = try JSONSerialization.data(withJSONObject: params)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type") // Ensure Content-Type if not set
        } else if let encoded = encodedParams {
            request.httpBody = try JSONEncoder().encode(encoded)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        } else if let uploadData = uploadData {
            request.httpBody = uploadData
            request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        }
    }
}
