//
//  RefreshTokenManager.swift
//  ZBNetworkKit
//
//  Created by Zuhaib Imtiaz on 02/03/2025.
//
import Foundation

/// An actor for managing the refresh of authentication tokens in a thread-safe manner.
public actor ZBRefreshTokenManager {
    /// The shared singleton instance of the refresh token manager.
    public static let shared = ZBRefreshTokenManager()

    /// The current refresh task, if any, to prevent concurrent refresh attempts.
    private var refreshTask: Task<Void, Error>?

    /// Private initializer to enforce singleton pattern.
    private init() {}

    /// Refreshes the authentication tokens using the configured endpoint.
    /// - Throws: An error if the refresh request fails or no endpoint is configured.
    public func refreshToken() async throws {
        if refreshTask == nil,
            let endpoint = ZBNetworkConfiguration.shared.refreshTokenEndpoint {
            refreshTask = Task {
                defer {
                    refreshTask = nil
                }
                
                let client = ZBHttpClient()
                struct TokenResponse: Decodable {
                    let accessToken: String
                    let refreshToken: String
                }
                let response = try await client.asyncRequest(endpoint: endpoint, responseModel: TokenResponse.self)
                ZBTokenManager.shared.setTokens(access: response.accessToken, refresh: response.refreshToken)
            }
        }
        
        if let task = refreshTask {
            try await task.value
        }
    }
}

