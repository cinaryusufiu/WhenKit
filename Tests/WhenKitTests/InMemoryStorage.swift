//
//  InMemoryStorage.swift
//  WhenKitTests
//
//  Created by Yusuf Cinar on 14.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import Foundation
@testable import WhenKit

/// In-memory storage provider for testing.
final class InMemoryStorage: StorageProvider {
    private var store: [String: Any] = [:]

    func set<T: Codable>(_ value: T, forKey key: String) {
        store[key] = value
    }

    func get<T: Codable>(forKey key: String) -> T? {
        store[key] as? T
    }

    func remove(forKey key: String) {
        store.removeValue(forKey: key)
    }

    func reset() {
        store.removeAll()
    }
}
