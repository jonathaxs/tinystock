// ⌘
//  TinyStock/Views/SalesView/SaleDayHeaderView.swift
//
//  Propósito: Cabeçalho de um dia no histórico, com o título e o total vendido.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-12.
// ⌘

import SwiftUI
import TinyStockCore

struct SaleDayHeaderView: View {

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let group: SaleDayGroup

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 4) {
                    title
                    Text(group.total.currencyText)
                }
            } else {
                HStack {
                    title
                    Spacer()
                    Text(group.total.currencyText)
                }
            }
        }
    }

    /// O título é calculado ao desenhar. Se virar meia-noite com o app aberto,
    /// ele se acerta no próximo redesenho.
    private var title: some View {
        Text(group.title())
    }
}

#Preview {
    List {
        Section {
            Text(verbatim: "Amigurumi Gato")
        } header: {
            SaleDayHeaderView(group: SaleDayGroup(day: Date(), sales: []))
        }
    }
}
