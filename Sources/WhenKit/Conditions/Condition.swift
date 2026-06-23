//
//  Condition.swift
//  WhenKit
//
//  Created by Yusuf Cinar on 9.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import Foundation

/// Protocol that all rule conditions must conform to.
public protocol Condition {
    /// Evaluates whether this condition is met given the current context.
    func evaluate(context: EvaluationContext) -> Bool

    /// A human-readable description of this condition.
    var description: String { get }
}
