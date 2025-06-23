//
//  ZBSSLPinningCertificateSessionDelegate.swift
//  ZBNetworkKit
//
//  Created by Zuhaib Imtiaz on 6/20/25.
//
import Foundation

final class SSLPinningCertificateSessionDelegate: NSObject, URLSessionDelegate {

    private let certificateData: Data

    init(certificateName: String) {
        // Load certificate from the bundle
        let certPath = Bundle.main.path(forResource: certificateName, ofType: "cer")!
        self.certificateData = try! Data(contentsOf: URL(fileURLWithPath: certPath))
    }

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust,
              let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Extract the server certificate data
        let serverCertificateData = SecCertificateCopyData(serverCertificate) as Data

        // Compare server certificate to our bundled certificate
        if serverCertificateData == self.certificateData {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
