//
//  CooldownManager.swift
//  WhenKit
//
//  Created by Yusuf Cinar on 10.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import Foundation

/// Manages cooldown periods for rules to prevent over-triggering.
final class CooldownManager {
    private let storage: StorageProvider
    private let prefix = "whenkit_cooldown_"
    private var trackedRules: Set<String> = []
    weak var whenKit: WhenKit?

    init(storage: StorageProvider) {
        self.storage = storage
    }

    private var currentTime: Date {
        whenKit?.now() ?? Date()
    }

    /// Checks if a rule is currently in cooldown.
    func isInCooldown(ruleName: String) -> Bool {
        guard let expiresAt: Double = storage.get(forKey: key(for: ruleName)) else {
            return false
        }
        return currentTime.timeIntervalSince1970 < expiresAt
    }

    /// Records that a rule was triggered, starting its cooldown.
    func recordTrigger(ruleName: String, cooldownInterval: TimeInterval) {
        let expiresAt = currentTime.addingTimeInterval(cooldownInterval).timeIntervalSince1970
        storage.set(expiresAt, forKey: key(for: ruleName))
        trackedRules.insert(ruleName)
    }

    /// Resets cooldown for a specific rule.
    func resetCooldown(ruleName: String) {
        storage.remove(forKey: key(for: ruleName))
        trackedRules.remove(ruleName)
    }

    /// Resets all tracked cooldowns.
    func resetAll() {
        for ruleName in trackedRules {
            storage.remove(forKey: key(for: ruleName))
        }
        trackedRules.removeAll()
    }

    private func key(for ruleName: String) -> String {
        "\(prefix)\(ruleName)"
    }
}
