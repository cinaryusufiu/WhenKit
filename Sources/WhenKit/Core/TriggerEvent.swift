//
//  TriggerEvent.swift
//  WhenKit
//
//  Created by Yusuf Cinar on 8.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import Foundation

/// Represents a single trigger event recorded by the SDK.
public struct TriggerEvent: Codable {
    public let name: String
    public let value: Double?
    public let metadata: [String: String]?
    public let timestamp: Date
    public let userId: String?
    public let platform: String
    public let appVersion: String?
    public let sdkVersion: String

    public init(
        name: String,
        value: Double? = nil,
        metadata: [String: String]? = nil,
        timestamp: Date = Date(),
        userId: String? = nil,
        platform: String = "ios",
        appVersion: String? = nil,
        sdkVersion: String = WhenKitVersion.current
    ) {
        self.name = name
        self.value = value
        self.metadata = metadata
        self.timestamp = timestamp
        self.userId = userId
        self.platform = platform
        self.appVersion = appVersion
        self.sdkVersion = sdkVersion
    }

    enum CodingKeys: String, CodingKey {
        case name, value, metadata, timestamp, platform
        case userId = "user_id"
        case appVersion = "app_version"
        case sdkVersion = "sdk_version"
    }
}

/// SDK version constant.
public enum WhenKitVersion {
    public static let current = "1.0.3"
}
