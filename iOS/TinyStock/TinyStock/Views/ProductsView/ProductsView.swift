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
    @State private var searchText = ""

    /// Filtra em memória de propósito: o estoque de um pequeno negócio tem dezenas de itens,
    /// então o custo é irrelevante e o código fica bem mais simples do que remontar o @Query.
    private var filteredProducts: [Product] {
        products.filter { $0.matches(searchText: searchText) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if products.isEmpty {
                    emptyState
                } else if filteredProducts.isEmpty {
                    // Estado nativo de "nada encontrado", já localizado pelo sistema.
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List {
                        ForEach(filteredProducts) { product in
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
            .searchable(
                text: $searchText,
                prompt: Text(String(localized: "products.search.prompt", bundle: .tinyStockCore))
            )
            .sheet(isPresented: $isPresentingForm) {
                ProductFormView()
            }
        }
    }

    // MARK: - Exclusão

    /// Os índices vêm do ForEach, que itera a lista JÁ FILTRADA pela busca.
    /// Usar `products` aqui apagaria o produto errado sempre que houvesse busca ativa.
    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredProducts[index])
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
