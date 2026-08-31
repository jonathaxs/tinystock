// TinyStock/Views/ProductsView/ProductVariantFormView.swift
//
// Proposito: Editar o rascunho de uma variacao e seu estoque inicial.
//
// Created by Jonathas Motta (@jonathaxs) on 2026-08-30.

import SwiftUI
import TinyStockCore

/// Edita somente o rascunho. O formulario de produto confirma a gravacao do conjunto.
struct ProductVariantFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var input: ProductVariantInput
    @State private var quantityText: String
    let onSave: (ProductVariantInput) -> Void

    init(input: ProductVariantInput, onSave: @escaping (ProductVariantInput) -> Void) {
        _input = State(initialValue: input)
        _quantityText = State(initialValue: String(input.initialQuantity))
        self.onSave = onSave
    }

    private var quantity: Int? { Int(quantityText.trimmingCharacters(in: .whitespacesAndNewlines)) }
    private var canSave: Bool {
        guard !input.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        if input.existingID != nil { return true }
        guard let quantity else { return false }
        return quantity >= 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(String(localized: "product.form.variant.name", bundle: .tinyStockCore), text: $input.name)
                    if input.existingID == nil {
                        LabeledContent(String(localized: "product.form.variant.initialStock", bundle: .tinyStockCore)) {
                            TextField("0", text: $quantityText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .accessibilityLabel(String(localized: "product.form.variant.initialStock", bundle: .tinyStockCore))
                        }
                    } else {
                        LabeledContent(String(localized: "product.form.variant.available", bundle: .tinyStockCore)) {
                            Text(input.initialQuantity, format: .number)
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "product.form.variant.title", bundle: .tinyStockCore))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel", bundle: .tinyStockCore)) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.save", bundle: .tinyStockCore)) {
                        if input.existingID == nil, let quantity { input.initialQuantity = quantity }
                        input.name = input.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(input)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}
