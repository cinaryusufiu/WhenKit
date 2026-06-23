//
//  WhenKitLogger.swift
//  WhenKit
//
//  Created by Yusuf Cinar on 9.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import Foundation

/// Logger for debug output in the WhenKit SDK.
/// Logging is disabled by default; enable via `WhenKitConfig(isDebugEnabled: true)`.
public final class WhenKitLogger {
    /// Controls whether log output is emitted. Set internally during initialization.
    static var isEnabled: Bool = false

    public enum Level: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARN"
        case error = "ERROR"
    }

    static func log(_ message: String, level: Level = .debug, file: String = #file, line: Int = #line) {
        guard isEnabled else { return }
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        print("[WhenKit][\(level.rawValue)] \(fileName):\(line) — \(message)")
    }

    static func debug(_ message: String, file: String = #file, line: Int = #line) {
        log(message, level: .debug, file: file, line: line)
    }

    static func info(_ message: String, file: String = #file, line: Int = #line) {
        log(message, level: .info, file: file, line: line)
    }

    static func warning(_ message: String, file: String = #file, line: Int = #line) {
        log(message, level: .warning, file: file, line: line)
    }

    static func error(_ message: String, file: String = #file, line: Int = #line) {
        log(message, level: .error, file: file, line: line)
    }
}
