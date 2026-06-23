//
//  CrashDetector.swift
//  WhenKit
//
//  Created by Yusuf Cinar on 12.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import Foundation

/// Automatically detects crashes and records them as trigger events.
/// Uses POSIX signal handlers and NSException handler.
final class CrashDetector {
    private weak var whenKit: WhenKit?
    private let storage: StorageProvider
    private let crashFlagKey = "whenkit_pending_crash"
    private static var shared: CrashDetector?

    init(whenKit: WhenKit, storage: StorageProvider) {
        self.whenKit = whenKit
        self.storage = storage
        CrashDetector.shared = self
    }

    /// Starts monitoring for crashes.
    func start() {
        // Check if there was a crash in the previous session
        checkPendingCrash()

        // Register signal handlers for common crash signals
        signal(SIGABRT) { _ in CrashDetector.handleCrash(signal: "SIGABRT") }
        signal(SIGILL)  { _ in CrashDetector.handleCrash(signal: "SIGILL") }
        signal(SIGSEGV) { _ in CrashDetector.handleCrash(signal: "SIGSEGV") }
        signal(SIGFPE)  { _ in CrashDetector.handleCrash(signal: "SIGFPE") }
        signal(SIGBUS)  { _ in CrashDetector.handleCrash(signal: "SIGBUS") }
        signal(SIGPIPE) { _ in CrashDetector.handleCrash(signal: "SIGPIPE") }

        // Register NSException handler
        NSSetUncaughtExceptionHandler { exception in
            CrashDetector.handleException(exception)
        }

        WhenKitLogger.debug("CrashDetector started")
    }

    /// Checks if a crash was recorded in a previous session and logs it.
    private func checkPendingCrash() {
        guard let crashData: String = storage.get(forKey: crashFlagKey), !crashData.isEmpty else {
            return
        }

        // Previous session crashed — record it
        WhenKitLogger.info("Previous session crash detected: \(crashData)")
        whenKit?.trigger(.crash, metadata: ["signal": crashData, "source": "automatic"])
        storage.remove(forKey: crashFlagKey)
    }

    /// Called when a crash signal is received. Writes crash flag synchronously.
    private static func handleCrash(signal signalName: String) {
        guard let detector = CrashDetector.shared else { return }
        // Write crash flag synchronously — we're about to die
        detector.storage.set(signalName, forKey: detector.crashFlagKey)
    }

    /// Called when an uncaught NSException occurs.
    private static func handleException(_ exception: NSException) {
        guard let detector = CrashDetector.shared else { return }
        let reason = exception.reason ?? "unknown"
        let info = "\(exception.name.rawValue): \(reason)"
        detector.storage.set(info, forKey: detector.crashFlagKey)
    }
}
