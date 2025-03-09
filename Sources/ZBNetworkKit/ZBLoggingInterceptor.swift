//
//  ZBLoggingInterceptor.swift
//  ZBNetworkKit
//
//  Created by Zuhaib Imtiaz on 09/03/2025.
//
import Foundation

public struct ZBLoggingInterceptor: ZBInterceptor {
    public func onRequest(_ request: inout URLRequest) {
        let curl = formatCurlRequest(request)
        Log.info(curl)
    }
    
    public func onResponse(_ data: inout Data, _ response: URLResponse?, _ error: Error?) {
        if let error = error {
            Log.error("Response Error:\n\(error.localizedDescription)")
        } else if let httpResponse = response as? HTTPURLResponse {
            let formattedResponse = formatResponse(httpResponse, data: data)
            Log.info("Response:\n\(formattedResponse)")
        } else {
            Log.error("Response: No valid response or data received")
        }
    }
    
    private func formatCurlRequest(_ request: URLRequest) -> String {
        var components = ["curl -X \(request.httpMethod ?? "GET")"]
        
        // Add URL
        if let url = request.url?.absoluteString {
            components.append("\"\(url)\"")
        }
        
        // Add headers
        if let headers = request.allHTTPHeaderFields,
            !headers.isEmpty {
            for (key, value) in headers {
                components.append("-H \"\(key): \(value)\"")
            }
        }
        
        // Add body
        if let body = request.httpBody, !body.isEmpty {
            if let bodyString = String(data: body, encoding: .utf8) {
                // Escape quotes in the body for cURL
                let escapedBody = bodyString.replacingOccurrences(of: "\"", with: "\\\"")
                components.append("-d \"\(escapedBody)\"")
            } else {
                // If body isn’t UTF-8 string, show as raw bytes
                components.append("-d \"[binary data: \(body.count) bytes]\"")
            }
        }
        
        // Join components with proper spacing
        return components.joined(separator: " \\\n\t")
    }
    
    private func formatResponse(_ response: HTTPURLResponse, data: Data) -> String {
        var output = ["Status: \(response.statusCode)"]
        
        // Add headers
        if !response.allHeaderFields.isEmpty {
            output.append("Headers:")
            for (key, value) in response.allHeaderFields {
                output.append("  \(key): \(value)")
            }
        }
        
        // Add body (pretty-print JSON if possible)
        output.append("Body:")
        if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
           let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            output.append(prettyString)
        } else if let string = String(data: data, encoding: .utf8),
                    !string.isEmpty {
            output.append(string)
        } else {
            output.append("[binary data: \(data.count) bytes]")
        }
        
        return output.joined(separator: "\n")
    }
}
