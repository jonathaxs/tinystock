// ⌘
//  TinyStock/Views/ReportsView/RestockProductRowView.swift
//
//  Propósito: Mostrar um produto que atingiu o estoque mínimo e precisa de reposição.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-15.
// ⌘

import SwiftUI
import TinyStockCore

struct RestockProductRowView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let product: Product

    private var stockText: String {
        String(
            format: String(localized: "reports.restock.stock", bundle: .tinyStockCore),
            product.quantity,
            product.minimumStock
        )
    }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 12) {
                    productHeader

                    Text(stockText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack(spacing: 12) {
                    ProductImageView(imageData: product.imageData, side: 52)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.name)
                            .font(.headline)

                        Text(stockText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 8)

                    navigationIndicators
                }
            }
        }
        .padding(16)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var productHeader: some View {
        HStack(spacing: 12) {
            ProductImageView(imageData: product.imageData, side: 52)

            Text(product.name)
                .font(.headline)

            Spacer(minLength: 8)

            navigationIndicators
        }
    }

    private var navigationIndicators: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .accessibilityHidden(true)

            Image(systemName: "chevron.right")
                .font(.footnote.bold())
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
    }
}

#Preview {
    RestockProductRowView(
        product: Product(
            name: "Suporte de Fone",
            quantity: 2,
            minimumStock: 3
        )
    )
    .padding()
}
