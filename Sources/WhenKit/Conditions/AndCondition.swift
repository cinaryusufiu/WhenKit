//
//  AndCondition.swift
//  WhenKit
//
//  Created by Yusuf Cinar on 10.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import Foundation

/// Evaluates to true only if ALL inner conditions are met.
public struct AndCondition: Condition {
    public let conditions: [Condition]

    public init(_ conditions: [Condition]) {
        self.conditions = conditions
    }

    public func evaluate(context: EvaluationContext) -> Bool {
        conditions.allSatisfy { $0.evaluate(context: context) }
    }

    public var description: String {
        "and(\(conditions.map(\.description).joined(separator: ", ")))"
    }
}
