//
//  SequenceCondition.swift
//  WhenKit
//
//  Created by Yusuf Cinar on 10.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import Foundation

/// Evaluates to true if the given events occurred in the specified order.
public struct SequenceCondition: Condition {
    public let eventNames: [String]

    public init(eventNames: [String]) {
        self.eventNames = eventNames
    }

    public func evaluate(context: EvaluationContext) -> Bool {
        guard eventNames.count >= 2 else { return true }

        var lastTimestamp: Date = .distantPast
        for name in eventNames {
            guard let event = context.events(named: name).first(where: { $0.timestamp > lastTimestamp }) else {
                return false
            }
            lastTimestamp = event.timestamp
        }
        return true
    }

    public var description: String {
        "sequence([\(eventNames.joined(separator: " → "))])"
    }
}
