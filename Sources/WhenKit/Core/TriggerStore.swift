//
//  TriggerStore.swift
//  WhenKit
//
//  Created by Yusuf Cinar on 8.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import Foundation

/// In-memory + persistent store for trigger event counts and history.
/// Thread-safe: all mutations are guarded by an internal lock.
final class TriggerStore {
    private let storage: StorageProvider
    private var counts: [String: Int] = [:]
    private var events: [TriggerEvent] = []
    private var sessionCount: Int = 0
    private let lock = NSLock()

    /// Max events kept in history to prevent unbounded growth.
    private let maxEventHistory = 1000

    private let countsKey = "whenkit_trigger_counts"
    private let sessionCountKey = "whenkit_session_count"
    private let eventsKey = "whenkit_events"

    init(storage: StorageProvider) {
        self.storage = storage
        loadFromStorage()
    }

    func record(event: TriggerEvent) {
        lock.lock()
        defer { lock.unlock() }

        counts[event.name, default: 0] += 1
        events.append(event)
        pruneEventsIfNeeded()
        saveToStorage()
    }

    func incrementSession() {
        lock.lock()
        defer { lock.unlock() }

        sessionCount += 1
        storage.set(sessionCount, forKey: sessionCountKey)
    }

    func count(for name: String) -> Int {
        lock.lock()
        defer { lock.unlock() }
        return counts[name] ?? 0
    }

    func allCounts() -> [String: Int] {
        lock.lock()
        defer { lock.unlock() }
        return counts
    }

    func allEvents() -> [TriggerEvent] {
        lock.lock()
        defer { lock.unlock() }
        return events
    }

    func currentSessionCount() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return sessionCount
    }

    func reset() {
        lock.lock()
        defer { lock.unlock() }

        counts = [:]
        events = []
        sessionCount = 0
        storage.remove(forKey: countsKey)
        storage.remove(forKey: sessionCountKey)
        storage.remove(forKey: eventsKey)
    }

    // Removes oldest events when history exceeds the limit.
    // Counts are preserved -- only the event detail list is pruned.
    private func pruneEventsIfNeeded() {
        guard events.count > maxEventHistory else { return }
        let overflow = events.count - maxEventHistory
        events.removeFirst(overflow)
        WhenKitLogger.debug("Pruned \(overflow) old events from history")
    }

    private func loadFromStorage() {
        if let data: Data = storage.get(forKey: countsKey) {
            do {
                counts = try JSONDecoder().decode([String: Int].self, from: data)
            } catch {
                WhenKitLogger.warning("Failed to decode trigger counts: \(error.localizedDescription)")
            }
        }

        sessionCount = storage.get(forKey: sessionCountKey) ?? 0

        if let data: Data = storage.get(forKey: eventsKey) {
            do {
                events = try JSONDecoder().decode([TriggerEvent].self, from: data)
            } catch {
                WhenKitLogger.warning("Failed to decode event history: \(error.localizedDescription)")
            }
        }
    }

    private func saveToStorage() {
        do {
            let countsData = try JSONEncoder().encode(counts)
            storage.set(countsData, forKey: countsKey)
        } catch {
            WhenKitLogger.warning("Failed to encode trigger counts: \(error.localizedDescription)")
        }

        do {
            let eventsData = try JSONEncoder().encode(events)
            storage.set(eventsData, forKey: eventsKey)
        } catch {
            WhenKitLogger.warning("Failed to encode event history: \(error.localizedDescription)")
        }
    }
}
