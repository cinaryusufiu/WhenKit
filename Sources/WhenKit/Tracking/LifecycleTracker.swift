//
//  LifecycleTracker.swift
//  WhenKit
//
//  Created by Yusuf Cinar on 12.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Tracks app lifecycle events automatically:
/// - app_install (first launch ever)
/// - app_update (version changed since last launch)
/// - app_open (every launch)
final class LifecycleTracker {
    private weak var whenKit: WhenKit?
    private let storage: StorageProvider

    private let installedVersionKey = "whenkit_installed_version"
    private let firstInstallKey = "whenkit_first_install"
    private let launchCountKey = "whenkit_launch_count"

    init(whenKit: WhenKit, storage: StorageProvider) {
        self.whenKit = whenKit
        self.storage = storage
    }

    /// Checks install/update status and fires appropriate events.
    func track() {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let currentBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"

        // Increment launch count
        let launchCount: Int = storage.get(forKey: launchCountKey) ?? 0
        storage.set(launchCount + 1, forKey: launchCountKey)

        let storedVersion: String? = storage.get(forKey: installedVersionKey)

        if storedVersion == nil {
            // First install
            storage.set(currentVersion, forKey: installedVersionKey)
            storage.set(Date().timeIntervalSince1970, forKey: firstInstallKey)

            whenKit?.trigger(.appInstall, metadata: [
                "version": currentVersion,
                "build": currentBuild,
                "source": "automatic"
            ])
            WhenKitLogger.info("First install detected: v\(currentVersion)")

        } else if storedVersion != currentVersion {
            // App updated
            let previousVersion = storedVersion ?? "unknown"
            storage.set(currentVersion, forKey: installedVersionKey)

            whenKit?.trigger(.appUpdate, metadata: [
                "previous_version": previousVersion,
                "new_version": currentVersion,
                "build": currentBuild,
                "source": "automatic"
            ])
            WhenKitLogger.info("App update detected: \(previousVersion) → \(currentVersion)")
        }

        // Always fire app_open
        whenKit?.trigger(.appOpen, metadata: [
            "version": currentVersion,
            "build": currentBuild,
            "launch_count": "\(launchCount + 1)",
            "source": "automatic"
        ])
    }

    /// Returns the number of times the app has been launched.
    var launchCount: Int {
        storage.get(forKey: launchCountKey) ?? 0
    }

    /// Returns the date of first install, if available.
    var firstInstallDate: Date? {
        guard let timestamp: Double = storage.get(forKey: firstInstallKey) else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }

    /// Returns the number of days since first install.
    var daysSinceInstall: Int {
        guard let installDate = firstInstallDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
    }
}
