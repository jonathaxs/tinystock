// ⌘
//  TinyStock/Views/ProductsView/ProductFormView.swift
//
//  Propósito: Formulário de cadastro de produto, com leitura dos preços e gravação no SwiftData.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-08.
// ⌘

import SwiftUI
import SwiftData
import TinyStockCore

struct ProductFormView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Campos do formulário

    @State private var name = ""
    @State private var category = ""
    @State private var quantity = 0
    @State private var minimumStock = 0

    // Dinheiro entra como texto livre e só vira Decimal na leitura abaixo.
    // Assim o usuário digita "45,90" ou "45.90" sem o campo brigar com ele.
    @State private var costPriceText = ""
    @State private var salePriceText = ""

    // MARK: - Valores derivados

    /// Campo vazio conta como zero, que é o padrão do model.
    private var costPrice: Decimal {
        CurrencyFormatter.decimal(from: costPriceText) ?? 0
    }

    private var salePrice: Decimal {
        CurrencyFormatter.decimal(from: salePriceText) ?? 0
    }

    private var unitProfit: Decimal {
        salePrice - costPrice
    }

    /// Nome é o único campo obrigatório. O resto tem padrão que faz sentido.
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Placeholder dos campos de dinheiro sai do próprio formatador, então
    /// acompanha o idioma do aparelho sem string fixa espalhada na view.
    private var currencyPlaceholder: String {
        Decimal.zero.currencyText
    }

    // MARK: - Corpo

    var body: some View {
        NavigationStack {
            Form {
                identificationSection
                stockSection
                pricesSection
            }
            .navigationTitle(String(localized: "product.form.title.new", bundle: .tinyStockCore))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel", bundle: .tinyStockCore)) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.save", bundle: .tinyStockCore)) {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    // MARK: - Seções

    private var identificationSection: some View {
        Section(String(localized: "product.form.section.identification", bundle: .tinyStockCore)) {
            TextField(
                String(localized: "product.form.name", bundle: .tinyStockCore),
                text: $name,
                prompt: Text(String(localized: "product.form.name.placeholder", bundle: .tinyStockCore))
            )

            TextField(
                String(localized: "product.form.category", bundle: .tinyStockCore),
                text: $category,
                prompt: Text(String(localized: "product.form.category.placeholder", bundle: .tinyStockCore))
            )
        }
    }

    private var stockSection: some View {
        Section {
            LabeledContent {
                TextField("0", value: $quantity, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
            } label: {
                Text(String(localized: "product.form.quantity", bundle: .tinyStockCore))
            }

            LabeledContent {
                TextField("0", value: $minimumStock, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
            } label: {
                Text(String(localized: "product.form.minimumStock", bundle: .tinyStockCore))
            }
        } header: {
            Text(String(localized: "product.form.section.stock", bundle: .tinyStockCore))
        } footer: {
            Text(String(localized: "product.form.stock.footer", bundle: .tinyStockCore))
        }
    }

    private var pricesSection: some View {
        Section {
            LabeledContent {
                TextField(currencyPlaceholder, text: $costPriceText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            } label: {
                Text(String(localized: "product.form.costPrice", bundle: .tinyStockCore))
            }

            LabeledContent {
                TextField(currencyPlaceholder, text: $salePriceText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            } label: {
                Text(String(localized: "product.form.salePrice", bundle: .tinyStockCore))
            }

            // Resumo em tempo real pra pessoa perceber na hora se está vendendo no prejuízo.
            LabeledContent {
                Text(unitProfit.currencyText)
                    .foregroundStyle(unitProfit < 0 ? Color.red : Color.primary)
            } label: {
                Text(String(localized: "product.form.unitProfit", bundle: .tinyStockCore))
            }
        } header: {
            Text(String(localized: "product.form.section.prices", bundle: .tinyStockCore))
        } footer: {
            Text(String(localized: "product.form.prices.footer", bundle: .tinyStockCore))
        }
    }

    // MARK: - Gravação

    private func save() {
        let now = Date()

        let product = Product(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category.trimmingCharacters(in: .whitespacesAndNewlines),
            // Trava em zero pra um valor negativo digitado não virar estoque inválido.
            quantity: max(0, quantity),
            minimumStock: max(0, minimumStock),
            costPrice: costPrice,
            salePrice: salePrice,
            createdAt: now,
            updatedAt: now
        )

        // O contexto do ambiente tem autosave ligado, então basta inserir.
        modelContext.insert(product)
        dismiss()
    }
}

#Preview {
    ProductFormView()
        .modelContainer(for: Product.self, inMemory: true)
}
