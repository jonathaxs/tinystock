// ⌘
//  TinyStock/Views/MainView.swift
//
//  Propósito: Hospeda o TabView principal e roteia pras telas de Produtos, Vendas, Relatórios e Ajustes.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-07.
// ⌘

import SwiftUI
import SwiftData
import TinyStockCore

// MARK: - Índices das abas
// Constantes centralizadas pra outras telas navegarem sem números mágicos.
extension MainView {
    enum Tab {
        static let products = 0
        static let sales    = 1
        static let reports  = 2
        static let settings = 3
    }
}

// MARK: - Tela principal
struct MainView: View {

    // Aba selecionada, persistida pra permitir navegação entre abas no futuro.
    @AppStorage("app.selectedTab") private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {

            ProductsView()
                .tabItem {
                    Label(String(localized: "tab.products", bundle: .tinyStockCore), systemImage: "shippingbox.fill")
                }
                .tag(Tab.products)

            SalesView()
                .tabItem {
                    Label(String(localized: "tab.sales", bundle: .tinyStockCore), systemImage: "cart.fill")
                }
                .tag(Tab.sales)

            ReportsView()
                .tabItem {
                    Label(String(localized: "tab.reports", bundle: .tinyStockCore), systemImage: "chart.bar.fill")
                }
                .tag(Tab.reports)

            SettingsView()
                .tabItem {
                    Label(String(localized: "tab.settings", bundle: .tinyStockCore), systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
    }
}

#Preview {
    MainView()
        .modelContainer(for: Product.self, inMemory: true)
}
