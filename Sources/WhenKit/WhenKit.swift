//
//  WhenKit.swift
//  WhenKit
//
//  Created by Yusuf Cinar on 13.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import Foundation

/// Information about a triggered rule, passed to the callback.
public struct TriggerInfo {
    public let ruleName: String
    public let conditionsSnapshot: [String: Int]
    public let timestamp: Date
    public let score: Double
}

/// Main entry point for the WhenKit SDK.
///
/// Evaluates conditions and calls the developer's callback -- it never shows UI
/// or takes action on its own. Fully offline, no backend or API key needed.
///
/// Thread-safe: `trigger()` and `addRule()` can be called from any thread.
/// The `onRuleTriggered` callback fires on the caller's thread.
public final class WhenKit {
    /// Shared instance (available after `initialize` is called).
    public private(set) static var shared: WhenKit!

    /// Called when a rule's conditions are met.
    /// The SDK itself takes no action -- it just calls this closure.
    public var onRuleTriggered: ((String, TriggerInfo) -> Void)?

    private let config: WhenKitConfig
    private var rules: [String: Rule] = [:]
    private let rulesLock = NSLock()
    private let triggerStore: TriggerStore
    private let cooldownManager: CooldownManager
    private let scoreEngine: ScoreEngine
    private let storage: StorageProvider

    private var crashDetector: CrashDetector?
    private var sessionManager: SessionManager?
    private var lifecycleTracker: LifecycleTracker?
    private var screenTracker: ScreenTracker?

    private var userId: String?
    private var userAttributes: [String: String] = [:]
    private var serverTimeOffset: TimeInterval = 0

    @discardableResult
    public static func initialize(config: WhenKitConfig = WhenKitConfig(), storage: StorageProvider? = nil) -> WhenKit {
        let instance = WhenKit(config: config, storage: storage)
        shared = instance
        WhenKitLogger.isEnabled = config.isDebugEnabled
        WhenKitLogger.info("WhenKit initialized (v\(WhenKitVersion.current))")
        return instance
    }

    private init(config: WhenKitConfig, storage: StorageProvider?) {
        self.config = config
        self.storage = storage ?? UserDefaultsStorage()
        self.triggerStore = TriggerStore(storage: self.storage)
        self.cooldownManager = CooldownManager(storage: self.storage)
        self.scoreEngine = ScoreEngine()
        self.cooldownManager.whenKit = self

        triggerStore.incrementSession()
        startAutomaticTracking()
    }

    private func startAutomaticTracking() {
        crashDetector = CrashDetector(whenKit: self, storage: storage)
        crashDetector?.start()

        sessionManager = SessionManager(whenKit: self, storage: storage, timeoutMinutes: config.sessionTimeoutMinutes)
        sessionManager?.start()

        lifecycleTracker = LifecycleTracker(whenKit: self, storage: storage)
        lifecycleTracker?.track()

        screenTracker = ScreenTracker(whenKit: self)
        if config.autoScreenTracking {
            screenTracker?.enableAutoTracking()
        }
    }

    /// Manually track a screen view.
    public func trackScreen(_ screenName: String, metadata: [String: String]? = nil) {
        screenTracker?.trackScreen(screenName, metadata: metadata)
    }

    public func identify(userId: String) {
        self.userId = userId
        WhenKitLogger.debug("User identified: \(userId)")
    }

    public func setUserAttribute(_ key: String, value: String) {
        userAttributes[key] = value
    }

    /// Syncs the SDK's internal clock with a trusted server time.
    /// Call this with a `Date` from your backend's response header or body.
    /// If not called, the SDK uses the device clock.
    public func syncTime(_ serverTime: Date) {
        serverTimeOffset = serverTime.timeIntervalSince1970 - Date().timeIntervalSince1970
        WhenKitLogger.debug("Time synced (offset: \(String(format: "%.1f", serverTimeOffset))s)")
    }

    /// Returns the current time adjusted by server offset if available.
    func now() -> Date {
        Date(timeIntervalSince1970: Date().timeIntervalSince1970 + serverTimeOffset)
    }

    // MARK: - Rules

    /// Adds a rule using the DSL builder.
    public func addRule(_ name: String, builder: (RuleBuilder) -> Void) {
        let ruleBuilder = RuleBuilder()
        builder(ruleBuilder)
        let rule = ruleBuilder.build(name: name)

        rulesLock.lock()
        rules[name] = rule
        rulesLock.unlock()

        WhenKitLogger.debug("Rule added: \(name) with \(rule.conditions.count) conditions")
    }

    public func removeRule(_ name: String) {
        rulesLock.lock()
        rules.removeValue(forKey: name)
        rulesLock.unlock()
    }

    /// Sets the weight for a specific event in score calculation.
    public func setScoreWeight(for event: EventKey, weight: Double) {
        scoreEngine.setWeight(for: event.rawValue, weight: weight)
    }

    /// Records a trigger event and evaluates all rules.
    /// If any rule's conditions are met, `onRuleTriggered` is called.
    public func trigger(_ event: EventKey, value: Double? = nil, metadata: [String: String]? = nil) {
        let triggerEvent = TriggerEvent(
            name: event.rawValue,
            value: value,
            metadata: metadata,
            timestamp: now(),
            userId: userId,
            platform: "ios",
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            sdkVersion: WhenKitVersion.current
        )

        triggerStore.record(event: triggerEvent)
        WhenKitLogger.debug("Trigger: \(event.rawValue)" + (value.map { ", value: \($0)" } ?? ""))

        let context = buildContext(currentEvent: triggerEvent)
        evaluateRules(context: context)
    }

    // MARK: - Query

    /// Returns the count of a specific event.
    public func eventCount(for event: EventKey) -> Int {
        triggerStore.count(for: event.rawValue)
    }

    public var totalSessions: Int {
        sessionManager?.totalSessions ?? triggerStore.currentSessionCount()
    }

    public var daysSinceInstall: Int {
        lifecycleTracker?.daysSinceInstall ?? 0
    }

    public var currentScore: Double {
        scoreEngine.computeScore(counts: triggerStore.allCounts())
    }

    public var hasCrashed: Bool {
        triggerStore.count(for: EventKey.crash.rawValue) > 0
    }

    /// Resets all stored data (counts, events, cooldowns).
    public func reset() {
        triggerStore.reset()
        cooldownManager.resetAll()
        WhenKitLogger.info("WhenKit data reset")
    }

    private func buildContext(currentEvent: TriggerEvent) -> EvaluationContext {
        let counts = triggerStore.allCounts()
        let score = scoreEngine.computeScore(counts: counts)
        return EvaluationContext(
            counts: counts,
            events: triggerStore.allEvents(),
            sessionCount: sessionManager?.totalSessions ?? triggerStore.currentSessionCount(),
            score: score,
            currentEvent: currentEvent
        )
    }

    private func evaluateRules(context: EvaluationContext) {
        rulesLock.lock()
        let currentRules = rules
        rulesLock.unlock()

        for (name, rule) in currentRules {
            if cooldownManager.isInCooldown(ruleName: name) {
                WhenKitLogger.debug("Rule '\(name)' is in cooldown, skipping")
                continue
            }

            if rule.evaluate(context: context) {
                WhenKitLogger.info("Rule '\(name)' triggered!")

                if let interval = rule.cooldownInterval {
                    cooldownManager.recordTrigger(ruleName: name, cooldownInterval: interval)
                }

                let info = TriggerInfo(
                    ruleName: name,
                    conditionsSnapshot: context.counts,
                    timestamp: now(),
                    score: context.score
                )
                onRuleTriggered?(name, info)
            }
        }
    }
}
