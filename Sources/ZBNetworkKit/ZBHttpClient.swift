//
//  ZBHttpClient.swift
//  ZBNetworkKit
//
//  Created by Zuhaib Imtiaz on 08/03/2025.
//

import Foundation

final public class ZBHttpClient: ZBNetworkClientProtocol {
   
    private let session: URLSession
    private var retryCount: Int = 0
    private var interceptors: [ZBInterceptor] = []
    
    public init() {
        self.retryCount = ZBNetworkConfiguration.shared.refreshTokenRetryCount
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        config.timeoutIntervalForRequest = ZBNetworkConfiguration.shared.defaultTimeout
        config.timeoutIntervalForResource = ZBNetworkConfiguration.shared.resourceTimeout

        if let publicKeyHash = ZBNetworkConfiguration.shared.publicKeyHash {
            let delegate = ZBSSLPinningSessionDelegate(publicKeyHash: publicKeyHash)
            self.session = URLSession(
                configuration: config,
                delegate: delegate,
                delegateQueue: nil
            )
        } else {
            self.session = URLSession(configuration: config)
        }
        ZBNetworkConfiguration.shared.interceptors.forEach { self.addInterceptor($0) }
    }
    
    public func addInterceptor(_ interceptor: ZBInterceptor) {
        self.interceptors.append(interceptor)
    }
    
    public func asyncRequest<T: Decodable>(endpoint: any ZBEndpointProvider, responseModel: T.Type) async throws -> T {
        var request = try endpoint.buildURLRequest()
        if !endpoint.avoidAllInterceptor {
            interceptors.forEach { $0.onRequest(&request) }
        } else if ZBNetworkConfiguration.shared.isLogging {
            ZBLoggingInterceptor().onRequest(&request)
        }
        return try await performRequest(request: request, endpoint: endpoint, responseModel: responseModel)
    }
    
    public func asyncUpload<T: Decodable>(endpoint: any ZBEndpointProvider, responseModel: T.Type) async throws -> T {
        guard let uploadData = endpoint.uploadData else {
            throw ZBAPIError.invalidRequest
        }
        var request = try endpoint.buildURLRequest()
        if !endpoint.avoidAllInterceptor {
            interceptors.forEach { $0.onRequest(&request) }
        } else if ZBNetworkConfiguration.shared.isLogging {
            ZBLoggingInterceptor().onRequest(&request)
        }

        var (data, response) = try await session.upload(for: request, from: uploadData)
        if !endpoint.avoidAllInterceptor {
            endpoint.interceptors.forEach { $0.onResponse(&data, response, nil) }
            interceptors.forEach { $0.onResponse(&data, response, nil) }
        } else if ZBNetworkConfiguration.shared.isLogging {
            ZBLoggingInterceptor().onResponse(&data, response, nil)
        }

        return try manageResponse(data: data, response: response)
    }
    
    public func downloadFile(endpoint: any ZBEndpointProvider) async throws -> Data {
        var request = try endpoint.buildURLRequest()
        if !endpoint.avoidAllInterceptor {
            interceptors.forEach { $0.onRequest(&request) }
        } else if ZBNetworkConfiguration.shared.isLogging {
            ZBLoggingInterceptor().onRequest(&request)
        }

        var (data, response) = try await session.data(for: request)
        if !endpoint.avoidAllInterceptor {
            endpoint.interceptors.forEach { $0.onResponse(&data, response, nil) }
            interceptors.forEach { $0.onResponse(&data, response, nil) }
        } else if ZBNetworkConfiguration.shared.isLogging {
            ZBLoggingInterceptor().onResponse(&data, response, nil)
        }

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
        return data
    }
    
    private func performRequest<T: Decodable>(
        request: URLRequest,
        endpoint: any ZBEndpointProvider,
        responseModel: T.Type
    ) async throws -> T {
        do {
            var modifiedRequest = request
            if !endpoint.avoidAllInterceptor {
                interceptors.forEach { $0.onRequest(&modifiedRequest) }
            } else if ZBNetworkConfiguration.shared.isLogging {
                ZBLoggingInterceptor().onRequest(&modifiedRequest)
            }
            var (data, response) = try await session.data(for: request)
            if !endpoint.avoidAllInterceptor {
                endpoint.interceptors.forEach { $0.onResponse(&data, response, nil) }
                interceptors.forEach { $0.onResponse(&data, response, nil) }
            } else if ZBNetworkConfiguration.shared.isLogging {
                ZBLoggingInterceptor().onResponse(&data, response, nil)
            }

            return try manageResponse(data: data, response: response)
        } catch let error as ZBAPIError {
            if error == .unauthorized && retryCount > 0 {
                do {
                    try await ZBRefreshTokenManager.shared.refreshToken()
                    retryCount -= 1
                    return try await performRequest(request: request, endpoint: endpoint, responseModel: responseModel)
                } catch {
                    throw ZBAPIError.tokenRefreshFailed
                }
            } else {
                throw error
            }
        } catch let error as NSError {
            throw ZBAPIError.custom(model:
                    .init(
                        code: 0,
                        message: "Something went wrong: \(error.localizedDescription)",
                        response: nil,
                        request: request
                    )
            )
        } catch {
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
    
    private func manageResponse<T: Decodable>(data: Data, response: URLResponse) throws -> T {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ZBAPIError.networkError("Invalid HTTP response")
        }
        
        let statusCode = httpResponse.statusCode
        switch statusCode {
        case 200...299:
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw ZBAPIError.decodingError("Failed to decode response: \(error.localizedDescription)")
            }
        case 401:
            throw ZBAPIError.unauthorized
        default:
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
