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

    /// Mais recente primeiro. O agrupamento por dia acontece logo abaixo, na memória:
    /// o `#Predicate` do SwiftData não sabe agrupar, e o histórico é pequeno.
    @Query(sort: \Sale.date, order: .reverse) private var sales: [Sale]

    @State private var isPresentingNewSale = false

    private var dayGroups: [SaleDayGroup] {
        SaleDayGroup.groups(from: sales)
    }

    var body: some View {
        NavigationStack {
            Group {
                if sales.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(dayGroups) { group in
                            Section {
                                ForEach(group.sales) { sale in
                                    SaleRowView(sale: sale)
                                }
                                .onDelete { offsets in
                                    delete(offsets, from: group)
                                }
                            } header: {
                                SaleDayHeaderView(group: group)
                            }
                        }
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
    ///
    /// O índice vem do `ForEach` do grupo, então tem que voltar no grupo. Indexar
    /// a lista inteira aqui apagaria a venda errada.
    private func delete(_ offsets: IndexSet, from group: SaleDayGroup) {
        for index in offsets {
            modelContext.delete(group.sales[index])
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
