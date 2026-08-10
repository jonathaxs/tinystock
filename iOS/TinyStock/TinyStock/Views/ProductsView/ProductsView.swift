// ⌘
//  TinyStock/Views/ProductsView/ProductsView.swift
//
//  Propósito: Lista de produtos do estoque e porta de entrada pro cadastro de um novo produto.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-07.
// ⌘

import SwiftUI
import SwiftData
import TinyStockCore

struct ProductsView: View {

    @Environment(\.modelContext) private var modelContext

    /// Lista ordenada por nome.
    @Query(sort: \Product.name) private var products: [Product]

    @State private var isPresentingForm = false

    var body: some View {
        NavigationStack {
            Group {
                if products.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(products) { product in
                            NavigationLink {
                                ProductDetailView(product: product)
                            } label: {
                                ProductRowView(product: product)
                            }
                        }
                        // O swipe já funciona como confirmação, então aqui não tem alerta.
                        // A exclusão pelo detalhe é que pede confirmação.
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle(String(localized: "tab.products", bundle: .tinyStockCore))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingForm = true
                    } label: {
                        Label(
                            String(localized: "products.add", bundle: .tinyStockCore),
                            systemImage: "plus"
                        )
                    }
                }
            }
            .sheet(isPresented: $isPresentingForm) {
                ProductFormView()
            }
        }
    }

    // MARK: - Exclusão

    /// Os índices vêm do ForEach, então apontam pra lista já ordenada por nome.
    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(products[index])
        }
    }

    // MARK: - Estado vazio

    private var emptyState: some View {
        ContentUnavailableView {
            Label(
                String(localized: "products.empty.title", bundle: .tinyStockCore),
                systemImage: "shippingbox"
            )
        } description: {
            Text(String(localized: "products.empty.message", bundle: .tinyStockCore))
        } actions: {
            Button(String(localized: "products.add", bundle: .tinyStockCore)) {
                isPresentingForm = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    ProductsView()
        .modelContainer(for: Product.self, inMemory: true)
}
