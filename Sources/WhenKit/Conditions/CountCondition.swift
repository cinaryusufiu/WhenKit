//
//  CountCondition.swift
//  WhenKit
//
//  Created by Yusuf Cinar on 9.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import Foundation

/// Checks if a trigger event has occurred a certain number of times.
public struct CountCondition: Condition {
    public let eventName: String
    public let op: ComparisonOperator
    public let threshold: Int

    public init(eventName: String, op: ComparisonOperator, threshold: Int) {
        self.eventName = eventName
        self.op = op
        self.threshold = threshold
    }

    public func evaluate(context: EvaluationContext) -> Bool {
        let count = context.count(for: eventName)
        return op.evaluate(count, threshold)
    }

    public var description: String {
        "count(\(eventName)) \(op.rawValue) \(threshold)"
    }
}
