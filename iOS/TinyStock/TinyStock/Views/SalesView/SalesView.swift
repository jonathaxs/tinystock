// ⌘
//  TinyStock/Views/SalesView/SalesView.swift
//
//  Propósito: Registro e histórico de vendas. Placeholder na Fase 0; a venda com baixa de estoque chega na Fase 2.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-07.
// ⌘

import SwiftUI
import TinyStockCore

struct SalesView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label(String(localized: "sales.placeholder.title", bundle: .tinyStockCore), systemImage: "cart")
            } description: {
                Text(String(localized: "sales.placeholder.message", bundle: .tinyStockCore))
            }
            .navigationTitle(String(localized: "tab.sales", bundle: .tinyStockCore))
        }
    }
}

#Preview {
    SalesView()
}
