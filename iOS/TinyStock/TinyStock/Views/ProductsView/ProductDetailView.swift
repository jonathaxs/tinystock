// ⌘
//  TinyStock/Views/ProductsView/ProductDetailView.swift
//
//  Propósito: Detalhe de um produto, com acesso à edição e à exclusão.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-08.
// ⌘

import SwiftUI
import SwiftData
import TinyStockCore

struct ProductDetailView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let product: Product

    @State private var isPresentingForm = false
    @State private var isConfirmingDelete = false

    // MARK: - Corpo

    var body: some View {
        List {
            identificationSection
            stockSection
            pricesSection
            deleteSection
        }
        .navigationTitle(product.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(String(localized: "common.edit", bundle: .tinyStockCore)) {
                    isPresentingForm = true
                }
            }
        }
        .sheet(isPresented: $isPresentingForm) {
            ProductFormView(product: product)
        }
        .alert(
            String(localized: "product.delete.confirm.title", bundle: .tinyStockCore),
            isPresented: $isConfirmingDelete
        ) {
            Button(String(localized: "common.cancel", bundle: .tinyStockCore), role: .cancel) { }
            Button(String(localized: "common.delete", bundle: .tinyStockCore), role: .destructive) {
                delete()
            }
        } message: {
            Text(String(localized: "product.delete.confirm.message", bundle: .tinyStockCore))
        }
    }

    // MARK: - Seções

    private var identificationSection: some View {
        Section(String(localized: "product.form.section.identification", bundle: .tinyStockCore)) {
            LabeledContent {
                // Categoria é opcional, então o texto de apoio evita uma linha em branco.
                if product.category.isEmpty {
                    Text(String(localized: "product.detail.noCategory", bundle: .tinyStockCore))
                        .foregroundStyle(.secondary)
                } else {
                    Text(product.category)
                }
            } label: {
                Text(String(localized: "product.form.category", bundle: .tinyStockCore))
            }
        }
    }

    private var stockSection: some View {
        Section(String(localized: "product.form.section.stock", bundle: .tinyStockCore)) {
            LabeledContent {
                Text(product.quantity, format: .number)
            } label: {
                Text(String(localized: "product.form.quantity", bundle: .tinyStockCore))
            }

            LabeledContent {
                Text(product.minimumStock, format: .number)
            } label: {
                Text(String(localized: "product.form.minimumStock", bundle: .tinyStockCore))
            }
        }
    }

    private var pricesSection: some View {
        Section {
            LabeledContent {
                Text(product.costPrice.currencyText)
            } label: {
                Text(String(localized: "product.form.costPrice", bundle: .tinyStockCore))
            }

            LabeledContent {
                Text(product.salePrice.currencyText)
            } label: {
                Text(String(localized: "product.form.salePrice", bundle: .tinyStockCore))
            }

            LabeledContent {
                Text(product.unitProfit.currencyText)
                    .foregroundStyle(product.unitProfit < 0 ? Color.red : Color.primary)
            } label: {
                Text(String(localized: "product.form.unitProfit", bundle: .tinyStockCore))
            }

            LabeledContent {
                Text(product.potentialProfit.currencyText)
                    .foregroundStyle(product.potentialProfit < 0 ? Color.red : Color.primary)
            } label: {
                Text(String(localized: "product.detail.potentialProfit", bundle: .tinyStockCore))
            }
        } header: {
            Text(String(localized: "product.form.section.prices", bundle: .tinyStockCore))
        } footer: {
            Text(String(localized: "product.detail.potentialProfit.footer", bundle: .tinyStockCore))
        }
    }

    private var deleteSection: some View {
        Section {
            // Aqui a confirmação é obrigatória, diferente do swipe na lista,
            // porque o toque é fácil de errar e a pessoa perde o produto sem perceber.
            Button(role: .destructive) {
                isConfirmingDelete = true
            } label: {
                Text(String(localized: "common.delete", bundle: .tinyStockCore))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Exclusão

    private func delete() {
        modelContext.delete(product)
        // Volta pra lista, senão a tela fica apontando pra um produto que não existe mais.
        dismiss()
    }
}

#Preview {
    NavigationStack {
        ProductDetailView(
            product: Product(
                name: "Amigurumi Gato",
                category: "Crochê",
                quantity: 12,
                minimumStock: 3,
                costPrice: 20,
                salePrice: 45
            )
        )
    }
    .modelContainer(for: Product.self, inMemory: true)
}
