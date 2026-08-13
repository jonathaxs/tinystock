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

    let group: SaleDayGroup

    var body: some View {
        HStack {
            // O título é calculado na hora de desenhar. Se o app ficar aberto virando
            // a meia-noite, o "Hoje" só se acerta no próximo redesenho, e tudo bem.
            Text(group.title())

            Spacer()

            Text(group.total.currencyText)
        }
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
