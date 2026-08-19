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

    @State private var method: ProductionMethod = .printing3D
    @State private var materialQuantityText = ""
    @State private var materialUnitPriceText = ""
    @State private var productionHoursText = ""
    @State private var hourlyCostText = ""
    @State private var additionalCostText = ""
    @State private var desiredMargin = 30

    private var currencyPlaceholder: String {
        Decimal.zero.currencyText
    }

    private var input: ProductionCostInput {
        ProductionCostInput(
            method: method,
            materialQuantity: decimal(from: materialQuantityText),
            materialUnitPrice: decimal(from: materialUnitPriceText),
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

    private var materialQuantityLabel: String {
        switch method {
        case .printing3D:
            String(localized: "costCalculator.material.grams", bundle: .tinyStockCore)
        case .crochet:
            String(localized: "costCalculator.material.skeins", bundle: .tinyStockCore)
        }
    }

    private var materialUnitPriceLabel: String {
        switch method {
        case .printing3D:
            String(localized: "costCalculator.material.pricePerKilogram", bundle: .tinyStockCore)
        case .crochet:
            String(localized: "costCalculator.material.pricePerSkein", bundle: .tinyStockCore)
        }
    }

    private var productionHoursLabel: String {
        switch method {
        case .printing3D:
            String(localized: "costCalculator.time.printingHours", bundle: .tinyStockCore)
        case .crochet:
            String(localized: "costCalculator.time.workHours", bundle: .tinyStockCore)
        }
    }

    private var hourlyCostLabel: String {
        switch method {
        case .printing3D:
            String(localized: "costCalculator.time.energyPerHour", bundle: .tinyStockCore)
        case .crochet:
            String(localized: "costCalculator.time.laborPerHour", bundle: .tinyStockCore)
        }
    }

    private var timeCostLabel: String {
        switch method {
        case .printing3D:
            String(localized: "costCalculator.result.energy", bundle: .tinyStockCore)
        case .crochet:
            String(localized: "costCalculator.result.labor", bundle: .tinyStockCore)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                methodSection
                materialSection
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

    private var methodSection: some View {
        Section(String(localized: "costCalculator.section.method", bundle: .tinyStockCore)) {
            Picker(
                String(localized: "costCalculator.section.method", bundle: .tinyStockCore),
                selection: $method
            ) {
                ForEach(ProductionMethod.allCases) { option in
                    Text(option.localizedName).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    private var materialSection: some View {
        Section(String(localized: "costCalculator.section.material", bundle: .tinyStockCore)) {
            decimalField(materialQuantityLabel, text: $materialQuantityText, placeholder: "0")
            decimalField(materialUnitPriceLabel, text: $materialUnitPriceText)
        }
    }

    private var timeSection: some View {
        Section(String(localized: "costCalculator.section.time", bundle: .tinyStockCore)) {
            decimalField(productionHoursLabel, text: $productionHoursText, placeholder: "0")
            decimalField(hourlyCostLabel, text: $hourlyCostText)
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
                String(localized: "costCalculator.result.material", bundle: .tinyStockCore),
                value: (result?.materialCost ?? 0).currencyText
            )
            LabeledContent(
                timeCostLabel,
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

    private func applyResult() {
        guard let result, canApply else { return }
        onApply(result)
        dismiss()
    }
}
