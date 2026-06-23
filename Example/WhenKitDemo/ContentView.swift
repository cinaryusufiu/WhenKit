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
                    toolsCard
                    stateCard
                    logCard
                }
                .padding()
            }
            .navigationTitle("WhenKit Demo")
            .toolbar {
                Button("Sifirla") { store.reset() }
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
            Label("Tanimli Kurallar", systemImage: "list.bullet.clipboard")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                ruleRow(
                    name: "loyal_investor",
                    conditions: "count + count + never",
                    desc: "3+ yatirim, 2+ havale, crash yok",
                    cooldown: "30 gun"
                )
                Divider()
                ruleRow(
                    name: "power_trader",
                    conditions: "score",
                    desc: "Engagement skoru >= 40",
                    cooldown: "2 hafta"
                )
                Divider()
                ruleRow(
                    name: "active_user",
                    conditions: "sessionCount + countInLast",
                    desc: "5+ oturum, son 7 gunde 3+ havale",
                    cooldown: "1 ay"
                )
                Divider()
                ruleRow(
                    name: "big_spender",
                    conditions: "groupTotal + value",
                    desc: "10+ islem, son yatirim >= 5000₺",
                    cooldown: "12 saat"
                )
                Divider()
                ruleRow(
                    name: "onboarding_done",
                    conditions: "sequence",
                    desc: "Sirayla: bakiye → havale → yatirim",
                    cooldown: "6 ay"
                )
                Divider()
                ruleRow(
                    name: "cautious_saver",
                    conditions: "or + not",
                    desc: "5+ fatura VEYA 3+ yatirim, hisse YOK",
                    cooldown: "30 dk"
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func ruleRow(name: String, conditions: String, desc: String, cooldown: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(name).font(.subheadline).bold()
                Spacer()
                Text(conditions)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .cornerRadius(4)
            }
            Text(desc).font(.caption).foregroundStyle(.secondary)
            Text("Cooldown: \(cooldown)").font(.caption2).foregroundStyle(.tertiary)
        }
    }

    // MARK: - Actions Card

    private var actionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Finansal Islemler", systemImage: "banknote")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                actionButton("Bakiye Sorgula", icon: "eye", color: .blue) {
                    store.trigger("balance_check", label: "Bakiye sorgusu")
                }
                actionButton("Havale Yap", icon: "arrow.left.arrow.right", color: .orange) {
                    store.trigger("transfer", label: "Havale", value: 2500)
                }
                actionButton("Yatirim Yap", icon: "chart.line.uptrend.xyaxis", color: .green) {
                    store.trigger("investment", label: "Fon yatirimi", value: 5000)
                }
                actionButton("Fatura Ode", icon: "doc.text", color: .purple) {
                    store.trigger("bill_payment", label: "Fatura odendi", value: 320)
                }
                actionButton("Hisse Al/Sat", icon: "chart.bar.xaxis.ascending", color: .red) {
                    store.trigger("stock_trade", label: "Hisse islemi", value: 10000)
                }
                actionButton("Kredi Basvuru", icon: "building.columns", color: .teal) {
                    store.trigger("loan_application", label: "Kredi basvurusu")
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                scenarioText("loyal_investor", "3x Yatirim + 2x Havale")
                scenarioText("power_trader", "Skor 40'a ulassin (ornegin 4x Yatirim)")
                scenarioText("onboarding_done", "Sirayla: Bakiye → Havale → Yatirim")
                scenarioText("cautious_saver", "3x Yatirim ama hic Hisse yapma")
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
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
                    .bold()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .cornerRadius(10)
        }
    }

    // MARK: - Tools Card

    private var toolsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("SDK Araclari", systemImage: "wrench.and.screwdriver")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                toolButton("Crash Simule", icon: "exclamationmark.triangle", color: .red) {
                    store.simulateCrash()
                }
                toolButton("Saat Sync", icon: "clock.arrow.2.circlepath", color: .indigo) {
                    store.syncTime()
                }
                toolButton("Ekran Takip", icon: "rectangle.portrait", color: .mint) {
                    store.trackScreen("DemoScreen")
                }
            }

            Text("Crash: never(.crash) kosulunu bozar. Saat Sync: sunucu saatini senkronize eder. Ekran Takip: manuel ekran goruntulemesi kaydeder.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func toolButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.body)
                Text(title)
                    .font(.caption2)
                    .bold()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .cornerRadius(8)
        }
    }

    // MARK: - State Card

    private var stateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Canli Durum", systemImage: "gauge.with.dots.needle.bottom.50percent")
                .font(.headline)

            let investments = WhenKit.shared?.eventCount(for: "investment") ?? 0
            let transfers = WhenKit.shared?.eventCount(for: "transfer") ?? 0
            let bills = WhenKit.shared?.eventCount(for: "bill_payment") ?? 0
            let balances = WhenKit.shared?.eventCount(for: "balance_check") ?? 0
            let trades = WhenKit.shared?.eventCount(for: "stock_trade") ?? 0
            let score = WhenKit.shared?.currentScore ?? 0
            let sessions = WhenKit.shared?.totalSessions ?? 0
            let days = WhenKit.shared?.daysSinceInstall ?? 0
            let crashed = WhenKit.shared?.hasCrashed ?? false

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                statBadge("Yatirim", "\(investments)", target: "/ 3", met: investments >= 3)
                statBadge("Havale", "\(transfers)", target: "/ 2", met: transfers >= 2)
                statBadge("Skor", String(format: "%.0f", score), target: "/ 40", met: score >= 40)
                statBadge("Fatura", "\(bills)", target: nil, met: false)
                statBadge("Bakiye", "\(balances)", target: nil, met: false)
                statBadge("Hisse", "\(trades)", target: nil, met: false)
                statBadge("Oturum", "\(sessions)", target: "/ 5", met: sessions >= 5)
                statBadge("Gun", "\(days)", target: nil, met: false)
                statBadge("Crash", crashed ? "Evet" : "Yok", target: nil, met: false, warn: crashed)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func statBadge(_ label: String, _ value: String, target: String?, met: Bool, warn: Bool = false) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 2) {
                Text(value)
                    .font(.title3)
                    .bold()
                    .foregroundStyle(warn ? .red : (met ? .green : .primary))
                if let target {
                    Text(target)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            if met {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(warn ? Color.red.opacity(0.08) : (met ? Color.green.opacity(0.08) : Color.clear))
        .cornerRadius(8)
    }

    // MARK: - Log Card

    private var logCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Islem Gecmisi", systemImage: "clock.arrow.circlepath")
                .font(.headline)

            if store.logs.isEmpty {
                Text("Henuz islem yok. Yukaridaki butonlara basin.")
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
