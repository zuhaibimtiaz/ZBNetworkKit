//
//  RefreshTokenManager.swift
//  ZBNetworkKit
//
//  Created by Zuhaib Imtiaz on 02/03/2025.
//
import Foundation

public actor ZBRefreshTokenManager {
    public static let shared = ZBRefreshTokenManager()
    private var refreshTask: Task<Void, Error>?
    private let lock = NSLock()
    
    private init() {}
    
    public func refreshToken() async throws {
        lock.lock()
        if refreshTask == nil, let endpoint = ZBNetworkConfiguration.shared.refreshTokenEndpoint {
            refreshTask = Task {
                defer {
                    lock.lock()
                    refreshTask = nil
                    lock.unlock()
                }
                
                let client = ZBHttpClient()
                struct TokenResponse: Decodable {
                    let accessToken: String
                    let refreshToken: String
                }
                let response = try await client.asyncRequest(endpoint: endpoint, responseModel: TokenResponse.self)
                await ZBTokenManager.shared.setTokens(access: response.accessToken, refresh: response.refreshToken)
            }
        }
        lock.unlock()
        
        if let task = refreshTask {
            try await task.value
        }
    }
}

