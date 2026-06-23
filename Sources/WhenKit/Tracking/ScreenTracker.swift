//
//  ScreenTracker.swift
//  WhenKit
//
//  Created by Yusuf Cinar on 12.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Tracks screen/view controller appearances automatically.
final class ScreenTracker {
    private weak var whenKit: WhenKit?
    private var screenCounts: [String: Int] = [:]
    private var isSwizzled = false

    init(whenKit: WhenKit) {
        self.whenKit = whenKit
    }

    /// Enables automatic screen tracking via method swizzling.
    func enableAutoTracking() {
        #if canImport(UIKit) && !os(watchOS)
        guard !isSwizzled else { return }
        swizzleViewDidAppear()
        isSwizzled = true
        WhenKitLogger.debug("ScreenTracker auto-tracking enabled")
        #endif
    }

    /// Manually tracks a screen view.
    func trackScreen(_ screenName: String, metadata: [String: String]? = nil) {
        screenCounts[screenName, default: 0] += 1
        var meta = metadata ?? [:]
        meta["screen_name"] = screenName
        meta["view_count"] = "\(screenCounts[screenName] ?? 1)"
        meta["source"] = meta["source"] ?? "manual"
        whenKit?.trigger(.screenView, metadata: meta)
    }

    /// Returns how many times a specific screen has been viewed.
    func viewCount(for screenName: String) -> Int {
        screenCounts[screenName] ?? 0
    }

    #if canImport(UIKit) && !os(watchOS)
    private func swizzleViewDidAppear() {
        let originalSelector = #selector(UIViewController.viewDidAppear(_:))
        let swizzledSelector = #selector(UIViewController.whenkit_viewDidAppear(_:))

        guard let originalMethod = class_getInstanceMethod(UIViewController.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzledSelector) else {
            WhenKitLogger.warning("ScreenTracker: Failed to swizzle viewDidAppear")
            return
        }

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
    #endif
}

#if canImport(UIKit) && !os(watchOS)
extension UIViewController {
    @objc func whenkit_viewDidAppear(_ animated: Bool) {
        // Call original implementation (methods are swapped)
        whenkit_viewDidAppear(animated)

        // Skip system view controllers
        let className = String(describing: type(of: self))
        let skipPrefixes = ["UI", "_UI", "NS", "_NS", "AV", "CK", "MF", "SF", "SK", "WK"]
        let shouldSkip = skipPrefixes.contains(where: { className.hasPrefix($0) })

        if !shouldSkip {
            let screenName = className
                .replacingOccurrences(of: "ViewController", with: "")
                .replacingOccurrences(of: "Controller", with: "")

            WhenKit.shared?.trackScreen(screenName, metadata: [
                "class": className,
                "source": "automatic"
            ])
        }
    }
}
#endif
