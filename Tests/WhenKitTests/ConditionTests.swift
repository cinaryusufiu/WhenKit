//
//  ConditionTests.swift
//  WhenKitTests
//
//  Created by Yusuf Cinar on 14.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import XCTest
@testable import WhenKit

final class ConditionTests: XCTestCase {
    private func makeEvent(name: String, value: Double? = nil, timestamp: Date = Date()) -> TriggerEvent {
        TriggerEvent(name: name, value: value, timestamp: timestamp)
    }

    private func makeContext(
        counts: [String: Int] = [:],
        events: [TriggerEvent] = [],
        sessionCount: Int = 1,
        score: Double = 0,
        currentEvent: TriggerEvent? = nil
    ) -> EvaluationContext {
        EvaluationContext(
            counts: counts,
            events: events,
            sessionCount: sessionCount,
            score: score,
            currentEvent: currentEvent ?? makeEvent(name: "test")
        )
    }

    // MARK: - ComparisonOperator

    func testComparisonOperators() {
        XCTAssertTrue(ComparisonOperator.gte.evaluate(5, 5))
        XCTAssertTrue(ComparisonOperator.gte.evaluate(6, 5))
        XCTAssertFalse(ComparisonOperator.gte.evaluate(4, 5))

        XCTAssertTrue(ComparisonOperator.gt.evaluate(6, 5))
        XCTAssertFalse(ComparisonOperator.gt.evaluate(5, 5))

        XCTAssertTrue(ComparisonOperator.lte.evaluate(5, 5))
        XCTAssertTrue(ComparisonOperator.lte.evaluate(4, 5))
        XCTAssertFalse(ComparisonOperator.lte.evaluate(6, 5))

        XCTAssertTrue(ComparisonOperator.lt.evaluate(4, 5))
        XCTAssertFalse(ComparisonOperator.lt.evaluate(5, 5))

        XCTAssertTrue(ComparisonOperator.eq.evaluate(5, 5))
        XCTAssertFalse(ComparisonOperator.eq.evaluate(4, 5))

        XCTAssertTrue(ComparisonOperator.neq.evaluate(4, 5))
        XCTAssertFalse(ComparisonOperator.neq.evaluate(5, 5))
    }

    // MARK: - CountCondition

    func testCountConditionMet() {
        let condition = CountCondition(eventName: "purchase", op: .gte, threshold: 2)
        let context = makeContext(counts: ["purchase": 3])
        XCTAssertTrue(condition.evaluate(context: context))
    }

    func testCountConditionNotMet() {
        let condition = CountCondition(eventName: "purchase", op: .gte, threshold: 2)
        let context = makeContext(counts: ["purchase": 1])
        XCTAssertFalse(condition.evaluate(context: context))
    }

    func testCountConditionMissingEvent() {
        let condition = CountCondition(eventName: "purchase", op: .gte, threshold: 1)
        let context = makeContext(counts: [:])
        XCTAssertFalse(condition.evaluate(context: context))
    }

    // MARK: - NeverCondition

    func testNeverConditionTrue() {
        let condition = NeverCondition(eventName: "crash")
        let context = makeContext(counts: [:])
        XCTAssertTrue(condition.evaluate(context: context))
    }

    func testNeverConditionFalse() {
        let condition = NeverCondition(eventName: "crash")
        let context = makeContext(counts: ["crash": 1])
        XCTAssertFalse(condition.evaluate(context: context))
    }

    // MARK: - SessionCountCondition

    func testSessionCountMet() {
        let condition = SessionCountCondition(op: .gte, threshold: 5)
        let context = makeContext(sessionCount: 7)
        XCTAssertTrue(condition.evaluate(context: context))
    }

    func testSessionCountNotMet() {
        let condition = SessionCountCondition(op: .gte, threshold: 5)
        let context = makeContext(sessionCount: 3)
        XCTAssertFalse(condition.evaluate(context: context))
    }

    // MARK: - ScoreCondition

    func testScoreConditionMet() {
        let condition = ScoreCondition(op: .gte, threshold: 50.0)
        let context = makeContext(score: 75.0)
        XCTAssertTrue(condition.evaluate(context: context))
    }

    func testScoreConditionNotMet() {
        let condition = ScoreCondition(op: .gte, threshold: 50.0)
        let context = makeContext(score: 25.0)
        XCTAssertFalse(condition.evaluate(context: context))
    }

    // MARK: - ValueCondition

    func testValueConditionCurrentEvent() {
        let condition = ValueCondition(eventName: "purchase", op: .gte, threshold: 100.0)
        let event = makeEvent(name: "purchase", value: 149.90)
        let context = makeContext(currentEvent: event)
        XCTAssertTrue(condition.evaluate(context: context))
    }

    func testValueConditionNoValue() {
        let condition = ValueCondition(eventName: "purchase", op: .gte, threshold: 100.0)
        let event = makeEvent(name: "purchase", value: nil)
        let context = makeContext(currentEvent: event)
        XCTAssertFalse(condition.evaluate(context: context))
    }

