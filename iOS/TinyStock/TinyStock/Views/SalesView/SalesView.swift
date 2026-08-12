// ⌘
//  TinyStock/Views/SalesView/SalesView.swift
//
//  Propósito: Histórico de vendas e porta de entrada pro registro de uma venda nova.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-07.
// ⌘

import SwiftUI
import SwiftData
import TinyStockCore

struct SalesView: View {

    @Environment(\.modelContext) private var modelContext

    /// Mais recente primeiro. O agrupamento por dia chega na próxima etapa.
    @Query(sort: \Sale.date, order: .reverse) private var sales: [Sale]

    @State private var isPresentingNewSale = false

    var body: some View {
        NavigationStack {
            Group {
                if sales.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(sales) { sale in
                            SaleRowView(sale: sale)
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle(String(localized: "tab.sales", bundle: .tinyStockCore))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingNewSale = true
                    } label: {
                        Label(
                            String(localized: "sales.add", bundle: .tinyStockCore),
                            systemImage: "plus"
                        )
                    }
                }
            }
            .sheet(isPresented: $isPresentingNewSale) {
                NewSaleView()
            }
        }
    }

    // MARK: - Exclusão

    /// Apaga só o registro da venda. O estoque não volta de propósito: desfazer
    /// venda é outro assunto, e devolver silenciosamente confundiria a contagem.
    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sales[index])
        }
    }

    // MARK: - Estado vazio

    private var emptyState: some View {
        ContentUnavailableView {
            Label(
                String(localized: "sales.placeholder.title", bundle: .tinyStockCore),
                systemImage: "cart"
            )
        } description: {
            Text(String(localized: "sales.placeholder.message", bundle: .tinyStockCore))
        } actions: {
            Button(String(localized: "sales.add", bundle: .tinyStockCore)) {
                isPresentingNewSale = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    SalesView()
        .modelContainer(for: Sale.self, inMemory: true)
}
