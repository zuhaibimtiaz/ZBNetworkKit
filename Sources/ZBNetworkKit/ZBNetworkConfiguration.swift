//
//  ZBNetworkConfiguration.swift
//  ZBNetworkKit
//
//  Created by Zuhaib Imtiaz on 02/03/2025.
//

import Foundation

/// A singleton class for managing network configuration settings.
final class ZBNetworkConfiguration {
    /// The shared instance of the network configuration.
    nonisolated(unsafe) static let shared = ZBNetworkConfiguration()

    /// The URL scheme for network requests (e.g., "https").
    var scheme: String = "https"

    /// The base URL for network requests.
    var baseURL: String = ""

    /// An optional public key hash for certificate pinning.
    var publicKeyHash: String?
    
    /// An optional  for certificate pinning.
    var certificateName: String?

    /// An optional endpoint provider for refreshing authentication tokens.
    var refreshTokenEndpoint: (any ZBEndpointProvider)?

    /// Optional default headers to include in network requests.
    var defaultHeaders: [String: String]?

    /// An array of interceptors for modifying network requests or responses.
    var interceptors: [ZBInterceptor] = []

    /// The number of retry attempts for refreshing authentication tokens.
    var refreshTokenRetryCount: Int = 0

    /// The default timeout interval for network requests, in seconds.
    var defaultTimeout: TimeInterval = 60

    /// The timeout interval for resource-intensive network requests, in seconds.
    var resourceTimeout: TimeInterval = 90

    /// A flag indicating whether logging is enabled for network requests.
    var isLogging: Bool = true

    /// Private initializer to enforce singleton pattern.
    private init() {}
}
