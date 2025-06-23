//
//  MockHttpClient.swift
//  ZBNetworkKit
//
//  Created by Zuhaib Imtiaz on 6/23/25.
//

import Foundation

final public class MockHttpClient: NSObject, ZBNetworkClientProtocol, @unchecked Sendable  {
    
    let error: ZBAPIError?
    let response: Decodable?
    let downloadedURL: URL?
    let downloadedData: Data?
    var interceptors: [ZBInterceptor] = []
    
    public init(error: ZBAPIError? = nil,
         response: Decodable? = nil,
         downloadedURL: URL? = nil,
         downloadedData: Data? = nil
    ) {
        self.error = error
        self.response = response
        self.downloadedURL = downloadedURL
        self.downloadedData = downloadedData
    }
    
    public func asyncRequest<T>(endpoint: any ZBEndpointProvider, responseModel: T.Type) async throws -> T where T : Decodable {
        if let error {
            throw error
        }
        guard let response = response as? T else {
            throw ZBAPIError.invalidRequest
        }
        
        return response
    }
    
    public func asyncUpload<T>(endpoint: any ZBEndpointProvider, responseModel: T.Type) async throws -> T where T : Decodable {
        if let error {
            throw error
        }
        
        guard let response = response as? T else {
            throw ZBAPIError.invalidRequest
        }
        
        return response
    }
    
    public func downloadFile(endpoint: any ZBEndpointProvider) async throws -> Data {
        if let error {
            throw error
        }
        guard let downloadedData else {
            throw ZBAPIError.noData
        }
        
        return downloadedData
    }
    
    public func download(endpoint: any ZBEndpointProvider, progressHandler: @escaping @Sendable (Double) -> Void) async throws -> URL {
        if let error {
            throw error
        }
        guard let downloadedURL else {
            throw ZBAPIError.noURL
        }
        return downloadedURL
    }
    
    public func upload<T: Decodable>(
            endpoint: any ZBEndpointProvider,
            responseModel: T.Type,
            progressHandler: @Sendable @escaping (Double) -> Void
    ) async throws -> T {
        var request = try endpoint.buildURLRequest()
        try interceptors.forEach { try $0.onRequest(&request) }
        
        if let error {
            throw error
        }
       
        guard let response = response as? T else {
            throw ZBAPIError.invalidRequest
        }
        progressHandler(1.0) // Simulate completion
        return response
    }
    
    public func addInterceptor(_ interceptor: any ZBInterceptor) {
        
    }
    
}
