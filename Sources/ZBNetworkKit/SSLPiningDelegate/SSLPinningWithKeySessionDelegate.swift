//
//  ZBSSLPinningWithKeySessionDelegate.swift
//  ZBNetworkKit
//
//  Created by Zuhaib Imtiaz on 02/03/2025.
//
import Foundation
import CommonCrypto

final class SSLPinningWithKeySessionDelegate: NSObject, URLSessionDelegate {
    /// The public key hash to compare against the server's certificate for SSL pinning.
    private let publicKeyHash: String?

    /// Initializes the delegate with a public key hash for SSL pinning.
    /// - Parameter publicKeyHash: The expected public key hash to validate server certificates.
    init(publicKeyHash: String) {
        self.publicKeyHash = publicKeyHash
    }
    
    /// The ASN.1 header for RSA 2048-bit keys, used in SHA-256 hashing for SSL pinning.
    private static let rsa2048Asn1Header: [UInt8] = [
        0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09,
        0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01,
        0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00
    ]

    /// Computes the SHA-256 hash of the provided data, prepended with the RSA 2048-bit ASN.1 header.
    /// - Parameter data: The data to hash (typically a public key).
    /// - Returns: A base64-encoded string of the SHA-256 hash.
    private func sha256(data: Data) -> String {
        var keyWithHeader = Data(Self.rsa2048Asn1Header)
        keyWithHeader.append(data)
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        keyWithHeader.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG($0.count), &hash)
        }
        return Data(hash).base64EncodedString()
    }
}

extension SSLPinningWithKeySessionDelegate: URLSessionDataDelegate {
    /// Handles authentication challenges for URLSession, performing SSL pinning by validating the server's public key hash.
    /// - Parameters:
    ///   - session: The URLSession receiving the challenge.
    ///   - challenge: The authentication challenge to process.
    ///   - completionHandler: A closure to indicate how to handle the challenge and provide credentials if valid.

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (
            URLSession.AuthChallengeDisposition,
            URLCredential?
        ) -> Void
    ) {
        guard
            challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
            let serverTrust = challenge.protectionSpace.serverTrust,
            SecTrustGetCertificateCount(serverTrust) > 0,
            let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0),
            let serverPublicKey = SecCertificateCopyKey(serverCertificate),
            let serverPublicKeyData = SecKeyCopyExternalRepresentation(serverPublicKey, nil) as Data?
        else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        let serverHash = sha256(data: serverPublicKeyData)
        
        if serverHash == publicKeyHash {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
