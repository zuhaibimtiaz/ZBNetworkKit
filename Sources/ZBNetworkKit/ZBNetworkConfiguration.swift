//
//  ZBNetworkConfiguration.swift
//  ZBNetworkKit
//
//  Created by Zuhaib Imtiaz on 02/03/2025.
//

import Foundation

final class ZBNetworkConfiguration {
    static let shared = ZBNetworkConfiguration()
    var scheme: String = ""
    var baseURL: String = ""
    var publicKeyHash: String?
    var refreshTokenEndpoint: (any ZBEndpointProvider)?
    var defaultHeaders: [String: String]?
    var interceptors: [ZBInterceptor] = []
    var refreshTokenRetryCount: Int = 0
    var defaultTimeout: TimeInterval = 60
    var resourceTimeout: TimeInterval = 90
    var isLogging: Bool = true

    private init() {}
}
