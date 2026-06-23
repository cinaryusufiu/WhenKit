//
//  SessionManager.swift
//  WhenKit
//
//  Created by Yusuf Cinar on 12.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Manages session lifecycle: tracks foreground/background transitions,
/// session duration, and session timeouts.
final class SessionManager {
    private weak var whenKit: WhenKit?
    private let storage: StorageProvider
    private let sessionTimeoutInterval: TimeInterval

    private var sessionStartTime: Date?
    private var backgroundTime: Date?
    private var currentSessionDuration: TimeInterval = 0

    private let sessionStartKey = "whenkit_session_start"
    private let totalSessionsKey = "whenkit_total_sessions"
    private let lastActiveKey = "whenkit_last_active"

    /// Session timeout in seconds. If the app is backgrounded longer than this,
    /// a new session begins on return. Default: 30 minutes.
    init(whenKit: WhenKit, storage: StorageProvider, timeoutMinutes: Int = 30) {
        self.whenKit = whenKit
        self.storage = storage
        self.sessionTimeoutInterval = TimeInterval(timeoutMinutes * 60)
    }

    /// Begin observing app lifecycle notifications.
    func start() {
        startNewSession()

        #if canImport(UIKit) && !os(watchOS)
        NotificationCenter.default.addObserver(
            self, selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(appWillTerminate),
            name: UIApplication.willTerminateNotification, object: nil
        )
        #endif

        WhenKitLogger.debug("SessionManager started (timeout: \(Int(sessionTimeoutInterval))s)")
    }

    /// Returns the total number of sessions recorded.
    var totalSessions: Int {
        let count: Int? = storage.get(forKey: totalSessionsKey)
        return count ?? 0
    }

    /// Returns the duration of the current session in seconds.
    var currentDuration: TimeInterval {
        guard let start = sessionStartTime else { return 0 }
        return Date().timeIntervalSince(start) + currentSessionDuration
    }

    private func startNewSession() {
        sessionStartTime = Date()
        currentSessionDuration = 0

        let count = totalSessions + 1
        storage.set(count, forKey: totalSessionsKey)
        storage.set(Date().timeIntervalSince1970, forKey: sessionStartKey)

        whenKit?.trigger(.sessionStart, metadata: [
            "session_number": "\(count)",
            "source": "automatic"
        ])

        WhenKitLogger.info("Session #\(count) started")
    }

    private func endSession() {
        let duration = currentDuration
        whenKit?.trigger(.sessionEnd, metadata: [
            "duration_seconds": "\(Int(duration))",
            "source": "automatic"
        ])
        storage.set(Date().timeIntervalSince1970, forKey: lastActiveKey)
        WhenKitLogger.info("Session ended (duration: \(Int(duration))s)")
    }

    @objc private func appDidEnterBackground() {
        backgroundTime = Date()
        // Accumulate duration so far
        if let start = sessionStartTime {
            currentSessionDuration += Date().timeIntervalSince(start)
        }
        whenKit?.trigger(.appBackground, metadata: ["source": "automatic"])
        WhenKitLogger.debug("App entered background")
    }

    @objc private func appWillEnterForeground() {
        guard let bgTime = backgroundTime else {
            return
        }

        let elapsed = Date().timeIntervalSince(bgTime)

        if elapsed >= sessionTimeoutInterval {
            // Session expired — end old, start new
            endSession()
            startNewSession()
        } else {
            // Resume current session
            sessionStartTime = Date()
            whenKit?.trigger(.appForeground, metadata: [
                "background_seconds": "\(Int(elapsed))",
                "source": "automatic"
            ])
        }

        backgroundTime = nil
        WhenKitLogger.debug("App entered foreground (bg duration: \(Int(elapsed))s)")
    }

    @objc private func appWillTerminate() {
        endSession()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
