//
//  File.swift
//  ZBNetworkKit
//
//  Created by Zuhaib Imtiaz on 6/23/25.
//

import Foundation

//extension ZBHttpClient: URLSessionTaskDelegate, URLSessionDownloadDelegate {
//    public func urlSession(
//        _ session: URLSession,
//        task: URLSessionTask,
//        didSendBodyData bytesSent: Int64,
//        totalBytesSent: Int64,
//        totalBytesExpectedToSend: Int64
//    ) {
//        let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
////        Task { await tracker.updateProgress(for: task.taskIdentifier, progress: progress) }
//    }
//
//    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
//                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
//        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
//        Task { await tracker.updateProgress(for: downloadTask.taskIdentifier, progress: progress) }
//    }
//
//    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
//                    didFinishDownloadingTo location: URL) {
//        Task {
//            await tracker.resumeDownloadContinuation(for: downloadTask.taskIdentifier, with: .success(location))
//        }
//    }
//
//    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
//        Task {
//            if let error = error {
//                await tracker.resumeDownloadContinuation(for: task.taskIdentifier, with: .failure(error))
////                await tracker.resumeUploadContinuation(for: task.taskIdentifier, with: .failure(error))
//            }
//            await tracker.clearHandlers(for: task.taskIdentifier)
//        }
//    }
//
////    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
////        Task {
////            await tracker.resumeUploadContinuation(for: dataTask.taskIdentifier, with: .success(data))
////        }
////    }
//}

extension ZBHttpClient: URLSessionDelegate, URLSessionDownloadDelegate, URLSessionTaskDelegate {
    // Existing download delegate methods
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        Task {
            await tracker.completeDownload(for: downloadTask.taskIdentifier, url: location, error: nil)
        }
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = totalBytesExpectedToWrite > 0 ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) : 0
        Task {
            await tracker.updateProgress(for: downloadTask.taskIdentifier, progress: progress)
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            if let downloadTask = task as? URLSessionDownloadTask {
                Task {
                    await tracker.completeDownload(for: downloadTask.taskIdentifier, url: nil, error: error)
                }
            } else if let uploadTask = task as? URLSessionUploadTask {
                Task {
                    await tracker.completeUpload(for: uploadTask.taskIdentifier, data: nil, response: nil, error: error)
                }
            }
        }
    }

    // New upload delegate method
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let progress = totalBytesExpectedToSend > 0 ? Double(totalBytesSent) / Double(totalBytesExpectedToSend) : 0
        Task {
            await tracker.updateProgress(for: task.taskIdentifier, progress: progress)
        }
    }
}

extension ZBHttpClient {
    
    // New data delegate method for upload response
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let uploadTask = dataTask as? URLSessionUploadTask {
            Task {
                await tracker.completeUpload(for: uploadTask.taskIdentifier, data: data, response: uploadTask.response, error: nil)
            }
        }
    }
}
