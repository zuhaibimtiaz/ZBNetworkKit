//
//  ZBInterceptor.swift
//  ZBNetworkKit
//
//  Created by Zuhaib Imtiaz on 09/03/2025.
//
import Foundation

public protocol ZBInterceptor {
    func onRequest(_ request: inout URLRequest)
    func onResponse(_ data: inout Data, _ response: URLResponse?, _ error: Error?)
}

public extension ZBInterceptor {
    func onRequest(_ request: inout URLRequest) {
        // No-op by default
    }
    
    func onResponse(_ data: inout Data, _ response: URLResponse?, _ error: Error?) {
        // No-op by default
    }
}
