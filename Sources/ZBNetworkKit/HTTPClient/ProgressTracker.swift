//
//  ProgressTracker.swift
//  ZBNetworkKit
//
//  Created by Zuhaib Imtiaz on 6/23/25.
//

import Foundation

actor ProgressTracker {
    private var progressHandlers: [Int: @Sendable (Double) -> Void] = [:]
    private var downloadContinuationMap: [Int: CheckedContinuation<URL, Error>] = [:]
    private var uploadContinuationMap: [Int: CheckedContinuation<(Data, URLResponse), Error>] = [:]

    func setProgressHandler(for taskIdentifier: Int, handler: @Sendable @escaping (Double) -> Void) {
        progressHandlers[taskIdentifier] = handler
    }

    func setDownloadContinuation(for taskIdentifier: Int, continuation: CheckedContinuation<URL, Error>) {
        downloadContinuationMap[taskIdentifier] = continuation
    }

    func setUploadContinuation(for taskIdentifier: Int, continuation: CheckedContinuation<(Data, URLResponse), Error>) {
        uploadContinuationMap[taskIdentifier] = continuation
    }

    func updateProgress(for taskIdentifier: Int, progress: Double) {
        progressHandlers[taskIdentifier]?(progress)
    }

    func completeDownload(for taskIdentifier: Int, url: URL?, error: Error?) {
        if let error {
            downloadContinuationMap[taskIdentifier]?.resume(throwing: error)
        } else if let url {
            downloadContinuationMap[taskIdentifier]?.resume(returning: url)
        }
        cleanup(for: taskIdentifier)
    }

    func completeUpload(for taskIdentifier: Int, data: Data?, response: URLResponse?, error: Error?) {
        if let error {
            uploadContinuationMap[taskIdentifier]?.resume(throwing: error)
        } else if let data, let response {
            uploadContinuationMap[taskIdentifier]?.resume(returning: (data, response))
        }
        cleanup(for: taskIdentifier)
    }

    private func cleanup(for taskIdentifier: Int) {
        progressHandlers.removeValue(forKey: taskIdentifier)
        downloadContinuationMap.removeValue(forKey: taskIdentifier)
        uploadContinuationMap.removeValue(forKey: taskIdentifier)
    }
}
