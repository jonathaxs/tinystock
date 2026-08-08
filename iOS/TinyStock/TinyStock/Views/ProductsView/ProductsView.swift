// ⌘
//  TinyStock/Views/ProductsView/ProductsView.swift
//
//  Propósito: Lista de produtos do estoque. Na Fase 0 mostra só o estado vazio; o CRUD chega na Fase 1.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-07.
// ⌘

import SwiftUI
import SwiftData
import TinyStockCore

struct ProductsView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label(String(localized: "products.empty.title", bundle: .tinyStockCore), systemImage: "shippingbox")
            } description: {
                Text(String(localized: "products.empty.message", bundle: .tinyStockCore))
            }
            .navigationTitle(String(localized: "tab.products", bundle: .tinyStockCore))
        }
    }
}

#Preview {
    ProductsView()
        .modelContainer(for: Product.self, inMemory: true)
}
