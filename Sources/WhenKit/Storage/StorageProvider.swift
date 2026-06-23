//
//  StorageProvider.swift
//  WhenKit
//
//  Created by Yusuf Cinar on 8.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import Foundation

/// Protocol for key-value persistence used by the SDK.
public protocol StorageProvider {
    func set<T: Codable>(_ value: T, forKey key: String)
    func get<T: Codable>(forKey key: String) -> T?
    func remove(forKey key: String)
}
