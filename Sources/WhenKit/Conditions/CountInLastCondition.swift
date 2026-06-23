//
//  CountInLastCondition.swift
//  WhenKit
//
//  Created by Yusuf Cinar on 10.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import Foundation

/// Checks if an event occurred N times within the last X days.
public struct CountInLastCondition: Condition {
    public let eventName: String
    public let days: Int
    public let op: ComparisonOperator
    public let threshold: Int

    public init(eventName: String, days: Int, op: ComparisonOperator, threshold: Int) {
        self.eventName = eventName
        self.days = days
        self.op = op
        self.threshold = threshold
    }

    public func evaluate(context: EvaluationContext) -> Bool {
        let recentCount = context.events(named: eventName, inLast: days).count
        return op.evaluate(recentCount, threshold)
    }

    public var description: String {
        "countInLast(\(eventName), \(days)d) \(op.rawValue) \(threshold)"
    }
}
