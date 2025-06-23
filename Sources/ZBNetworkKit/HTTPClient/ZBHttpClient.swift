//
//  ZBHttpClient.swift
//  ZBNetworkKit
//
//  Created by Zuhaib Imtiaz on 08/03/2025.
//

import Foundation

/// A final class implementing the `NetworkClientProtocol` to handle HTTP requests, uploads, and file downloads.
/// Supports SSL pinning, request interceptors, and token refresh retries.
final public class ZBHttpClient: NSObject, ZBNetworkClientProtocol, @unchecked Sendable  {
    
    // MARK: - Properties
    /// The `URLSession` used for making network requests.
    private var session: URLSession = URLSession(configuration: .default)
    
    /// The number of retry attempts for token refresh in case of unauthorized errors.
    private var retryCount: Int = 0
    
    /// An array of interceptors to modify requests and responses.
    private var interceptors: [ZBInterceptor] = []
    
    let tracker = ProgressTracker()

    // MARK: - Initialization
    
    /// Initializes the `HttpClient` with a configured `URLSession` and interceptors.
    public override init() {
        // Set retry count from shared `ZBNetworkConfiguration`.
        self.retryCount = ZBNetworkConfiguration.shared.refreshTokenRetryCount
        // Configure `URLSession` with default settings.
        super.init()
        self.configureSession()
        // Add global interceptors from `ZBNetworkConfiguration`.
        ZBNetworkConfiguration.shared.interceptors.forEach { [weak self] in
            self?.addInterceptor($0)
        }
    }
    
    private func configureSession() {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true // Wait for network connectivity.
        config.timeoutIntervalForRequest = ZBNetworkConfiguration.shared.defaultTimeout
        config.timeoutIntervalForResource = ZBNetworkConfiguration.shared.resourceTimeout
        
        // Apply SSL pinning if a public key hash is provided.
        if let publicKeyHash = ZBNetworkConfiguration.shared.publicKeyHash {
            let delegate = SSLPinningWithKeySessionDelegate(publicKeyHash: publicKeyHash)
            self.session = URLSession(
                configuration: config,
                delegate: delegate,
                delegateQueue: nil
            )
        } else if let certificateName = ZBNetworkConfiguration.shared.certificateName {
            let delegate = SSLPinningCertificateSessionDelegate(certificateName: certificateName)
            self.session = URLSession(
                configuration: config,
                delegate: delegate,
                delegateQueue: nil
            )
        } else {
            // Use default `URLSession` without SSL pinning.
            self.session = URLSession(configuration: config)
        }
    }
    
    // MARK: - Public Methods
    
    /// Adds an interceptor to the client's interceptor array.
    /// - Parameter interceptor: The interceptor to add for modifying requests and responses.
    public func addInterceptor(_ interceptor: ZBInterceptor) {
        self.interceptors.append(interceptor)
    }
    
    /// Performs an asynchronous HTTP request and decodes the response into the specified model.
    /// - Parameters:
    ///   - endpoint: The `EndpointProvider` defining the request details.
    ///   - responseModel: The type of the expected response model, conforming to `Decodable`.
    /// - Returns: The decoded response object of type `T`.
    /// - Throws: An `ZBAPIError` if the request fails or response cannot be decoded.
    public func asyncRequest<T: Decodable>(endpoint: any ZBEndpointProvider, responseModel: T.Type) async throws -> T {
        // Build the URL request from the endpoint.
        let request = try endpoint.buildURLRequest()
        
        // Perform the request and return the decoded response.
        return try await performRequest(request: request, endpoint: endpoint, responseModel: responseModel)
    }
    
