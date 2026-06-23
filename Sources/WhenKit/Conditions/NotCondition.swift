//
//  NotCondition.swift
//  WhenKit
//
//  Created by Yusuf Cinar on 10.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import Foundation

/// Negates the result of an inner condition.
public struct NotCondition: Condition {
    public let inner: Condition

    public init(_ inner: Condition) {
        self.inner = inner
    }

    public func evaluate(context: EvaluationContext) -> Bool {
        !inner.evaluate(context: context)
    }

    public var description: String {
        "not(\(inner.description))"
    }
}
