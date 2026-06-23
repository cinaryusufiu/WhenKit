//
//  EvaluationContext.swift
//  WhenKit
//
//  Created by Yusuf Cinar on 8.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import Foundation

/// Snapshot of the current state used when evaluating conditions.
public struct EvaluationContext {
    /// Total count of each trigger event name.
    public let counts: [String: Int]

    /// All recorded trigger events, ordered by timestamp.
    public let events: [TriggerEvent]

    /// Number of sessions recorded.
    public let sessionCount: Int

    /// Current engagement score.
    public let score: Double

    /// The event that just occurred and triggered the evaluation.
    public let currentEvent: TriggerEvent

    public init(
        counts: [String: Int],
        events: [TriggerEvent],
        sessionCount: Int,
        score: Double,
        currentEvent: TriggerEvent
    ) {
        self.counts = counts
        self.events = events
        self.sessionCount = sessionCount
        self.score = score
        self.currentEvent = currentEvent
    }

    /// Returns the count for a specific trigger name.
    public func count(for name: String) -> Int {
        counts[name] ?? 0
    }

    /// Returns events filtered by name, within a given time window.
    public func events(named name: String, inLast days: Int) -> [TriggerEvent] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date.distantPast
        return events.filter { $0.name == name && $0.timestamp >= cutoff }
    }

    /// Returns all events matching a given name.
    public func events(named name: String) -> [TriggerEvent] {
        events.filter { $0.name == name }
    }
}