    /// Performs an asynchronous file upload request and decodes the response into the specified model.
    /// - Parameters:
    ///   - endpoint: The `EndpointProvider` defining the upload request details.
    ///   - responseModel: The type of the expected response model, conforming to `Decodable`.
    /// - Returns: The decoded response object of type `T`.
    /// - Throws: An `ZBAPIError` if the upload data is missing, the request fails, or the response cannot be decoded.
    public func asyncUpload<T: Decodable>(endpoint: any ZBEndpointProvider, responseModel: T.Type) async throws -> T {
        // Ensure upload data is provided.
        guard let uploadData = endpoint.uploadData else {
            throw ZBAPIError.invalidRequest
        }
        
        // Build the URL request from the endpoint.
        var request = try endpoint.buildURLRequest()
        
        // Apply interceptors unless bypassed, with fallback to logging if enabled.
        if !endpoint.avoidAllInterceptor {
            try interceptors.forEach { try $0.onRequest(&request) }
        }
        if !endpoint.avoidAllInterceptor,
           ZBNetworkConfiguration.shared.isLogging {
            try ZBLoggingInterceptor().onRequest(&request)
        }
        
        // Perform the upload request and retrieve response data.
        var (data, response) = try await session.upload(for: request, from: uploadData)
        
        // Apply response interceptors unless bypassed, with fallback to logging if enabled.
        if !endpoint.avoidAllInterceptor {
            try endpoint.interceptors.forEach { try $0.onResponse(&data, response, nil) }
            try interceptors.forEach { try $0.onResponse(&data, response, nil) }
        }
        if !endpoint.avoidAllInterceptor,
           ZBNetworkConfiguration.shared.isLogging {
            try ZBLoggingInterceptor().onResponse(&data, response, nil)
        }
        // Process and decode the response.
        return try manageResponse(data: data, response: response)
    }
    
    /// Downloads a file from the specified endpoint and returns the raw data.
    /// - Parameter endpoint: The `EndpointProvider` defining the download request details.
    /// - Returns: The raw `Data` of the downloaded file.
    /// - Throws: An `ZBAPIError` if the request fails or the response status is not 200.
    public func downloadFile(endpoint: any ZBEndpointProvider) async throws -> Data {
        // Build the URL request from the endpoint.
        var request = try endpoint.buildURLRequest()
        
        // Apply interceptors unless bypassed, with fallback to logging if enabled.
        if !endpoint.avoidAllInterceptor {
            try interceptors.forEach { try $0.onRequest(&request) }
        }
        if !endpoint.avoidAllInterceptor,
           ZBNetworkConfiguration.shared.isLogging {
            try ZBLoggingInterceptor().onRequest(&request)
        }
        
        // Perform the download request and retrieve response data.
        var (data, response) = try await session.data(for: request)
        
        // Apply response interceptors unless bypassed, with fallback to logging if enabled.
        if !endpoint.avoidAllInterceptor {
            try endpoint.interceptors.forEach { try $0.onResponse(&data, response, nil) }
            try interceptors.forEach { try $0.onResponse(&data, response, nil) }
        }
        if !endpoint.avoidAllInterceptor,
           ZBNetworkConfiguration.shared.isLogging {
            try ZBLoggingInterceptor().onResponse(&data, response, nil)
        }
        
        // Validate the HTTP response status code.
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw ZBAPIError.custom(model:
                .init(
                    code: code,
                    message: "Download failed with status: \(code)",
                    response: nil,
                    request: request
                )
            )
        }
        
