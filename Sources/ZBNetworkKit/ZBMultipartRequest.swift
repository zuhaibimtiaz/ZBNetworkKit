//
//  ZBMultipartRequest.swift
//  ZBNetworkKit
//
//  Created by Zuhaib Imtiaz on 08/03/2025.
//

import Foundation
import UniformTypeIdentifiers
import MobileCoreServices

/// Represents a structure for creating multipart/form-data requests.
public struct ZBMultipartRequest {
    /// The mutable data object to store the multipart request body.
    private var data = NSMutableData()

    /// A unique boundary string for separating parts in the multipart request.
    private let boundary: String = UUID().uuidString
    
    /// The separator used between parts in the multipart request.
    private let separator: String = "\r\n"

    /// The starting boundary marker for each part.
    private var topBoundry: String {
        return "--\(boundary)"
    }

    /// The ending boundary marker for the entire multipart request.
    private var endBoundry: String {
        return "--\(boundary)--"
    }

    /// Creates a Content-Disposition header for a form field.
    /// - Parameters:
    ///   - name: The name of the form field.
    ///   - fileName: The optional filename for the form field.
    /// - Returns: A string representing the Content-Disposition header.
    private func contentDisposition(_ name: String, fileName: String?) -> String {
        var disposition = "form-data; name=\"\(name)\""
        if let fileName = fileName { disposition += "; filename=\"\(fileName)\"" }
        return "Content-Disposition: " + disposition
    }

    /// The Content-Type header value for the multipart request.
    var headerValue: String {
        "multipart/form-data; boundary=\(boundary)"
    }

    /// The complete HTTP body of the multipart request.
    var httpBody: Data {
        let bodyData = data
        bodyData.append("--\(boundary)--")
        return bodyData as Data
    }

    /// The length of the HTTP body in bytes.
    var length: UInt64 {
        return UInt64(httpBody.count)
    }

    /// Appends a string value to the multipart request.
    /// - Parameters:
    ///   - fileString: The string data to append.
    ///   - name: The name of the form field.
    func append(fileString: String, withName name: String) {
        data.append(topBoundry)
        data.append(separator)
        data.append(contentDisposition(name, fileName: nil))
        data.append(separator)
        data.append(separator)
        data.append(fileString)
        data.append(separator)
    }

    /// Appends binary data to the multipart request with a specified MIME type.
    /// - Parameters:
    ///   - fileData: The binary data to append.
    ///   - name: The name of the form field.
    ///   - fileName: The optional filename for the data.
    ///   - mimeType: The optional MIME type for the data.
    func append(fileData: Data, withName name: String, fileName: String?, mimeType: FileType?) {
        data.append(topBoundry)
        data.append(separator)
        data.append(contentDisposition(name, fileName: fileName))
        data.append(separator)
        if let mimeType = mimeType {
            data.append("Content-Type: \(mimeType.rawValue)" + separator)
        }
        data.append(separator)
        data.append(fileData)
        data.append(separator)
    }
    
    /// Appends binary data to the multipart request with a custom MIME type string.
    /// - Parameters:
    ///   - fileData: The binary data to append.
    ///   - name: The name of the form field.
    ///   - fileName: The optional filename for the data.
    ///   - mimeTypeString: The optional MIME type string for the data.
    func append(fileData: Data, withName name: String, fileName: String?, mimeTypeString: String?) {
        data.append(topBoundry)
        data.append(separator)
        data.append(contentDisposition(name, fileName: fileName))
        data.append(separator)
        if let mimeTypeString = mimeTypeString {
            data.append("Content-Type: \(mimeType(for: mimeTypeString))" + separator)
        }
        data.append(separator)
        data.append(fileData)
        data.append(separator)
    }

    /// Appends data from a file URL to the multipart request.
    /// - Parameters:
    ///   - fileURL: The URL of the file to append.
    ///   - name: The name of the form field.
    func append(fileURL: URL, withName name: String) {
        guard let fileData = try? Data(contentsOf: fileURL) else {
            return
        }
        let fileName = fileURL.lastPathComponent
        let pathExtension = fileURL.pathExtension
        let mimeType = mimeType(for: pathExtension)

        data.append(topBoundry)
        data.append(separator)
        data.append(contentDisposition(name, fileName: fileName))
        data.append(separator)
        data.append("Content-Type: \(mimeType)" + separator)
        data.append(separator)
        data.append(fileData)
        data.append(separator)
    }
}

extension ZBMultipartRequest {
    /// Determines the MIME type for a given file extension.
    /// - Parameter pathExtension: The file extension to evaluate.
    /// - Returns: A string representing the MIME type, defaulting to "application/octet-stream" if unknown.
    private func mimeType(for pathExtension: String) -> String {
        if #available(iOS 14, *) {
            return UTType(filenameExtension: pathExtension)?.preferredMIMEType ?? "application/octet-stream"
        } else {
            if
                let id = UTTypeCreatePreferredIdentifierForTag(
                    kUTTagClassFilenameExtension,
                    pathExtension as CFString,
                    nil
                )?.takeRetainedValue(),
                let contentType = UTTypeCopyPreferredTagWithClass(id, kUTTagClassMIMEType)?.takeRetainedValue()
            {
                return contentType as String
            }

            return "application/octet-stream"
        }
    }
}

/// Enumerates common MIME types for files.
enum FileType: String {
    case jpeg = "image/jpeg"
    case png = "image/png"
    case gif = "image/gif"
    case tiff = "image/tiff"
    case bmp = "image/bmp"
    case quickTime = "video/quicktime"
    case mov = "video/mov"
    case mp4 = "video/mp4"
    case pdf = "application/pdf"
    case vnd = "application/vnd"
    case plainText = "text/plain"
    case anyBinary = "application/octet-stream"
}

private extension NSMutableData {
    /// Appends a string to the mutable data using the specified encoding.
    /// - Parameters:
    ///   - string: The string to append.
    ///   - encoding: The string encoding to use, defaults to UTF-8.
    func append(_ string: String, encoding: String.Encoding = .utf8) {
        if let data = string.data(using: encoding) {
            self.append(data)
        }
    }
}
