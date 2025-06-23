//
//  ZBNetworkKit.swift
//  ZBNetworkKit
//
//  Created by Zuhaib Imtiaz on 02/03/2025.
//
import Foundation

// Public entry point for the package
public enum ZBNetworkKit {
    /// Timeout settings for network requests.
    public struct TimeoutSettings {
        let defaultTimeout: TimeInterval
        let resourceTimeout: TimeInterval
        
        public init(defaultTimeout: TimeInterval = 60,
                    resourceTimeout: TimeInterval = 90) {
            self.defaultTimeout = defaultTimeout
            self.resourceTimeout = resourceTimeout
        }
    }
    
    /// Authentication settings for network requests.
    public struct AuthSettings {
        let publicKeyHash: String?
        let sslCertificateName: String?
        let refreshTokenEndpoint: (any ZBEndpointProvider)?
        let refreshTokenRetryCount: Int
        
        public init(
            publicKeyHash: String? = nil,
            sslCertificateName: String? = nil,
            refreshTokenEndpoint: (any ZBEndpointProvider)? = nil,
            refreshTokenRetryCount: Int = 0
        ) {
            self.publicKeyHash = publicKeyHash
            self.sslCertificateName = sslCertificateName
            self.refreshTokenEndpoint = refreshTokenEndpoint
            self.refreshTokenRetryCount = refreshTokenRetryCount
        }
    }
    
    /// Request settings for network configuration.
    public struct RequestSettings {
        let defaultHeaders: [String: String]?
        let globalInterceptors: [ZBInterceptor]?
        
        public init(
            defaultHeaders: [String: String]? = nil,
            globalInterceptors: [ZBInterceptor]? = nil
        ) {
            self.defaultHeaders = defaultHeaders
            self.globalInterceptors = globalInterceptors
        }
    }
    
    /// Base URL settings for network configuration.
    public struct BaseURLSettings {
        let scheme: String
        let url: String

        public init(
            scheme: String = "https",
            url: String
        ) {
            self.scheme = scheme
            self.url = url
        }
    }
    
    /// Configuration struct for network settings.
    public struct ZBNetworkConfigurationSettings {
        let baseURL: BaseURLSettings
        let auth: AuthSettings
        let request: RequestSettings
        let timeouts: TimeoutSettings
        let isLogging: Bool
        
        public init(
            baseURL: BaseURLSettings,
            auth: AuthSettings = AuthSettings(),
            request: RequestSettings = RequestSettings(),
            timeouts: TimeoutSettings = TimeoutSettings(),
            isLogging: Bool = true
        ) {
            self.baseURL = baseURL
            self.auth = auth
            self.request = request
            self.timeouts = timeouts
            self.isLogging = isLogging
        }
    }
    
    /// Configures the shared network configuration with the provided settings.
    /// - Parameter settings: The configuration settings for the network.
    public static func configure(_ settings: ZBNetworkConfigurationSettings) {
        ZBNetworkConfiguration.shared.scheme = settings.baseURL.scheme
        ZBNetworkConfiguration.shared.baseURL = settings.baseURL.url
        ZBNetworkConfiguration.shared.publicKeyHash = settings.auth.publicKeyHash
        ZBNetworkConfiguration.shared.certificateName = settings.auth.sslCertificateName
        ZBNetworkConfiguration.shared.refreshTokenEndpoint = settings.auth.refreshTokenEndpoint
        ZBNetworkConfiguration.shared.defaultHeaders = settings.request.defaultHeaders
        ZBNetworkConfiguration.shared.interceptors = settings.request.globalInterceptors ?? []
        ZBNetworkConfiguration.shared.refreshTokenRetryCount = settings.auth.refreshTokenRetryCount
        ZBNetworkConfiguration.shared.defaultTimeout = settings.timeouts.defaultTimeout
        ZBNetworkConfiguration.shared.resourceTimeout = settings.timeouts.resourceTimeout
        ZBNetworkConfiguration.shared.isLogging = settings.isLogging
    }
    
    /// Sets authentication tokens in the shared token manager.
    /// - Parameters:
    ///   - access: The access token to set.
    ///   - refresh: An optional refresh token to set. Defaults to nil.
    public static func setToken(
        access: String,
        refresh: String? = nil
    ) {
        ZBTokenManager.shared.setTokens(access: access, refresh: refresh)
    }
    
    /// Clears all authentication tokens from the shared token manager.
    public static func clearToken() {
        ZBTokenManager.shared.clearTokens()
    }
}



