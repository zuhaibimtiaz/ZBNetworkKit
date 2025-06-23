//
//  ZBNetworkClientProtocol.swift
//  ZBNetworkKit
//
//  Created by Zuhaib Imtiaz on 02/03/2025.
//

import Foundation

/// A protocol defining the interface for a network client to perform asynchronous requests, uploads, downloads, and interceptor management.
public protocol ZBNetworkClientProtocol: Sendable {
    /// Performs an asynchronous network request and decodes the response into the specified model.
    /// - Parameters:
    ///   - endpoint: The endpoint provider defining the request details.
    ///   - responseModel: The type of the expected response model, conforming to Decodable.
    /// - Returns: The decoded response of type T.
    /// - Throws: An error if the request or decoding fails.
    func asyncRequest<T: Decodable>(endpoint: any ZBEndpointProvider, responseModel: T.Type) async throws -> T

    /// Performs an asynchronous file upload request and decodes the response into the specified model.
    /// - Parameters:
    ///   - endpoint: The endpoint provider defining the upload request details.
    ///   - responseModel: The type of the expected response model, conforming to Decodable.
    /// - Returns: The decoded response of type T.
    /// - Throws: An error if the upload or decoding fails.
    func asyncUpload<T: Decodable>(endpoint: any ZBEndpointProvider, responseModel: T.Type) async throws -> T

    /// Downloads a file from the specified endpoint and returns its data.
    /// - Parameter endpoint: The endpoint provider defining the download request details.
    /// - Returns: The downloaded file data.
    /// - Throws: An error if the download fails.
    func downloadFile(endpoint: any ZBEndpointProvider) async throws -> Data
    
    /// Downloads a file from the specified endpoint and returns its data.
    /// - Parameter
    ///     - endpoint: The endpoint provider defining the download request details.
    ///     - progressHandler: this will give you the progress
    /// - Returns: The downloaded file data.
    /// - Throws: An error if the download fails.

    func download(endpoint: any ZBEndpointProvider, progressHandler: @Sendable @escaping (Double) -> Void) async throws -> URL
    
    func upload<T: Decodable>(endpoint: any ZBEndpointProvider, responseModel: T.Type, progressHandler: @Sendable @escaping (Double) -> Void) async throws -> T

    /// Adds an interceptor to modify network requests or responses.
    /// - Parameter interceptor: The interceptor to add.
    func addInterceptor(_ interceptor: ZBInterceptor)
}
