//
//  CooldownTests.swift
//  WhenKitTests
//
//  Created by Yusuf Cinar on 14.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import XCTest
@testable import WhenKit

final class CooldownTests: XCTestCase {
    func testNotInCooldownInitially() {
        let storage = InMemoryStorage()
        let manager = CooldownManager(storage: storage)
        XCTAssertFalse(manager.isInCooldown(ruleName: "test"))
    }

    func testInCooldownAfterTrigger() {
        let storage = InMemoryStorage()
        let manager = CooldownManager(storage: storage)
        manager.recordTrigger(ruleName: "test", cooldownInterval: 86400) // 1 day
        XCTAssertTrue(manager.isInCooldown(ruleName: "test"))
    }

    func testResetCooldown() {
        let storage = InMemoryStorage()
        let manager = CooldownManager(storage: storage)
        manager.recordTrigger(ruleName: "test", cooldownInterval: 86400)
        XCTAssertTrue(manager.isInCooldown(ruleName: "test"))
        manager.resetCooldown(ruleName: "test")
        XCTAssertFalse(manager.isInCooldown(ruleName: "test"))
    }
}
