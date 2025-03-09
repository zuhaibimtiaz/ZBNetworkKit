//
//  ZBNetworkKit.swift
//  ZBNetworkKit
//
//  Created by Zuhaib Imtiaz on 02/03/2025.
//
import Foundation

// Public entry point for the package
public enum ZBNetworkKit {
    public static func configure(
        scheme: String = "https",
        baseURL: String,
        publicKeyHash: String? = nil,
        refreshTokenEndpoint: (any ZBEndpointProvider)? = nil,
        defaultHeaders: [String: String]?,
        globalInterceptors: [ZBInterceptor]?,
        refreshTokenRetryCount: Int = 0,
        defaultTimeout: TimeInterval = 60,
        resourceTimeout: TimeInterval = 90,
        isLogging: Bool = true
    ) {
        ZBNetworkConfiguration.shared.scheme = scheme
        ZBNetworkConfiguration.shared.baseURL = baseURL
        ZBNetworkConfiguration.shared.publicKeyHash = publicKeyHash
        ZBNetworkConfiguration.shared.refreshTokenEndpoint = refreshTokenEndpoint
        ZBNetworkConfiguration.shared.defaultHeaders = defaultHeaders
        ZBNetworkConfiguration.shared.interceptors = globalInterceptors ?? []
        ZBNetworkConfiguration.shared.refreshTokenRetryCount = refreshTokenRetryCount
        ZBNetworkConfiguration.shared.defaultTimeout = defaultTimeout
        ZBNetworkConfiguration.shared.resourceTimeout = resourceTimeout
        ZBNetworkConfiguration.shared.isLogging = isLogging
    }
    
    public static func setToken(
        access: String,
        refresh: String? = nil
    ) {
        ZBTokenManager.shared.setTokens(access: access, refresh: refresh)
    }
    
    public static func clearToken() {
        ZBTokenManager.shared.clearTokens()
    }
}



