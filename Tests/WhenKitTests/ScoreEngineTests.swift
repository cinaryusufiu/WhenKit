//
//  ScoreEngineTests.swift
//  WhenKitTests
//
//  Created by Yusuf Cinar on 14.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import XCTest
@testable import WhenKit

final class ScoreEngineTests: XCTestCase {
    func testDefaultWeightScoring() {
        let engine = ScoreEngine()
        let score = engine.computeScore(counts: ["a": 3, "b": 2])
        XCTAssertEqual(score, 5.0) // default weight 1.0 each
    }

    func testCustomWeightScoring() {
        let engine = ScoreEngine()
        engine.setWeight(for: "purchase", weight: 10.0)
        engine.setWeight(for: "view", weight: 1.0)
        let score = engine.computeScore(counts: ["purchase": 2, "view": 5])
        XCTAssertEqual(score, 25.0) // 2*10 + 5*1
    }

    func testEmptyCountsScore() {
        let engine = ScoreEngine()
        let score = engine.computeScore(counts: [:])
        XCTAssertEqual(score, 0.0)
    }
}
