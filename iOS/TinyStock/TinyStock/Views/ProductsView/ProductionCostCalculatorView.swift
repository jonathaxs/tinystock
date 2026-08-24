// ⌘
//  TinyStock/Views/ProductsView/ProductionCostCalculatorView.swift
//
//  Propósito: Calcular o custo de produção e aplicar os valores sugeridos ao produto.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-18.
// ⌘

import SwiftUI
import TinyStockCore

struct ProductionCostCalculatorView: View {

    @Environment(\.dismiss) private var dismiss

    let onApply: (ProductionCostResult) -> Void

    @State private var materials = [MaterialDraft()]
    @State private var productionHoursText = ""
    @State private var hourlyCostText = ""
    @State private var additionalCostText = ""
    @State private var desiredMargin = 30

    private var currencyPlaceholder: String {
        Decimal.zero.currencyText
    }

    private var input: ProductionCostInput {
        ProductionCostInput(
            components: materials.map {
                ProductionCostComponent(
                    quantity: decimal(from: $0.quantityText),
                    unitCost: decimal(from: $0.unitCostText)
                )
            },
            productionHours: decimal(from: productionHoursText),
            hourlyCost: decimal(from: hourlyCostText),
            additionalCost: decimal(from: additionalCostText),
            desiredMarginPercentage: Decimal(desiredMargin)
        )
    }

    private var result: ProductionCostResult? {
        try? ProductionCostCalculator.calculate(input)
    }

    private var canApply: Bool {
        guard let result else { return false }
        return result.totalCost > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                materialsSection
                timeSection
                additionalCostsSection
                marginSection
                resultSection
            }
            .navigationTitle(String(localized: "costCalculator.title", bundle: .tinyStockCore))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel", bundle: .tinyStockCore)) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "costCalculator.apply", bundle: .tinyStockCore)) {
                        applyResult()
                    }
                    .disabled(!canApply)
                }
            }
        }
    }

    private var materialsSection: some View {
        Section {
            ForEach($materials) { $material in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        TextField(
                            String(localized: "costCalculator.material.name", bundle: .tinyStockCore),
                            text: $material.name,
                            prompt: Text(
                                String(
                                    localized: "costCalculator.material.name.placeholder",
                                    bundle: .tinyStockCore
                                )
                            )
                        )

                        if materials.count > 1 {
                            Button(role: .destructive) {
                                removeMaterial(id: material.id)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel(
                                String(localized: "costCalculator.material.remove", bundle: .tinyStockCore)
                            )
                        }
                    }

                    decimalField(
                        String(localized: "costCalculator.material.quantity", bundle: .tinyStockCore),
                        text: $material.quantityText,
                        placeholder: "0"
                    )
                    decimalField(
                        String(localized: "costCalculator.material.unitCost", bundle: .tinyStockCore),
                        text: $material.unitCostText
                    )
                }
            }

            Button {
                materials.append(MaterialDraft())
            } label: {
                Label(
                    String(localized: "costCalculator.material.add", bundle: .tinyStockCore),
                    systemImage: "plus.circle"
                )
            }
        } header: {
            Text(String(localized: "costCalculator.section.materials", bundle: .tinyStockCore))
        } footer: {
            Text(String(localized: "costCalculator.materials.footer", bundle: .tinyStockCore))
        }
    }

    private var timeSection: some View {
        Section(String(localized: "costCalculator.section.time", bundle: .tinyStockCore)) {
            decimalField(
                String(localized: "costCalculator.time.hours", bundle: .tinyStockCore),
                text: $productionHoursText,
                placeholder: "0"
            )
            decimalField(
                String(localized: "costCalculator.time.hourlyCost", bundle: .tinyStockCore),
                text: $hourlyCostText
            )
        }
    }

    private var additionalCostsSection: some View {
        Section {
            decimalField(
                String(localized: "costCalculator.additional", bundle: .tinyStockCore),
                text: $additionalCostText
            )
        } header: {
            Text(String(localized: "costCalculator.section.additional", bundle: .tinyStockCore))
        } footer: {
            Text(String(localized: "costCalculator.additional.footer", bundle: .tinyStockCore))
        }
    }

    private var marginSection: some View {
        Section {
            Stepper(value: $desiredMargin, in: 0...95, step: 5) {
                LabeledContent(
                    String(localized: "costCalculator.margin", bundle: .tinyStockCore),
                    value: "\(desiredMargin)%"
                )
            }
        } header: {
            Text(String(localized: "costCalculator.section.margin", bundle: .tinyStockCore))
        } footer: {
            Text(String(localized: "costCalculator.margin.footer", bundle: .tinyStockCore))
        }
    }

    private var resultSection: some View {
        Section(String(localized: "costCalculator.section.result", bundle: .tinyStockCore)) {
            LabeledContent(
                String(localized: "costCalculator.result.materials", bundle: .tinyStockCore),
                value: (result?.materialsCost ?? 0).currencyText
            )
            LabeledContent(
                String(localized: "costCalculator.result.time", bundle: .tinyStockCore),
                value: (result?.timeCost ?? 0).currencyText
            )
            LabeledContent(
                String(localized: "costCalculator.result.additional", bundle: .tinyStockCore),
                value: (result?.additionalCost ?? 0).currencyText
            )
            LabeledContent {
                Text((result?.totalCost ?? 0).currencyText)
                    .fontWeight(.semibold)
            } label: {
                Text(String(localized: "costCalculator.result.totalCost", bundle: .tinyStockCore))
            }
            LabeledContent {
                Text((result?.suggestedPrice ?? 0).currencyText)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
            } label: {
                Text(String(localized: "costCalculator.result.suggestedPrice", bundle: .tinyStockCore))
            }
            LabeledContent(
                String(localized: "costCalculator.result.expectedProfit", bundle: .tinyStockCore),
                value: (result?.expectedProfit ?? 0).currencyText
            )
        }
    }

    private func decimalField(
        _ title: String,
        text: Binding<String>,
        placeholder: String? = nil
    ) -> some View {
        // Rótulo e valor ficam em linhas separadas pra textos longos não colidirem.
        VStack(alignment: .leading, spacing: 6) {
            Text(title)

            TextField(placeholder ?? currencyPlaceholder, text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
        }
    }

    private func decimal(from text: String) -> Decimal {
        CurrencyFormatter.decimal(from: text) ?? 0
    }

    private func removeMaterial(id: UUID) {
        materials.removeAll { $0.id == id }
    }

    private func applyResult() {
        guard let result, canApply else { return }
        onApply(result)
        dismiss()
    }
}

private struct MaterialDraft: Identifiable {
    let id = UUID()
    var name = ""
    var quantityText = ""
    var unitCostText = ""
}
