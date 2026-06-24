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
        WhenKit.initialize(config: WhenKitConfig(
            isDebugEnabled: true,
            sessionTimeoutMinutes: 15,
            autoScreenTracking: false
        ))

        WhenKit.shared?.identify(userId: "demo_user_01")
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
        WhenKit.shared?.setScoreWeight(for: EventKey("purchase"), weight: 10.0)
        WhenKit.shared?.setScoreWeight(for: EventKey("add_to_cart"), weight: 5.0)
        WhenKit.shared?.setScoreWeight(for: EventKey("product_view"), weight: 1.0)
    }

    // MARK: - Rules

    private func setupRules() {

        // Rule 1: happy_buyer
        // "3 purchases + no crash → Ask for App Store rating"
        WhenKit.shared?.addRule("happy_buyer") { rule in
            rule.when(RuleBuilder.count("purchase", .gte, 3))
            rule.when(RuleBuilder.never(.crash))
            rule.cooldown(days: 30)
        }

        // Rule 2: cart_master
        // "5 add to cart actions → Show 'Complete your cart' campaign"
        WhenKit.shared?.addRule("cart_master") { rule in
            rule.when(RuleBuilder.count("add_to_cart", .gte, 5))
            rule.cooldown(hours: 24)
        }

        // Rule 3: window_shopper
        // "10 product views but 0 purchases → Give discount code"
        WhenKit.shared?.addRule("window_shopper") { rule in
            rule.when(RuleBuilder.count("product_view", .gte, 10))
            rule.when(RuleBuilder.count("purchase", .eq, 0))
            rule.cooldown(days: 7)
        }

        // Rule 4: first_purchase
        // "First purchase → Show thank you message"
        WhenKit.shared?.addRule("first_purchase") { rule in
            rule.when(RuleBuilder.count("purchase", .eq, 1))
            rule.cooldown(days: 365) // Once per year (effectively once)
        }
    }

    // MARK: - Callback

    private func setupCallback() {
        WhenKit.shared?.onRuleTriggered = { [weak self] ruleName, info in
            DispatchQueue.main.async {
                guard let self else { return }

                switch ruleName {
                case "happy_buyer":
                    self.alertTitle = "Mutlu Alıcı! 🎉"
                    self.alertMessage = "3 alışveriş yaptınız ve hiç hata yaşamadınız.\n\nBu, App Store rating istemek için ideal an!"

                case "cart_master":
                    self.alertTitle = "Sepet Ustası! 🛒"
                    self.alertMessage = "5 kez sepete ürün eklediniz.\n\n'Sepetini tamamla' kampanyası gösterilebilir."

                case "window_shopper":
                    self.alertTitle = "Vitrin Gezgini! 👀"
                    self.alertMessage = "10 ürün gördünüz ama henüz alışveriş yapmadınız.\n\nİndirim kodu verilebilir: ILKALISVERIŞ20"

                case "first_purchase":
                    self.alertTitle = "İlk Alışveriş! 🎊"
                    self.alertMessage = "İlk alışverişinizi tamamladınız.\n\nTeşekkür ederiz!"

                default:
                    self.alertTitle = "Kural Tetiklendi"
                    self.alertMessage = "'\(ruleName)' tetiklendi."
                }

                self.showAlert = true
                self.addLog("🎯", "TETIKLENDI: \(ruleName)")
            }
        }
    }

    // MARK: - Actions

    func trigger(_ event: String, label: String) {
        let key = EventKey(event)
        WhenKit.shared?.trigger(key)
        addLog("⚡", label)
    }

    func simulateCrash() {
        WhenKit.shared?.trigger(.crash)
        addLog("💥", "Crash simule edildi")
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
