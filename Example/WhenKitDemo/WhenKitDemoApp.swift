//
//  WhenKitDemoApp.swift
//  WhenKitDemo
//
//  Created by Yusuf Cinar on 22.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import SwiftUI
import WhenKit

@main
struct WhenKitDemoApp: App {
    @StateObject private var store = DemoStore()

    init() {
        WhenKit.initialize(config: WhenKitConfig(isDebugEnabled: true))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}

/// Manages the demo state and WhenKit rules.
final class DemoStore: ObservableObject {
    @Published var logs: [LogEntry] = []
    @Published var alertMessage: String?
    @Published var showAlert = false

    struct LogEntry: Identifiable {
        let id = UUID()
        let icon: String
        let text: String
        let time: String
    }

    init() {
        setupRules()

        WhenKit.shared?.onRuleTriggered = { [weak self] ruleName, info in
            DispatchQueue.main.async {
                guard let self else { return }
                switch ruleName {
                case "loyal_investor":
                    self.alertMessage = "Bu kullanici duzenli yatirim yapiyor!\n\nApp Store rating istemek icin uygun bir an. 3+ yatirim, 2+ havale, hic hata yok."
                case "power_trader":
                    self.alertMessage = "Bu kullanici cok aktif bir trader!\n\nPremium hesap teklifi gostermek icin ideal zaman. Engagement skoru yuksek."
                default:
                    self.alertMessage = "'\(ruleName)' kurali tetiklendi!"
                }
                self.showAlert = true
                self.addLog("🎯", "KURAL TETIKLENDI: \(ruleName)")
            }
        }
    }

    func trigger(_ event: String, label: String, value: Double? = nil) {
        let key = EventKey(event)
        if let value {
            WhenKit.shared?.trigger(key, value: value)
            addLog("⚡", "\(label) (₺\(String(format: "%.0f", value)))")
        } else {
            WhenKit.shared?.trigger(key)
            addLog("⚡", label)
        }
    }

    func addLog(_ icon: String, _ text: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let entry = LogEntry(icon: icon, text: text, time: formatter.string(from: Date()))
        logs.insert(entry, at: 0)
        if logs.count > 50 { logs.removeLast() }
    }

    func reset() {
        WhenKit.shared?.reset()
        logs.removeAll()
        addLog("🔄", "Tum veriler sifirlandi")
    }

    private func setupRules() {
        // Kural 1: Sadik yatirimci — rating iste
        WhenKit.shared?.addRule("loyal_investor") { rule in
            rule.when(RuleBuilder.count("investment", .gte, 3))
            rule.when(RuleBuilder.count("transfer", .gte, 2))
            rule.when(RuleBuilder.never(.crash))
            rule.cooldown(seconds: 10) // demo icin kisa cooldown
        }

        // Kural 2: Aktif trader — premium teklifi
        WhenKit.shared?.addRule("power_trader") { rule in
            rule.when(RuleBuilder.score(.gte, 40.0))
            rule.cooldown(seconds: 10)
        }

        // Skor agirliklari
        WhenKit.shared?.setScoreWeight(for: EventKey("investment"), weight: 10.0)
        WhenKit.shared?.setScoreWeight(for: EventKey("transfer"), weight: 5.0)
        WhenKit.shared?.setScoreWeight(for: EventKey("bill_payment"), weight: 3.0)
        WhenKit.shared?.setScoreWeight(for: EventKey("balance_check"), weight: 1.0)
        WhenKit.shared?.setScoreWeight(for: EventKey("stock_trade"), weight: 8.0)
    }
}
