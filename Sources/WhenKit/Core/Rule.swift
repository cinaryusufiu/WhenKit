//
//  Rule.swift
//  WhenKit
//
//  Created by Yusuf Cinar on 8.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import Foundation

/// Represents a named rule with conditions and cooldown settings.
public struct Rule {
    public let name: String
    public let conditions: [Condition]
    public let cooldownInterval: TimeInterval?

    public init(name: String, conditions: [Condition] = [], cooldownInterval: TimeInterval? = nil) {
        self.name = name
        self.conditions = conditions
        self.cooldownInterval = cooldownInterval
    }

    /// Evaluates all conditions against the given context.
    /// Returns `true` if every condition is satisfied.
    public func evaluate(context: EvaluationContext) -> Bool {
        guard !conditions.isEmpty else { return false }
        return conditions.allSatisfy { $0.evaluate(context: context) }
    }
}
