//
//  ContentView.swift
//  WhenKitDemo
//
//  Created by Yusuf Cinar on 22.06.2026.
//  Copyright © 2026 Yusuf Cinar. All rights reserved.
//

import SwiftUI
import WhenKit

struct ContentView: View {
    @EnvironmentObject var store: DemoStore

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    rulesCard
                    actionsCard
                    stateCard
                    logCard
                }
                .padding()
            }
            .navigationTitle("WhenKit Demo")
            .toolbar {
                Button("Sıfırla") { store.reset() }
            }
            .alert(store.alertTitle, isPresented: $store.showAlert) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(store.alertMessage ?? "")
            }
        }
    }

    // MARK: - Rules Card

    private var rulesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Tanımlı Kurallar", systemImage: "list.bullet.clipboard")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                ruleRow(
                    name: "happy_buyer",
                    condition: "3 alışveriş + crash yok",
                    action: "Rating iste",
                    cooldown: "30 gün"
                )
                Divider()
                ruleRow(
                    name: "cart_master",
                    condition: "5 sepete ekleme",
                    action: "Sepet kampanyası",
                    cooldown: "24 saat"
                )
                Divider()
                ruleRow(
                    name: "window_shopper",
                    condition: "10 ürün görüntüleme + 0 alışveriş",
                    action: "İndirim kodu",
                    cooldown: "7 gün"
                )
                Divider()
                ruleRow(
                    name: "first_purchase",
                    condition: "İlk alışveriş",
                    action: "Teşekkür mesajı",
                    cooldown: "1 yıl"
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func ruleRow(name: String, condition: String, action: String, cooldown: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(name).font(.subheadline).bold()
                Spacer()
                Text("cooldown: \(cooldown)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text("Koşul: \(condition)").font(.caption).foregroundStyle(.secondary)
            Text("Aksiyon: \(action)").font(.caption).foregroundStyle(.blue)
        }
    }

    // MARK: - Actions Card

    private var actionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Kullanıcı Aksiyonları", systemImage: "hand.tap")
                .font(.headline)

            VStack(spacing: 10) {
                actionButton("Ürün Gör", icon: "eyes", color: .blue) {
                    store.trigger("product_view", label: "Ürün görüntülendi")
                }
                actionButton("Sepete Ekle", icon: "cart.badge.plus", color: .orange) {
                    store.trigger("add_to_cart", label: "Sepete eklendi")
                }
                actionButton("Satın Al", icon: "creditcard", color: .green) {
                    store.trigger("purchase", label: "Alışveriş tamamlandı")
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Senaryolar:").font(.caption).bold()
                scenarioText("happy_buyer", "3x Satın Al (crash yapma)")
                scenarioText("cart_master", "5x Sepete Ekle")
                scenarioText("window_shopper", "10x Ürün Gör (satın alma)")
                scenarioText("first_purchase", "1x Satın Al")
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func scenarioText(_ rule: String, _ hint: String) -> some View {
        HStack(spacing: 4) {
            Text("•").foregroundStyle(.secondary)
            Text(rule).font(.caption2).bold().foregroundStyle(.blue)
            Text(hint).font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func actionButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.body)
                    .bold()
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .cornerRadius(10)
        }
    }

    // MARK: - State Card

    private var stateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Canlı Durum", systemImage: "chart.bar")
                .font(.headline)

            let productViews = WhenKit.shared?.eventCount(for: EventKey("product_view")) ?? 0
            let addToCarts = WhenKit.shared?.eventCount(for: EventKey("add_to_cart")) ?? 0
            let purchases = WhenKit.shared?.eventCount(for: EventKey("purchase")) ?? 0
            let crashed = WhenKit.shared?.hasCrashed ?? false

            HStack(spacing: 12) {
                statBadge("Ürün Görüntüleme", "\(productViews)", target: "/ 10", met: productViews >= 10)
                statBadge("Sepete Ekleme", "\(addToCarts)", target: "/ 5", met: addToCarts >= 5)
            }
            HStack(spacing: 12) {
                statBadge("Alışveriş", "\(purchases)", target: "/ 3", met: purchases >= 3)
                statBadge("Crash", crashed ? "Var" : "Yok", target: nil, met: false, warn: crashed)
            }

            Button(action: { store.simulateCrash() }) {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                    Text("Crash Simule Et")
                        .font(.caption)
                        .bold()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .foregroundStyle(.red)
                .cornerRadius(8)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func statBadge(_ label: String, _ value: String, target: String?, met: Bool, warn: Bool = false) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 2) {
                Text(value)
                    .font(.title2)
                    .bold()
                    .foregroundStyle(warn ? .red : (met ? .green : .primary))
                if let target {
                    Text(target)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if met {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(warn ? Color.red.opacity(0.08) : (met ? Color.green.opacity(0.08) : Color.clear))
        .cornerRadius(8)
    }

    // MARK: - Log Card

    private var logCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("İşlem Geçmişi", systemImage: "clock.arrow.circlepath")
                .font(.headline)

            if store.logs.isEmpty {
                Text("Henüz işlem yok. Yukarıdaki butonlara basın.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(store.logs) { log in
                    HStack(spacing: 8) {
                        Text(log.icon)
                        Text(log.text)
                            .font(.caption)
                            .foregroundStyle(log.icon == "🎯" ? .green : .primary)
                        Spacer()
                        Text(log.time)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
