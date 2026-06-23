//
//  NeverCondition.swift
//  WhenKit
//
//  Created by Yusuf Cinar on 9.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import Foundation

/// Evaluates to true only if the given event has NEVER occurred.
public struct NeverCondition: Condition {
    public let eventName: String

    public init(eventName: String) {
        self.eventName = eventName
    }

    public func evaluate(context: EvaluationContext) -> Bool {
        context.count(for: eventName) == 0
    }

    public var description: String {
        "never(\(eventName))"
    }
}
