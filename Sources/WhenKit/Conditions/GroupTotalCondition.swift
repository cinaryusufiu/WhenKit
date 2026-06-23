//
//  GroupTotalCondition.swift
//  WhenKit
//
//  Created by Yusuf Cinar on 10.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import Foundation

/// Checks if the total count across multiple trigger event names meets a threshold.
public struct GroupTotalCondition: Condition {
    public let eventNames: [String]
    public let op: ComparisonOperator
    public let threshold: Int

    public init(eventNames: [String], op: ComparisonOperator, threshold: Int) {
        self.eventNames = eventNames
        self.op = op
        self.threshold = threshold
    }

    public func evaluate(context: EvaluationContext) -> Bool {
        let total = eventNames.reduce(0) { $0 + context.count(for: $1) }
        return op.evaluate(total, threshold)
    }

    public var description: String {
        "groupTotal([\(eventNames.joined(separator: ", "))]) \(op.rawValue) \(threshold)"
    }
}
