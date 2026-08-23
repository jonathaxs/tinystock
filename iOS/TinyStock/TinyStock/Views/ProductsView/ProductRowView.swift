// ⌘
//  TinyStock/Views/ProductsView/ProductRowView.swift
//
//  Propósito: Linha da lista de produtos, com quantidade, preço e alerta de estoque baixo.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-08.
// ⌘

import SwiftUI
import SwiftData
import TinyStockCore

struct ProductRowView: View {

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let product: Product

    /// A chave carrega um %d, então a contagem entra por String(format:).
    private var quantityText: String {
        String(
            format: String(localized: "products.row.quantity", bundle: .tinyStockCore),
            product.quantity
        )
    }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 12) {
                    ProductImageView(imageData: product.imageData)
                    productName
                    Text(quantityText)
                        .foregroundStyle(product.isLowStock ? Color.orange : Color.secondary)
                    Text(product.salePrice.currencyText)
                        .foregroundStyle(.secondary)
                    lowStockLabel
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack(spacing: 12) {
                    ProductImageView(imageData: product.imageData)
                    details
                }
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 4) {
            productName

            HStack(spacing: 6) {
                // Quantidade em laranja já entrega o alerta antes mesmo de ler o selo.
                Text(quantityText)
                    .foregroundStyle(product.isLowStock ? Color.orange : Color.secondary)

                Text(verbatim: "·")
                    .foregroundStyle(.secondary)

                Text(product.salePrice.currencyText)
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
            .accessibilityElement(children: .combine)

            lowStockLabel
        }
    }

    private var productName: some View {
        Text(product.name)
            .font(.headline)
    }

    @ViewBuilder
    private var lowStockLabel: some View {
        if product.isLowStock {
            Label(
                String(localized: "products.lowStock", bundle: .tinyStockCore),
                systemImage: "exclamationmark.triangle.fill"
            )
            .font(.caption)
            .foregroundStyle(.orange)
        }
    }
}

#Preview {
    List {
        ProductRowView(product: Product(name: "Amigurumi Gato", quantity: 12, minimumStock: 3, salePrice: 45))
        ProductRowView(product: Product(name: "Suporte de Fone", quantity: 2, minimumStock: 5, salePrice: 25))
        ProductRowView(product: Product(name: "Tapete Redondo", quantity: 0, minimumStock: 2, salePrice: 90))
    }
    .modelContainer(for: Product.self, inMemory: true)
}
