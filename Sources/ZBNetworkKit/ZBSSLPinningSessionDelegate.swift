//
//  ZBSSLPinningSessionDelegate.swift
//  ZBNetworkKit
//
//  Created by Zuhaib Imtiaz on 02/03/2025.
//
import Foundation
import CommonCrypto

final class ZBSSLPinningSessionDelegate: NSObject {
    private var publicKeyHash: String = ""
    
    convenience init(publicKeyHash: String) {
        self.init()
        self.publicKeyHash = publicKeyHash
    }
    
    private static let rsa2048Asn1Header:[UInt8] = [
        0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
        0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00
    ];
    
        
    private func sha256(data : Data) -> String {
        
        var keyWithHeader = Data(ZBSSLPinningSessionDelegate.rsa2048Asn1Header)
        keyWithHeader.append(data)
        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        keyWithHeader.withUnsafeBytes { buffer in
              _ = CC_SHA256(buffer.baseAddress!, CC_LONG(buffer.count), &hash)
          }
        return Data(hash).base64EncodedString()
    }
}

extension ZBSSLPinningSessionDelegate: URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (
            URLSession.AuthChallengeDisposition,
            URLCredential?
        ) -> Void
    ) {
        guard let serverTrust = challenge.protectionSpace.serverTrust, SecTrustGetCertificateCount(serverTrust) > 1 else {
            completionHandler(.cancelAuthenticationChallenge, nil);
            return
        }
        if let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 1) {
            // Server public key
            let serverPublicKey = SecCertificateCopyKey(serverCertificate)
            
            // Server public key Data
            let serverPublicKeyData = SecKeyCopyExternalRepresentation(serverPublicKey!, nil )!
            let data:Data = serverPublicKeyData as Data
            
            // Server Hash key
            let serverHashKey = self.sha256(data: data)
            // Local Hash Key
            let publickKeyLocal = self.publicKeyHash
            
            if (serverHashKey == publickKeyLocal) {
                completionHandler(.useCredential, URLCredential(trust:serverTrust))
                return
            }
            else {
                completionHandler(.cancelAuthenticationChallenge,nil)
            }
        }
    }
}
