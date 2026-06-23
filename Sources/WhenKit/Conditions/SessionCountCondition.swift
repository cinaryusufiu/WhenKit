//
//  SessionCountCondition.swift
//  WhenKit
//
//  Created by Yusuf Cinar on 9.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import Foundation

/// Checks if the number of sessions meets a threshold.
public struct SessionCountCondition: Condition {
    public let op: ComparisonOperator
    public let threshold: Int

    public init(op: ComparisonOperator, threshold: Int) {
        self.op = op
        self.threshold = threshold
    }

    public func evaluate(context: EvaluationContext) -> Bool {
        op.evaluate(context.sessionCount, threshold)
    }

    public var description: String {
        "sessionCount \(op.rawValue) \(threshold)"
    }
}