        // Return the downloaded data.
        return data
    }
    
    public func download(endpoint: any ZBEndpointProvider, progressHandler: @Sendable @escaping (Double) -> Void) async throws -> URL {

        var request = try endpoint.buildURLRequest()
        
        // Apply interceptors unless bypassed, with fallback to logging if enabled.
        if !endpoint.avoidAllInterceptor {
            try interceptors.forEach { try $0.onRequest(&request) }
        }
        if !endpoint.avoidAllInterceptor,
           ZBNetworkConfiguration.shared.isLogging {
            try ZBLoggingInterceptor().onRequest(&request)
        }

        #warning("will remove the force unwrap")
        let task = session.downloadTask(with: request.url!)
        await tracker.setProgressHandler(for: task.taskIdentifier, handler: progressHandler)

        return try await withCheckedThrowingContinuation { continuation in
            Task { await self.tracker.setDownloadContinuation(for: task.taskIdentifier, continuation: continuation) }
            task.resume()
        }
    }
    
    public func upload<T: Decodable>(
            endpoint: any ZBEndpointProvider,
            responseModel: T.Type,
            progressHandler: @Sendable @escaping (Double) -> Void
        ) async throws -> T {
            guard let uploadData = endpoint.uploadData else {
                throw ZBAPIError.invalidRequest
            }
            var request = try endpoint.buildURLRequest()

            if !endpoint.avoidAllInterceptor {
                try interceptors.forEach { try $0.onRequest(&request) }
            }
            if !endpoint.avoidAllInterceptor,
               ZBNetworkConfiguration.shared.isLogging {
                try ZBLoggingInterceptor().onRequest(&request)
            }

            let task = session.uploadTask(with: request, from: uploadData)
            await tracker.setProgressHandler(for: task.taskIdentifier, handler: progressHandler)

            var (data, response) = try await withCheckedThrowingContinuation { continuation in
                Task {
                    await self.tracker.setUploadContinuation(for: task.taskIdentifier, continuation: continuation)
                }
                task.resume()
            }

            if !endpoint.avoidAllInterceptor {
                try endpoint.interceptors.forEach { try $0.onResponse(&data, response, nil) }
                try interceptors.forEach { try $0.onResponse(&data, response, nil) }
            }
            if !endpoint.avoidAllInterceptor,
                ZBNetworkConfiguration.shared.isLogging {
                try ZBLoggingInterceptor().onResponse(&data, response, nil)
            }

            return try manageResponse(data: data, response: response)
        }
    
    // MARK: - Private Methods
    
    /// Performs an HTTP request with retry logic for unauthorized errors and decodes the response.
    /// - Parameters:
    ///   - request: The `URLRequest` to execute.
    ///   - endpoint: The `EndpointProvider` defining the request details.
    ///   - responseModel: The type of the expected response model, conforming to `Decodable`.
    /// - Returns: The decoded response object of type `T`.
    /// - Throws: An `ZBAPIError` if the request fails, token refresh fails, or the response cannot be decoded.
    private func performRequest<T: Decodable>(
        request: URLRequest,
        endpoint: any ZBEndpointProvider,
        responseModel: T.Type
    ) async throws -> T {
        do {
            // Perform the request and retrieve response data.
            var (data, response) = try await session.data(for: request)
            
            // Apply response interceptors unless bypassed, with fallback to logging if enabled.
            if !endpoint.avoidAllInterceptor {
                try endpoint.interceptors.forEach { try $0.onResponse(&data, response, nil) }
                try interceptors.forEach { try $0.onResponse(&data, response, nil) }
            }
            if !endpoint.avoidAllInterceptor,
               ZBNetworkConfiguration.shared.isLogging {
                try ZBLoggingInterceptor().onResponse(&data, response, nil)
            }
            
            // Process and decode the response.
            return try manageResponse(data: data, response: response)
        } catch let error as ZBAPIError {
            // Handle unauthorized errors with token refresh retry logic.
            if error == .unauthorized && retryCount > 0 {
                do {
                    try await ZBRefreshTokenManager.shared.refreshToken()
                    retryCount -= 1
                    // Retry the request after refreshing the token.
                    return try await performRequest(request: request, endpoint: endpoint, responseModel: responseModel)
                } catch {
                    throw ZBAPIError.tokenRefreshFailed
                }
            } else {
                throw error
            }
        } catch let error as NSError {
            // Handle NSError by wrapping it in a custom `ZBAPIError`.
            throw ZBAPIError.custom(model:
                .init(
                    code: 0,
                    message: "Something went wrong: \(error.localizedDescription)",
                    response: nil,
                    request: request
                )
            )
        } catch {
            // Handle unknown errors by wrapping them in a custom `ZBAPIError`.
            throw ZBAPIError.custom(model:
                .init(
                    code: 0,
                    message: "Something went wrong: \(error.localizedDescription)",
                    response: nil,
                    request: request
                )
            )
        }
    }
    
    /// Processes the HTTP response and decodes it into the specified model.
    /// - Parameters:
    ///   - data: The raw response data.
    ///   - response: The `URLResponse` from the request.
    /// - Returns: The decoded response object of type `T`.
    /// - Throws: An `ZBAPIError` if the response is invalid, the status code indicates failure, or decoding fails.
    private func manageResponse<T: Decodable>(data: Data, response: URLResponse) throws -> T {
        // Ensure the response is an HTTP response.
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ZBAPIError.networkError("Invalid HTTP response")
        }
        
        let statusCode = httpResponse.statusCode
        switch statusCode {
        case 200...299:
            // Decode the response data into the specified model.
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw ZBAPIError.decodingError("Failed to decode response: \(error.localizedDescription)")
            }
        case 401:
            // Throw unauthorized error for 401 status.
            throw ZBAPIError.unauthorized
        default:
            // Throw custom error for other failure status codes.
            throw ZBAPIError.custom(model:
                .init(
                    code: statusCode,
                    message: "Request failed with status: \(statusCode)",
                    response: httpResponse,
                    request: nil
                )
            )
        }
    }
}
