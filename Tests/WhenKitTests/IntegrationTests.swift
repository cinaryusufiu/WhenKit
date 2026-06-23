//
//  IntegrationTests.swift
//  WhenKitTests
//
//  Created by Yusuf Cinar on 15.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import XCTest
@testable import WhenKit

final class IntegrationTests: XCTestCase {
    func testFullTriggerFlow() {
        let storage = InMemoryStorage()
        let config = WhenKitConfig(isDebugEnabled: false)
        let whenKit = WhenKit.initialize(config: config, storage: storage)

        var triggeredRules: [String] = []
        whenKit.onRuleTriggered = { ruleName, info in
            triggeredRules.append(ruleName)
        }

        whenKit.addRule("happy_buyer") { rule in
            rule.when(RuleBuilder.count("purchase_completed", .gte, 2))
            rule.when(RuleBuilder.count("order_delivered", .gte, 1))
            rule.when(RuleBuilder.never("crash"))
            rule.cooldown(days: 30)
        }

        // Not enough purchases yet
        whenKit.trigger("purchase_completed")
        XCTAssertTrue(triggeredRules.isEmpty)

        // Second purchase — still missing delivery
        whenKit.trigger("purchase_completed")
        XCTAssertTrue(triggeredRules.isEmpty)

        // Delivery — all conditions met!
        whenKit.trigger("order_delivered")
        XCTAssertEqual(triggeredRules, ["happy_buyer"])

        // Second trigger should be blocked by cooldown
        triggeredRules.removeAll()
        whenKit.trigger("order_delivered")
        XCTAssertTrue(triggeredRules.isEmpty)
    }

    func testMultipleRules() {
        let storage = InMemoryStorage()
        let config = WhenKitConfig(isDebugEnabled: false)
        let whenKit = WhenKit.initialize(config: config, storage: storage)

        var triggeredRules: [String] = []
        whenKit.onRuleTriggered = { ruleName, _ in
            triggeredRules.append(ruleName)
        }

        whenKit.addRule("rule_a") { rule in
            rule.when(RuleBuilder.count("event_a", .gte, 1))
        }

        whenKit.addRule("rule_b") { rule in
            rule.when(RuleBuilder.count("event_b", .gte, 1))
        }

        whenKit.trigger("event_a")
        XCTAssertTrue(triggeredRules.contains("rule_a"))
        XCTAssertFalse(triggeredRules.contains("rule_b"))

        triggeredRules.removeAll()
        whenKit.trigger("event_b")
        XCTAssertTrue(triggeredRules.contains("rule_b"))
    }

    func testCrashBlocksRule() {
        let storage = InMemoryStorage()
        let config = WhenKitConfig(isDebugEnabled: false)
        let whenKit = WhenKit.initialize(config: config, storage: storage)

        var triggered = false
        whenKit.onRuleTriggered = { _, _ in
            triggered = true
        }

        whenKit.addRule("safe_user") { rule in
            rule.when(RuleBuilder.count("login", .gte, 1))
            rule.when(RuleBuilder.never("crash"))
        }

        whenKit.trigger("crash")
        whenKit.trigger("login")
        XCTAssertFalse(triggered)
    }

    func testEventCounting() {
        let storage = InMemoryStorage()
        let whenKit = WhenKit.initialize(config: WhenKitConfig(), storage: storage)

        whenKit.trigger("purchase")
        whenKit.trigger("purchase")
        whenKit.trigger("view")

        XCTAssertEqual(whenKit.eventCount(for: "purchase"), 2)
        XCTAssertEqual(whenKit.eventCount(for: "view"), 1)
        XCTAssertEqual(whenKit.eventCount(for: "unknown"), 0)
    }

    func testScoreCalculation() {
        let storage = InMemoryStorage()
        let whenKit = WhenKit.initialize(config: WhenKitConfig(), storage: storage)

        whenKit.setScoreWeight(for: "purchase", weight: 10.0)
        whenKit.setScoreWeight(for: "view", weight: 1.0)

        whenKit.trigger("purchase")
        whenKit.trigger("purchase")
        whenKit.trigger("view")
        whenKit.trigger("view")
        whenKit.trigger("view")

        // 2*10 + 3*1 = 23, plus automatic events (session_start, app_install, app_open)
        XCTAssertTrue(whenKit.currentScore >= 23.0)
    }
}
