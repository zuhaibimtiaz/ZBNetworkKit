//
//  Log.swift
//  ZBNetworkKit
//
//  Created by Zuhaib Imtiaz on 08/03/2025.
//

#if canImport(OSLog) && os(iOS) || os(macOS)
import OSLog
#endif

public enum Log {
    public enum Level {
        case error
        case warning
        case info
        
        fileprivate var prefix: String {
            switch self {
            case .error: return "ERROR ❌"
            case .warning: return "WARNING ⚠️"
            case .info: return "INFO ℹ️"
            }
        }
    }
    
    public struct Context {
        let file: String
        let function: String
        let line: Int
        
        var fileName: String {
            return "\((file as NSString).lastPathComponent)"
        }
        
        var description: String {
            return "\(fileName): \(line) \(function)"
        }
    }
    
    #if canImport(OSLog) && os(iOS) || os(macOS)
    @available(iOS 14.0, macOS 11.0, *)
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CustomLogger", category: "main")
    #endif
    
    // Public logging methods
    public static func info(_ message: String,
                          shouldLogContext: Bool = true,
                          file: String = #file,
                          function: String = #function,
                          line: Int = #line) {
        let context = Context(file: file, function: function, line: line)
        handleLog(level: .info, message: message, shouldLogContext: shouldLogContext, context: context)
    }
    
    public static func warning(_ message: String,
                             shouldLogContext: Bool = true,
                             file: String = #file,
                             function: String = #function,
                             line: Int = #line) {
        let context = Context(file: file, function: function, line: line)
        handleLog(level: .warning, message: message, shouldLogContext: shouldLogContext, context: context)
    }
    
    public static func error(_ message: String,
                           shouldLogContext: Bool = true,
                           file: String = #file,
                           function: String = #function,
                           line: Int = #line) {
        let context = Context(file: file, function: function, line: line)
        handleLog(level: .error, message: message, shouldLogContext: shouldLogContext, context: context)
    }
    
    // Private implementation
    private static func handleLog(level: Level,
                                message: String,
                                shouldLogContext: Bool,
                                context: Context) {
        let messageWithPrefix = "[\(level.prefix)] \(message)"
        let fullMessage = shouldLogContext ? "\(messageWithPrefix) → \(context.description)" : messageWithPrefix
        
        #if canImport(OSLog) && os(iOS) || os(macOS)
        if #available(iOS 14.0, macOS 11.0, *) {
            switch level {
            case .error:
                logger.error("\(fullMessage, privacy: .public)")
            case .warning:
                logger.warning("\(fullMessage, privacy: .public)")
            case .info:
                logger.info("\(fullMessage, privacy: .public)")
            }
        } else {
            #if DEBUG
            debugPrint(fullMessage)
            #endif
        }
        #else
        #if DEBUG
        debugPrint(fullMessage)
        #endif
        #endif
    }
}
