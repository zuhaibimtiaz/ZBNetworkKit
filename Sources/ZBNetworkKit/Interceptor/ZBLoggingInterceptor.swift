//
//  ZBLoggingInterceptor.swift
//  ZBNetworkKit
//
//  Created by Zuhaib Imtiaz on 09/03/2025.
//
import Foundation


/// A struct implementing the `Interceptor` protocol to log HTTP requests and responses.
/// Logs requests as cURL commands and responses with status, headers, and body details.
public struct ZBLoggingInterceptor: ZBInterceptor {
    
    /// Logs the HTTP request as a cURL command.
    /// - Parameter request: The `URLRequest` to log (passed as inout).
    public func onRequest(_ request: inout URLRequest) throws {
        // Format the request as a cURL command.
        let curl = formatCurlRequest(request)
        // Log the cURL command at info level.
        Log.info(curl)
    }
    
    /// Logs the HTTP response, including status, headers, and body, or logs errors if present.
    /// - Parameters:
    ///   - data: The response data to log (passed as inout).
    ///   - response: The `URLResponse` received from the request, if any.
    ///   - error: The `Error` encountered during the request, if any.
    public func onResponse(_ data: inout Data, _ response: URLResponse?, _ error: Error?) throws {
        if let error = error {
            // Log error details if an error occurred.
            Log.error("Response Error:\n\(error.localizedDescription)")
        } else if let httpResponse = response as? HTTPURLResponse {
            // Format and log the HTTP response with status, headers, and body.
            let formattedResponse = formatResponse(httpResponse, data: data)
            Log.info("Response:\n\(formattedResponse)")
        } else {
            // Log an error if no valid response or data is received.
            Log.error("Response: No valid response or data received")
        }
    }
    
    /// Formats a `URLRequest` as a cURL command for logging.
    /// - Parameter request: The `URLRequest` to format.
    /// - Returns: A string representing the request as a cURL command.
    private func formatCurlRequest(_ request: URLRequest) -> String {
        // Initialize components with the HTTP method (default to GET if not specified).
        var components = ["curl -X \(request.httpMethod ?? "GET")"]
        
        // Add the URL if available.
        if let url = request.url?.absoluteString {
            components.append("\"\(url)\"")
        }
        
        // Add headers if present.
        if let headers = request.allHTTPHeaderFields,
           !headers.isEmpty {
            for (key, value) in headers {
                components.append("-H \"\(key): \(value)\"")
            }
        }
        
        // Add request body if present.
        if let body = request.httpBody, !body.isEmpty {
            if let bodyString = String(data: body, encoding: .utf8) {
                // Escape quotes in the body to ensure valid cURL syntax.
                let escapedBody = bodyString.replacingOccurrences(of: "\"", with: "\\\"")
                components.append("-d \"\(escapedBody)\"")
            } else {
                // Log binary data size if body cannot be converted to UTF-8 string.
                components.append("-d \"[binary data: \(body.count) bytes]\"")
            }
        }
        
        // Join components with newline and tab for readable formatting.
        return components.joined(separator: " \\\n\t")
    }
    
    /// Formats an HTTP response with status, headers, and body for logging.
    /// - Parameters:
    ///   - response: The `HTTPURLResponse` to format.
    ///   - data: The response data to format.
    /// - Returns: A string containing the formatted response details.
    private func formatResponse(_ response: HTTPURLResponse, data: Data) -> String {
        // Initialize output with the HTTP status code.
        var output = ["Status: \(response.statusCode)"]
        
        // Add headers if present.
        if !response.allHeaderFields.isEmpty {
            output.append("Headers:")
            for (key, value) in response.allHeaderFields {
                output.append("  \(key): \(value)")
            }
        }
        
        // Add response body, attempting to pretty-print JSON if possible.
        output.append("Body:")
        if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
           let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            // Append pretty-printed JSON if successful.
            output.append(prettyString)
        } else if let string = String(data: data, encoding: .utf8),
                  !string.isEmpty {
            // Append raw string if not JSON but convertible to UTF-8.
            output.append(string)
        } else {
            // Append binary data size if body cannot be converted to string.
            output.append("[binary data: \(data.count) bytes]")
        }
        
        // Join output components with newlines for readable formatting.
        return output.joined(separator: "\n")
    }
}
