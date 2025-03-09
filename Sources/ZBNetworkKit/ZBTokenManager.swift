//
//  ZBTokenManager.swift
//  ZBNetworkKit
//
//  Created by Zuhaib Imtiaz on 08/03/2025.
//

// Token Manager
final class ZBTokenManager {
    public static let shared = ZBTokenManager()
    public var accessToken: String?
    public var refreshToken: String?
    private init() {}
    
    public func setTokens(access: String, refresh: String?) {
        self.accessToken = access
        self.refreshToken = refresh
    }
    
    public func clearTokens() {
        self.accessToken = nil
        self.refreshToken = nil
    }
}
