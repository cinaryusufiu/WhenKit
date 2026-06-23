//
//  ValueCondition.swift
//  WhenKit
//
//  Created by Yusuf Cinar on 9.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import Foundation

/// Checks if the current trigger event's value meets a threshold.
public struct ValueCondition: Condition {
    public let eventName: String
    public let op: ComparisonOperator
    public let threshold: Double

    public init(eventName: String, op: ComparisonOperator, threshold: Double) {
        self.eventName = eventName
        self.op = op
        self.threshold = threshold
    }

    public func evaluate(context: EvaluationContext) -> Bool {
        if context.currentEvent.name == eventName {
            guard let value = context.currentEvent.value else { return false }
            return op.evaluate(value, threshold)
        }
        // Check historical events for the latest matching event
        guard let latestEvent = context.events(named: eventName).last,
              let value = latestEvent.value else {
            return false
        }
        return op.evaluate(value, threshold)
    }

    public var description: String {
        "value(\(eventName)) \(op.rawValue) \(threshold)"
    }
}
