//
//  OrCondition.swift
//  WhenKit
//
//  Created by Yusuf Cinar on 10.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import Foundation

/// Evaluates to true if ANY of the inner conditions are met.
public struct OrCondition: Condition {
    public let conditions: [Condition]

    public init(_ conditions: [Condition]) {
        self.conditions = conditions
    }

    public func evaluate(context: EvaluationContext) -> Bool {
        conditions.contains { $0.evaluate(context: context) }
    }

    public var description: String {
        "or(\(conditions.map(\.description).joined(separator: ", ")))"
    }
}
