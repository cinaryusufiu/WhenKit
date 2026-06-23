//
//  WhenKitConfig.swift
//  WhenKit
//
//  Created by Yusuf Cinar on 13.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import Foundation

/// Configuration for the WhenKit SDK.
public struct WhenKitConfig {
    public let isDebugEnabled: Bool
    public let sessionTimeoutMinutes: Int
    public let autoScreenTracking: Bool

    public init(
        isDebugEnabled: Bool = false,
        sessionTimeoutMinutes: Int = 30,
        autoScreenTracking: Bool = false
    ) {
        self.isDebugEnabled = isDebugEnabled
        self.sessionTimeoutMinutes = sessionTimeoutMinutes
        self.autoScreenTracking = autoScreenTracking
    }
}
