//
//  ZBNetworkClientProtocol.swift
//  ZBNetworkKit
//
//  Created by Zuhaib Imtiaz on 02/03/2025.
//

import Foundation

public protocol ZBNetworkClientProtocol {
    func asyncRequest<T: Decodable>(endpoint: any ZBEndpointProvider, responseModel: T.Type) async throws -> T
    func asyncUpload<T: Decodable>(endpoint: any ZBEndpointProvider, responseModel: T.Type) async throws -> T
    func downloadFile(endpoint: any ZBEndpointProvider) async throws -> Data
    func addInterceptor(_ interceptor: ZBInterceptor)
}
