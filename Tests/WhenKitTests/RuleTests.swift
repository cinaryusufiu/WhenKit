//
//  RuleTests.swift
//  WhenKitTests
//
//  Created by Yusuf Cinar on 14.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import XCTest
@testable import WhenKit

final class RuleTests: XCTestCase {
    private func makeEvent(name: String, value: Double? = nil) -> TriggerEvent {
        TriggerEvent(name: name, value: value)
    }

    func testRuleAllConditionsMet() {
        let rule = Rule(name: "happy_buyer", conditions: [
            CountCondition(eventName: "purchase", op: .gte, threshold: 2),
            CountCondition(eventName: "delivery", op: .gte, threshold: 1),
            NeverCondition(eventName: "crash")
        ])

        let context = EvaluationContext(
            counts: ["purchase": 3, "delivery": 1],
            events: [],
            sessionCount: 5,
            score: 0,
            currentEvent: makeEvent(name: "delivery")
        )

        XCTAssertTrue(rule.evaluate(context: context))
    }

    func testRuleOneConditionFails() {
        let rule = Rule(name: "happy_buyer", conditions: [
            CountCondition(eventName: "purchase", op: .gte, threshold: 2),
            NeverCondition(eventName: "crash")
        ])

        let context = EvaluationContext(
            counts: ["purchase": 3, "crash": 1],
            events: [],
            sessionCount: 5,
            score: 0,
            currentEvent: makeEvent(name: "purchase")
        )

        XCTAssertFalse(rule.evaluate(context: context))
    }

    func testRuleBuilderDSL() {
        let builder = RuleBuilder()
        builder
            .when(RuleBuilder.count("purchase", .gte, 2))
            .when(RuleBuilder.never("crash"))
            .when(RuleBuilder.sessionCount(.gte, 5))
            .cooldown(days: 30)

        let rule = builder.build(name: "test_rule")

        XCTAssertEqual(rule.name, "test_rule")
        XCTAssertEqual(rule.conditions.count, 3)
        XCTAssertEqual(rule.cooldownInterval, 30 * 86400)
    }

    // MARK: - And/Or/Not DSL

    func testRuleBuilderOrCondition() {
        let builder = RuleBuilder()
        builder
            .when(RuleBuilder.count("purchase", .gte, 1))
            .or([
                RuleBuilder.count("share", .gte, 1),
                RuleBuilder.score(.gte, 50.0)
            ])

        let rule = builder.build(name: "or_rule")
        XCTAssertEqual(rule.conditions.count, 2) // count + or

        // share = 0 but score = 60 → or passes
        let context = EvaluationContext(
            counts: ["purchase": 2],
            events: [],
            sessionCount: 1,
            score: 60.0,
            currentEvent: makeEvent(name: "purchase")
        )
        XCTAssertTrue(rule.evaluate(context: context))
    }

    func testRuleBuilderOrConditionFails() {
        let builder = RuleBuilder()
        builder.or([
            RuleBuilder.count("share", .gte, 5),
            RuleBuilder.score(.gte, 100.0)
        ])

        let rule = builder.build(name: "or_fail")

        let context = EvaluationContext(
            counts: ["share": 1],
            events: [],
            sessionCount: 1,
            score: 10.0,
            currentEvent: makeEvent(name: "test")
        )
        XCTAssertFalse(rule.evaluate(context: context))
    }

    func testRuleBuilderAndCondition() {
        let builder = RuleBuilder()
        builder.and([
            RuleBuilder.count("a", .gte, 1),
            RuleBuilder.count("b", .gte, 1)
        ])

        let rule = builder.build(name: "and_rule")

        let pass = EvaluationContext(
            counts: ["a": 2, "b": 3],
            events: [], sessionCount: 1, score: 0,
            currentEvent: makeEvent(name: "a")
        )
        XCTAssertTrue(rule.evaluate(context: pass))

        let fail = EvaluationContext(
            counts: ["a": 2, "b": 0],
            events: [], sessionCount: 1, score: 0,
            currentEvent: makeEvent(name: "a")
        )
        XCTAssertFalse(rule.evaluate(context: fail))
    }

    func testRuleBuilderNotCondition() {
        let builder = RuleBuilder()
        builder.not(RuleBuilder.count("crash", .gte, 1))

        let rule = builder.build(name: "not_rule")

        let pass = EvaluationContext(
            counts: [:], events: [], sessionCount: 1, score: 0,
            currentEvent: makeEvent(name: "test")
        )
        XCTAssertTrue(rule.evaluate(context: pass))

        let fail = EvaluationContext(
            counts: ["crash": 2], events: [], sessionCount: 1, score: 0,
            currentEvent: makeEvent(name: "test")
        )
        XCTAssertFalse(rule.evaluate(context: fail))
    }

    // MARK: - Static factories for And/Or/Not

    func testStaticOrFactory() {
        let condition = RuleBuilder.or([
            RuleBuilder.count("a", .gte, 10),
            RuleBuilder.count("b", .gte, 1)
        ])

        let context = EvaluationContext(
            counts: ["b": 5], events: [], sessionCount: 1, score: 0,
            currentEvent: makeEvent(name: "b")
        )
        XCTAssertTrue(condition.evaluate(context: context))
    }

    // MARK: - Flexible Cooldown

    func testCooldownHours() {
        let builder = RuleBuilder()
        builder.when(RuleBuilder.count("x", .gte, 1))
            .cooldown(hours: 12)

        let rule = builder.build(name: "hours_rule")
        XCTAssertEqual(rule.cooldownInterval, 12 * 3600)
    }

    func testCooldownMinutes() {
        let builder = RuleBuilder()
        builder.when(RuleBuilder.count("x", .gte, 1))
            .cooldown(minutes: 90)

        let rule = builder.build(name: "min_rule")
        XCTAssertEqual(rule.cooldownInterval, 90 * 60)
    }

    func testCooldownWeeks() {
        let builder = RuleBuilder()
        builder.when(RuleBuilder.count("x", .gte, 1))
            .cooldown(weeks: 2)

        let rule = builder.build(name: "week_rule")
        XCTAssertEqual(rule.cooldownInterval, 2 * 7 * 86400)
    }

    func testCooldownMonths() {
        let builder = RuleBuilder()
        builder.when(RuleBuilder.count("x", .gte, 1))
            .cooldown(months: 6)

        let rule = builder.build(name: "month_rule")
        XCTAssertEqual(rule.cooldownInterval, 6 * 30 * 86400)
    }

    func testCooldownCustomSeconds() {
        let builder = RuleBuilder()
        builder.when(RuleBuilder.count("x", .gte, 1))
            .cooldown(seconds: 7200)

        let rule = builder.build(name: "custom_rule")
        XCTAssertEqual(rule.cooldownInterval, 7200)
    }
}