    // MARK: - GroupTotalCondition

    func testGroupTotalMet() {
        let condition = GroupTotalCondition(eventNames: ["buy", "sell"], op: .gte, threshold: 5)
        let context = makeContext(counts: ["buy": 3, "sell": 3])
        XCTAssertTrue(condition.evaluate(context: context))
    }

    func testGroupTotalNotMet() {
        let condition = GroupTotalCondition(eventNames: ["buy", "sell"], op: .gte, threshold: 5)
        let context = makeContext(counts: ["buy": 1, "sell": 2])
        XCTAssertFalse(condition.evaluate(context: context))
    }

    // MARK: - AndCondition

    func testAndConditionAllMet() {
        let and = AndCondition([
            CountCondition(eventName: "a", op: .gte, threshold: 1),
            CountCondition(eventName: "b", op: .gte, threshold: 1)
        ])
        let context = makeContext(counts: ["a": 2, "b": 3])
        XCTAssertTrue(and.evaluate(context: context))
    }

    func testAndConditionOneFails() {
        let and = AndCondition([
            CountCondition(eventName: "a", op: .gte, threshold: 1),
            CountCondition(eventName: "b", op: .gte, threshold: 5)
        ])
        let context = makeContext(counts: ["a": 2, "b": 3])
        XCTAssertFalse(and.evaluate(context: context))
    }

    // MARK: - OrCondition

    func testOrConditionOneMet() {
        let or = OrCondition([
            CountCondition(eventName: "a", op: .gte, threshold: 10),
            CountCondition(eventName: "b", op: .gte, threshold: 1)
        ])
        let context = makeContext(counts: ["a": 1, "b": 3])
        XCTAssertTrue(or.evaluate(context: context))
    }

    func testOrConditionNoneMet() {
        let or = OrCondition([
            CountCondition(eventName: "a", op: .gte, threshold: 10),
            CountCondition(eventName: "b", op: .gte, threshold: 10)
        ])
        let context = makeContext(counts: ["a": 1, "b": 3])
        XCTAssertFalse(or.evaluate(context: context))
    }

    // MARK: - NotCondition

    func testNotCondition() {
        let not = NotCondition(CountCondition(eventName: "crash", op: .gte, threshold: 1))
        let context = makeContext(counts: [:])
        XCTAssertTrue(not.evaluate(context: context))
    }

    func testNotConditionNegated() {
        let not = NotCondition(CountCondition(eventName: "crash", op: .gte, threshold: 1))
        let context = makeContext(counts: ["crash": 2])
        XCTAssertFalse(not.evaluate(context: context))
    }

    // MARK: - CountInLastCondition

    func testCountInLastMet() {
        let recentEvent = makeEvent(name: "purchase", timestamp: Date().addingTimeInterval(-3600)) // 1 hour ago
        let condition = CountInLastCondition(eventName: "purchase", days: 7, op: .gte, threshold: 1)
        let context = makeContext(events: [recentEvent])
        XCTAssertTrue(condition.evaluate(context: context))
    }

    func testCountInLastOldEvents() {
        let oldEvent = makeEvent(name: "purchase", timestamp: Date().addingTimeInterval(-86400 * 30)) // 30 days ago
        let condition = CountInLastCondition(eventName: "purchase", days: 7, op: .gte, threshold: 1)
        let context = makeContext(events: [oldEvent])
        XCTAssertFalse(condition.evaluate(context: context))
    }

    // MARK: - SequenceCondition

    func testSequenceConditionMet() {
        let now = Date()
        let events = [
            makeEvent(name: "signup", timestamp: now.addingTimeInterval(-300)),
            makeEvent(name: "purchase", timestamp: now.addingTimeInterval(-200)),
            makeEvent(name: "review", timestamp: now.addingTimeInterval(-100))
        ]
        let condition = SequenceCondition(eventNames: ["signup", "purchase", "review"])
        let context = makeContext(events: events)
        XCTAssertTrue(condition.evaluate(context: context))
    }

    func testSequenceConditionNotMet() {
        let now = Date()
        let events = [
            makeEvent(name: "review", timestamp: now.addingTimeInterval(-300)),
            makeEvent(name: "purchase", timestamp: now.addingTimeInterval(-200)),
            makeEvent(name: "signup", timestamp: now.addingTimeInterval(-100))
        ]
        let condition = SequenceCondition(eventNames: ["signup", "purchase", "review"])
        let context = makeContext(events: events)
        // signup occurs after purchase, so we need signup before purchase
        // The sequence should fail because there's no signup before purchase
        // Actually: "signup" event at -100, "purchase" at -200
        // evaluate looks for signup first (finds at -300? no, it's "review"), then after signup finds purchase...
        // Let me re-check: events named "signup" = [at -100], events named "purchase" = [at -200]
        // Need signup first (finds at -100), then purchase after -100 — none exist
        XCTAssertFalse(condition.evaluate(context: context))
    }
}
