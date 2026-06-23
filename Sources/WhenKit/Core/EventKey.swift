//
//  EventKey.swift
//  WhenKit
//
//  Created by Yusuf Cinar on 15.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import Foundation

/// Type-safe identifier for trigger events.
///
/// Provides autocomplete for built-in system events while still
/// accepting arbitrary strings for custom events:
///
/// ```swift
/// // System events — autocomplete supported:
/// WhenKit.shared.trigger(.appOpen)
/// RuleBuilder.never(.crash)
///
/// // Custom events — string literals work too:
/// WhenKit.shared.trigger("purchase_completed")
/// RuleBuilder.count("order_delivered", .gte, 1)
/// ```
public struct EventKey: Hashable, ExpressibleByStringLiteral, CustomStringConvertible {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    public var description: String { rawValue }

    // MARK: - System Events

    /// Fires once on the very first app launch.
    public static let appInstall = EventKey("app_install")

    /// Fires when the app version changes between launches.
    public static let appUpdate = EventKey("app_update")

    /// Fires on every app launch.
    public static let appOpen = EventKey("app_open")

    /// Fires when a new session begins.
    public static let sessionStart = EventKey("session_start")

    /// Fires when a session ends (timeout or app termination).
    public static let sessionEnd = EventKey("session_end")

    /// Fires when the app moves to the background.
    public static let appBackground = EventKey("app_background")

    /// Fires when the app returns to the foreground (within session timeout).
    public static let appForeground = EventKey("app_foreground")

    /// Fires on next launch if a crash was detected in the previous session.
    public static let crash = EventKey("crash")

    /// Fires when a screen/view controller appears.
    public static let screenView = EventKey("screen_view")
}
