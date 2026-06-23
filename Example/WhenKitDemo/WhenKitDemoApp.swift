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
        // Full configuration: debug logging, 15-min session timeout, auto screen tracking
        WhenKit.initialize(config: WhenKitConfig(
            isDebugEnabled: true,
            sessionTimeoutMinutes: 15,
            autoScreenTracking: true
        ))

        // Identify user (for analytics/logging)
        WhenKit.shared?.identify(userId: "demo_user_01")
        WhenKit.shared?.setUserAttribute("plan", value: "free")
        WhenKit.shared?.setUserAttribute("region", value: "TR")

        // Sync time with server (in real app, use your backend's Date header)
        // If not called, device clock is used as fallback.
        WhenKit.shared?.syncTime(Date())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}

// MARK: - Demo Store

/// Manages the demo state and WhenKit rules.
final class DemoStore: ObservableObject {
    @Published var logs: [LogEntry] = []
    @Published var alertTitle: String = ""
    @Published var alertMessage: String?
    @Published var showAlert = false

    struct LogEntry: Identifiable {
        let id = UUID()
        let icon: String
        let text: String
        let time: String
    }

    init() {
        setupScoreWeights()
        setupRules()
        setupCallback()
    }

    // MARK: - Score Weights

    private func setupScoreWeights() {
        WhenKit.shared?.setScoreWeight(for: EventKey("investment"), weight: 10.0)
        WhenKit.shared?.setScoreWeight(for: EventKey("stock_trade"), weight: 8.0)
        WhenKit.shared?.setScoreWeight(for: EventKey("transfer"), weight: 5.0)
        WhenKit.shared?.setScoreWeight(for: EventKey("bill_payment"), weight: 3.0)
        WhenKit.shared?.setScoreWeight(for: EventKey("balance_check"), weight: 1.0)
    }

    // MARK: - Rules

    private func setupRules() {

        // ── Rule 1: loyal_investor ──────────────────────────
        // Conditions: count + count + never
        // "3+ investments, 2+ transfers, and no crashes"
        WhenKit.shared?.addRule("loyal_investor") { rule in
            rule.when(RuleBuilder.count("investment", .gte, 3))
            rule.when(RuleBuilder.count("transfer", .gte, 2))
            rule.when(RuleBuilder.never(.crash))
            rule.cooldown(days: 30)
        }

        // ── Rule 2: power_trader ────────────────────────────
        // Conditions: score
        // "Engagement score reaches 40+"
        WhenKit.shared?.addRule("power_trader") { rule in
            rule.when(RuleBuilder.score(.gte, 40.0))
            rule.cooldown(weeks: 2)
        }

        // ── Rule 3: active_user ─────────────────────────────
        // Conditions: sessionCount + countInLast
        // "5+ sessions and 3+ transactions in the last 7 days"
        WhenKit.shared?.addRule("active_user") { rule in
            rule.when(RuleBuilder.sessionCount(.gte, 5))
            rule.when(RuleBuilder.countInLast("transfer", days: 7, .gte, 3))
            rule.cooldown(months: 1)
        }

        // ── Rule 4: big_spender ─────────────────────────────
        // Conditions: groupTotal + value
        // "10+ total financial actions and last transaction value >= 5000"
        WhenKit.shared?.addRule("big_spender") { rule in
            rule.when(RuleBuilder.groupTotal(
                ["investment", "transfer", "stock_trade", "bill_payment"],
                .gte, 10
            ))
            rule.when(RuleBuilder.value("investment", .gte, 5000.0))
            rule.cooldown(hours: 12)
        }

        // ── Rule 5: onboarding_done ─────────────────────────
        // Conditions: sequence
        // "Completed onboarding steps in order: balance check → transfer → investment"
        WhenKit.shared?.addRule("onboarding_done") { rule in
            rule.when(RuleBuilder.sequence(["balance_check", "transfer", "investment"]))
            rule.cooldown(months: 6)
        }

        // ── Rule 6: cautious_saver ──────────────────────────
        // Conditions: or + not (logical combinators)
        // "Either 5+ bill payments OR 3+ investments, but NOT a stock trader"
        WhenKit.shared?.addRule("cautious_saver") { rule in
            rule.when(RuleBuilder.or([
                RuleBuilder.count("bill_payment", .gte, 5),
                RuleBuilder.count("investment", .gte, 3)
            ]))
            rule.when(RuleBuilder.not(RuleBuilder.count("stock_trade", .gte, 1)))
            rule.cooldown(minutes: 30)
        }
    }

    // MARK: - Callback

    private func setupCallback() {
        WhenKit.shared?.onRuleTriggered = { [weak self] ruleName, info in
            DispatchQueue.main.async {
                guard let self else { return }

                switch ruleName {
                case "loyal_investor":
                    self.alertTitle = "Sadik Yatirimci"
                    self.alertMessage = "3+ yatirim, 2+ havale, hic crash yok.\nApp Store rating istemek icin ideal an.\n\nSkor: \(String(format: "%.0f", info.score))"

                case "power_trader":
                    self.alertTitle = "Guclu Trader"
                    self.alertMessage = "Engagement skoru \(String(format: "%.0f", info.score)) — cok aktif.\nPremium hesap teklifi goster."

                case "active_user":
                    self.alertTitle = "Aktif Kullanici"
                    self.alertMessage = "5+ oturum ve son 7 gunde 3+ islem.\nOzel kampanya goster."

                case "big_spender":
                    self.alertTitle = "Buyuk Yatirimci"
                    self.alertMessage = "10+ finansal islem ve son yatirim >= 5000₺.\nVIP hesap teklifi sun."

                case "onboarding_done":
                    self.alertTitle = "Onboarding Tamamlandi"
                    self.alertMessage = "Kullanici sirasi ile: bakiye → havale → yatirim yapti.\nBasari mesaji goster."

                case "cautious_saver":
                    self.alertTitle = "Tutumlu Tasarrufcu"
                    self.alertMessage = "Fatura veya yatirim yapti ama hisse almadi.\nVadeli mevduat teklifi goster."

                default:
                    self.alertTitle = "Kural Tetiklendi"
                    self.alertMessage = "'\(ruleName)' tetiklendi.\nSkor: \(String(format: "%.0f", info.score))"
                }

                self.showAlert = true
                self.addLog("🎯", "TETIKLENDI: \(ruleName) (skor: \(String(format: "%.0f", info.score)))")
            }
        }
    }

    // MARK: - Actions

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

    func trackScreen(_ name: String) {
        WhenKit.shared?.trackScreen(name)
        addLog("📱", "Ekran: \(name)")
    }

    func simulateCrash() {
        WhenKit.shared?.trigger(.crash, metadata: ["source": "manual", "reason": "demo"])
        addLog("💥", "Crash simule edildi")
    }

    func syncTime() {
        WhenKit.shared?.syncTime(Date())
        addLog("🕐", "Saat senkronize edildi")
    }

    func reset() {
        WhenKit.shared?.reset()
        logs.removeAll()
        addLog("🔄", "Tum veriler sifirlandi")
    }

    func addLog(_ icon: String, _ text: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let entry = LogEntry(icon: icon, text: text, time: formatter.string(from: Date()))
        logs.insert(entry, at: 0)
        if logs.count > 50 { logs.removeLast() }
    }
}
