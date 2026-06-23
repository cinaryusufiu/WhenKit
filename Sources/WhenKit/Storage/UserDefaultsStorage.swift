//
//  UserDefaultsStorage.swift
//  WhenKit
//
//  Created by Yusuf Cinar on 8.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import Foundation

/// Default storage provider using UserDefaults.
public final class UserDefaultsStorage: StorageProvider {
    private let defaults: UserDefaults

    public init(suiteName: String = "com.whenkit.storage") {
        self.defaults = UserDefaults(suiteName: suiteName) ?? .standard
    }

    public func set<T: Codable>(_ value: T, forKey key: String) {
        if let data = value as? Data {
            defaults.set(data, forKey: key)
        } else if let intVal = value as? Int {
            defaults.set(intVal, forKey: key)
        } else if let doubleVal = value as? Double {
            defaults.set(doubleVal, forKey: key)
        } else if let stringVal = value as? String {
            defaults.set(stringVal, forKey: key)
        } else if let boolVal = value as? Bool {
            defaults.set(boolVal, forKey: key)
        } else if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    public func get<T: Codable>(forKey key: String) -> T? {
        if T.self == Data.self {
            return defaults.data(forKey: key) as? T
        } else if T.self == Int.self {
            return defaults.object(forKey: key) != nil ? defaults.integer(forKey: key) as? T : nil
        } else if T.self == Double.self {
            return defaults.object(forKey: key) != nil ? defaults.double(forKey: key) as? T : nil
        } else if T.self == String.self {
            return defaults.string(forKey: key) as? T
        } else if T.self == Bool.self {
            return defaults.object(forKey: key) != nil ? defaults.bool(forKey: key) as? T : nil
        } else if let data = defaults.data(forKey: key) {
            return try? JSONDecoder().decode(T.self, from: data)
        }
        return nil
    }

    public func remove(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}
