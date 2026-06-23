//
//  ComparisonOperator.swift
//  WhenKit
//
//  Created by Yusuf Cinar on 8.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import Foundation

/// Comparison operators used in rule conditions.
public enum ComparisonOperator: String, Codable {
    case gte = ">="
    case gt = ">"
    case lte = "<="
    case lt = "<"
    case eq = "=="
    case neq = "!="

    public func evaluate<T: Comparable>(_ lhs: T, _ rhs: T) -> Bool {
        switch self {
        case .gte: return lhs >= rhs
        case .gt:  return lhs > rhs
        case .lte: return lhs <= rhs
        case .lt:  return lhs < rhs
        case .eq:  return lhs == rhs
        case .neq: return lhs != rhs
        }
    }
}
