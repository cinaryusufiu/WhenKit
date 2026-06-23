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
                Button("Sifirla") { store.reset() }
            }
            .alert("WhenKit Sinyal Verdi!", isPresented: $store.showAlert) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(store.alertMessage ?? "")
            }
        }
    }

    // MARK: - Rules Card

    private var rulesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tanimli Kurallar")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                ruleRow(
                    name: "loyal_investor",
                    desc: "3+ yatirim  +  2+ havale  +  hic hata yok",
                    action: "→ Rating popup goster"
                )
                Divider()
                ruleRow(
                    name: "power_trader",
                    desc: "Engagement skoru >= 40",
                    action: "→ Premium hesap teklifi goster"
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func ruleRow(name: String, desc: String, action: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name).font(.subheadline).bold()
            Text(desc).font(.caption).foregroundStyle(.secondary)
            Text(action).font(.caption).foregroundStyle(.blue)
        }
    }

    // MARK: - Actions Card

    private var actionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Finansal Islemler")
                .font(.headline)

            Text("Bir finans uygulamasindaki kullanici davranislarini simule edin:")
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                actionButton("Bakiye Sorgula", icon: "banknote", color: .blue) {
                    store.trigger("balance_check", label: "Bakiye sorgusu")
                }
                actionButton("Havale Yap", icon: "arrow.left.arrow.right", color: .orange) {
                    store.trigger("transfer", label: "Havale yapildi", value: 2500)
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

            Text("Senaryo: 3x 'Yatirim Yap' + 2x 'Havale Yap' yapinca loyal_investor tetiklenir")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
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

    // MARK: - State Card

    private var stateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Canli Durum")
                .font(.headline)

            let investments = WhenKit.shared?.eventCount(for: "investment") ?? 0
            let transfers = WhenKit.shared?.eventCount(for: "transfer") ?? 0
            let bills = WhenKit.shared?.eventCount(for: "bill_payment") ?? 0
            let balances = WhenKit.shared?.eventCount(for: "balance_check") ?? 0
            let trades = WhenKit.shared?.eventCount(for: "stock_trade") ?? 0
            let score = WhenKit.shared?.currentScore ?? 0

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                statBadge("Yatirim", "\(investments)", target: "/ 3", met: investments >= 3)
                statBadge("Havale", "\(transfers)", target: "/ 2", met: transfers >= 2)
                statBadge("Skor", String(format: "%.0f", score), target: "/ 40", met: score >= 40)
                statBadge("Fatura", "\(bills)", target: nil, met: false)
                statBadge("Bakiye", "\(balances)", target: nil, met: false)
                statBadge("Hisse", "\(trades)", target: nil, met: false)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func statBadge(_ label: String, _ value: String, target: String?, met: Bool) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 2) {
                Text(value)
                    .font(.title3)
                    .bold()
                    .foregroundStyle(met ? .green : .primary)
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
        .background(met ? Color.green.opacity(0.08) : Color.clear)
        .cornerRadius(8)
    }

    // MARK: - Log Card

    private var logCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Islem Gecmisi")
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
