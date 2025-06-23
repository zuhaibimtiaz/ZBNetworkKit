//
//  ZBTokenManager.swift
//  ZBNetworkKit
//
//  Created by Zuhaib Imtiaz on 08/03/2025.
//

/// An actor for managing authentication tokens in a thread-safe manner.
public class ZBTokenManager {
    /// The shared instance of the token manager.
    nonisolated(unsafe) public static let shared = ZBTokenManager()

    /// The current access token, if set.
    private var accessToken: String?

    /// The current refresh token, if set.
    private var refreshToken: String?

    /// Private initializer to enforce singleton pattern.
    private init() {}

    /// Sets the access and refresh tokens.
    /// - Parameters:
    ///   - access: The access token to set.
    ///   - refresh: An optional refresh token to set. Defaults to nil.
    public func setTokens(access: String, refresh: String?) {
        self.accessToken = access
        self.refreshToken = refresh
    }

    /// Clears both the access and refresh tokens.
    public func clearTokens() {
        self.accessToken = nil
        self.refreshToken = nil
    }

    /// Retrieves the current access token.
    /// - Returns: The access token, or nil if not set.
    public func getAccessToken() -> String? {
        return accessToken
    }

    /// Retrieves the current refresh token.
    /// - Returns: The refresh token, or nil if not set.
    public func getRefreshToken() -> String? {
        return refreshToken
    }
}
