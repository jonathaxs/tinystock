// ⌘
//  TinyStock/Views/ReportsView/ReportsView.swift
//
//  Propósito: Relatórios simples (total vendido, lucro, mais vendidos). Placeholder na Fase 0; conteúdo chega na Fase 3.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-07.
// ⌘

import SwiftUI
import TinyStockCore

struct ReportsView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label(String(localized: "reports.placeholder.title", bundle: .tinyStockCore), systemImage: "chart.bar")
            } description: {
                Text(String(localized: "reports.placeholder.message", bundle: .tinyStockCore))
            }
            .navigationTitle(String(localized: "tab.reports", bundle: .tinyStockCore))
        }
    }
}

#Preview {
    ReportsView()
}
