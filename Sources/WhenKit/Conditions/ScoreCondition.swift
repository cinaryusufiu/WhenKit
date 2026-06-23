//
//  ScoreCondition.swift
//  WhenKit
//
//  Created by Yusuf Cinar on 9.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import Foundation

/// Checks if the engagement score meets a threshold.
public struct ScoreCondition: Condition {
    public let op: ComparisonOperator
    public let threshold: Double

    public init(op: ComparisonOperator, threshold: Double) {
        self.op = op
        self.threshold = threshold
    }

    public func evaluate(context: EvaluationContext) -> Bool {
        op.evaluate(context.score, threshold)
    }

    public var description: String {
        "score \(op.rawValue) \(threshold)"
    }
}
