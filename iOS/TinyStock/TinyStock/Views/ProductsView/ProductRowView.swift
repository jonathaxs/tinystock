// ⌘
//  TinyStock/Views/ProductsView/ProductRowView.swift
//
//  Propósito: Linha da lista de produtos, mostrando nome, quantidade em estoque e preço de venda.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-08.
// ⌘

import SwiftUI
import SwiftData
import TinyStockCore

struct ProductRowView: View {

    let product: Product

    /// A chave carrega um %d, então a contagem entra por String(format:).
    private var quantityText: String {
        String(
            format: String(localized: "products.row.quantity", bundle: .tinyStockCore),
            product.quantity
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(product.name)
                .font(.headline)

            HStack(spacing: 6) {
                Text(quantityText)
                Text(verbatim: "·")
                Text(product.salePrice.currencyText)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    List {
        ProductRowView(product: Product(name: "Amigurumi Gato", quantity: 12, salePrice: 45))
        ProductRowView(product: Product(name: "Suporte de Fone", quantity: 2, salePrice: 25))
    }
    .modelContainer(for: Product.self, inMemory: true)
}
