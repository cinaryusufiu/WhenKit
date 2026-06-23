//
//  ScoreEngine.swift
//  WhenKit
//
//  Created by Yusuf Cinar on 11.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import Foundation

/// Computes a weighted engagement score based on trigger events.
/// Thread-safe: weight modifications and score computation are synchronized.
public final class ScoreEngine {
    private var weights: [String: Double] = [:]
    private var defaultWeight: Double = 1.0
    private let lock = NSLock()

    public init() {}

    /// Sets the weight for a specific event name.
    public func setWeight(for eventName: String, weight: Double) {
        lock.lock()
        defer { lock.unlock() }
        weights[eventName] = weight
    }

    /// Sets the default weight for events without a specific weight.
    public func setDefaultWeight(_ weight: Double) {
        lock.lock()
        defer { lock.unlock() }
        defaultWeight = weight
    }

    /// Computes the engagement score from event counts.
    public func computeScore(counts: [String: Int]) -> Double {
        lock.lock()
        defer { lock.unlock() }

        var score: Double = 0
        for (name, count) in counts {
            let weight = weights[name] ?? defaultWeight
            score += Double(count) * weight
        }
        return score
    }
}
