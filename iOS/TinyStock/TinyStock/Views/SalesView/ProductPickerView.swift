// ⌘
//  TinyStock/Views/SalesView/ProductPickerView.swift
//
//  Propósito: Escolher qual produto vai entrar na venda, mostrando só o que tem estoque.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-11.
// ⌘

import SwiftUI
import SwiftData
import TinyStockCore

struct ProductPickerView: View {

    @Environment(\.dismiss) private var dismiss

    /// Produto escolhido, devolvido pra tela de nova venda.
    @Binding var selection: Product?

    /// Só entra na lista quem tem o que vender. Filtrar aqui já evita
    /// metade dos erros de estoque antes de a pessoa tentar confirmar.
    @Query(filter: #Predicate<Product> { $0.quantity > 0 }, sort: \Product.name)
    private var availableProducts: [Product]

    @State private var searchText = ""

    private var filteredProducts: [Product] {
        availableProducts.filter { $0.matches(searchText: searchText) }
    }

    var body: some View {
        Group {
            if availableProducts.isEmpty {
                emptyState
            } else if filteredProducts.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                List(filteredProducts) { product in
                    Button {
                        selection = product
                        dismiss()
                    } label: {
                        row(for: product)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle(String(localized: "sale.picker.title", bundle: .tinyStockCore))
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $searchText,
            prompt: Text(String(localized: "products.search.prompt", bundle: .tinyStockCore))
        )
    }

    // MARK: - Linha

    private func row(for product: Product) -> some View {
        HStack(spacing: 12) {
            ProductImageView(imageData: product.imageData, side: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(product.name)
                    .font(.headline)

                Text(
                    String(
                        format: String(localized: "sale.new.available", bundle: .tinyStockCore),
                        product.quantity
                    )
                )
                .font(.subheadline)
                .foregroundStyle(product.isLowStock ? Color.orange : Color.secondary)
            }

            Spacer()

            Text(product.salePrice.currencyText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .contentShape(.rect)
    }

    // MARK: - Estado vazio

    private var emptyState: some View {
        ContentUnavailableView {
            Label(
                String(localized: "sale.picker.empty.title", bundle: .tinyStockCore),
                systemImage: "shippingbox"
            )
        } description: {
            Text(String(localized: "sale.picker.empty.message", bundle: .tinyStockCore))
        }
    }
}

#Preview {
    NavigationStack {
        ProductPickerView(selection: .constant(nil))
    }
    .modelContainer(for: Product.self, inMemory: true)
}
