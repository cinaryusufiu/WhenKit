//
//  RuleBuilder.swift
//  WhenKit
//
//  Created by Yusuf Cinar on 11.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import Foundation

/// DSL builder for constructing rules.
///
/// ```swift
/// WhenKit.shared.addRule("happy_buyer") { rule in
///     rule.when(RuleBuilder.count(.purchase, .gte, 2))
///     rule.when(RuleBuilder.never(.crash))
///     rule.or([
///         RuleBuilder.count("share", .gte, 1),
///         RuleBuilder.score(.gte, 50.0)
///     ])
///     rule.cooldown(months: 6)
/// }
/// ```
public class RuleBuilder {
    private var conditions: [Condition] = []
    private var cooldownInterval: TimeInterval?

    @discardableResult
    public func when(_ condition: Condition) -> RuleBuilder {
        conditions.append(condition)
        return self
    }

    // MARK: - Logical combinators

    @discardableResult
    public func and(_ conditions: [Condition]) -> RuleBuilder {
        self.conditions.append(AndCondition(conditions))
        return self
    }

    @discardableResult
    public func or(_ conditions: [Condition]) -> RuleBuilder {
        self.conditions.append(OrCondition(conditions))
        return self
    }

    @discardableResult
    public func not(_ condition: Condition) -> RuleBuilder {
        self.conditions.append(NotCondition(condition))
        return self
    }

    // Condition factories

    /// Event occurred N times.
    public static func count(_ event: EventKey, _ op: ComparisonOperator, _ threshold: Int) -> Condition {
        CountCondition(eventName: event.rawValue, op: op, threshold: threshold)
    }

    /// Event has never occurred.
    public static func never(_ event: EventKey) -> Condition {
        NeverCondition(eventName: event.rawValue)
    }

    /// Session count condition.
    public static func sessionCount(_ op: ComparisonOperator, _ threshold: Int) -> Condition {
        SessionCountCondition(op: op, threshold: threshold)
    }

    /// Engagement score condition.
    public static func score(_ op: ComparisonOperator, _ threshold: Double) -> Condition {
        ScoreCondition(op: op, threshold: threshold)
    }

    /// Value condition on a trigger event's value.
    public static func value(_ event: EventKey, _ op: ComparisonOperator, _ threshold: Double) -> Condition {
        ValueCondition(eventName: event.rawValue, op: op, threshold: threshold)
    }

    /// Count within a time window (last N days).
    public static func countInLast(_ event: EventKey, days: Int, _ op: ComparisonOperator, _ threshold: Int) -> Condition {
        CountInLastCondition(eventName: event.rawValue, days: days, op: op, threshold: threshold)
    }

    /// Events must occur in the specified order.
    public static func sequence(_ events: [EventKey]) -> Condition {
        SequenceCondition(eventNames: events.map(\.rawValue))
    }

    /// Sum of multiple event counts meets a threshold.
    public static func groupTotal(_ events: [EventKey], _ op: ComparisonOperator, _ threshold: Int) -> Condition {
        GroupTotalCondition(eventNames: events.map(\.rawValue), op: op, threshold: threshold)
    }

    /// Creates an AND condition from multiple conditions.
    public static func and(_ conditions: [Condition]) -> Condition {
        AndCondition(conditions)
    }

    /// Creates an OR condition from multiple conditions.
    public static func or(_ conditions: [Condition]) -> Condition {
        OrCondition(conditions)
    }

    /// Creates a NOT condition.
    public static func not(_ condition: Condition) -> Condition {
        NotCondition(condition)
    }

    // MARK: - Cooldown

    @discardableResult
    public func cooldown(days: Int) -> RuleBuilder {
        self.cooldownInterval = TimeInterval(days) * 86400
        return self
    }

    @discardableResult
    public func cooldown(hours: Int) -> RuleBuilder {
        self.cooldownInterval = TimeInterval(hours) * 3600
        return self
    }

    @discardableResult
    public func cooldown(minutes: Int) -> RuleBuilder {
        self.cooldownInterval = TimeInterval(minutes) * 60
        return self
    }

    @discardableResult
    public func cooldown(weeks: Int) -> RuleBuilder {
        self.cooldownInterval = TimeInterval(weeks) * 7 * 86400
        return self
    }

    /// Uses 30-day months.
    @discardableResult
    public func cooldown(months: Int) -> RuleBuilder {
        self.cooldownInterval = TimeInterval(months) * 30 * 86400
        return self
    }

    @discardableResult
    public func cooldown(seconds: TimeInterval) -> RuleBuilder {
        self.cooldownInterval = seconds
        return self
    }

    func build(name: String) -> Rule {
        Rule(name: name, conditions: conditions, cooldownInterval: cooldownInterval)
    }
}
