// ⌘
//  TinyStock/Views/SalesView/NewSaleView.swift
//
//  Propósito: Registrar uma venda, escolhendo produto, quantidade e forma de pagamento.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-11.
// ⌘

import SwiftUI
import SwiftData
import TinyStockCore

struct NewSaleView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProduct: Product?
    @State private var quantity = 1
    @State private var paymentMethod: PaymentMethod = .pix

    /// Mensagem do erro devolvido pelo Core. Não nil significa alerta na tela.
    @State private var errorMessage: String?

    // MARK: - Valores derivados

    private var total: Decimal {
        guard let selectedProduct else { return 0 }
        return selectedProduct.salePrice * Decimal(quantity)
    }

    private var profit: Decimal {
        guard let selectedProduct else { return 0 }
        return selectedProduct.unitProfit * Decimal(quantity)
    }

    private var canConfirm: Bool {
        selectedProduct != nil && quantity > 0
    }

    // MARK: - Corpo

    var body: some View {
        NavigationStack {
            Form {
                productSection

                if let product = selectedProduct {
                    quantitySection(for: product)
                    paymentSection
                    summarySection
                }
            }
            .navigationTitle(String(localized: "sale.new.title", bundle: .tinyStockCore))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel", bundle: .tinyStockCore)) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.save", bundle: .tinyStockCore)) {
                        confirm()
                    }
                    .disabled(!canConfirm)
                }
            }
            .alert(
                String(localized: "sale.error.title", bundle: .tinyStockCore),
                isPresented: .constant(errorMessage != nil),
                presenting: errorMessage
            ) { _ in
                Button(String(localized: "common.cancel", bundle: .tinyStockCore), role: .cancel) {
                    errorMessage = nil
                }
            } message: { message in
                Text(message)
            }
        }
    }

    // MARK: - Seções

    private var productSection: some View {
        Section(String(localized: "sale.new.section.product", bundle: .tinyStockCore)) {
            NavigationLink {
                ProductPickerView(selection: $selectedProduct)
            } label: {
                if let selectedProduct {
                    chosenProductLabel(selectedProduct)
                } else {
                    Text(String(localized: "sale.new.chooseProduct", bundle: .tinyStockCore))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onChange(of: selectedProduct) { _, newProduct in
            // Trocar de produto zera a quantidade, senão sobra um número
            // que talvez nem caiba no estoque do produto novo.
            quantity = newProduct == nil ? 1 : min(quantity, newProduct?.quantity ?? 1)
        }
    }

    private func chosenProductLabel(_ product: Product) -> some View {
        HStack(spacing: 12) {
            ProductImageView(imageData: product.imageData, side: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(product.name)
                    .font(.headline)

                Text(product.salePrice.currencyText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func quantitySection(for product: Product) -> some View {
        Section {
            // O Stepper para no estoque disponível, então não dá nem pra tentar
            // vender mais do que existe. O alerta continua como rede de segurança.
            Stepper(value: $quantity, in: 1...max(1, product.quantity)) {
                LabeledContent {
                    Text(quantity, format: .number)
                        .font(.body.monospacedDigit())
                } label: {
                    Text(String(localized: "sale.new.section.quantity", bundle: .tinyStockCore))
                }
            }

            LabeledContent {
                Text(product.quantity, format: .number)
                    .foregroundStyle(product.isLowStock ? Color.orange : Color.secondary)
            } label: {
                Text(String(localized: "sale.new.inStock", bundle: .tinyStockCore))
            }
        } footer: {
            Text(String(localized: "sale.new.quantity.footer", bundle: .tinyStockCore))
        }
    }

    private var paymentSection: some View {
        Section(String(localized: "sale.new.section.payment", bundle: .tinyStockCore)) {
            Picker(
                String(localized: "sale.new.section.payment", bundle: .tinyStockCore),
                selection: $paymentMethod
            ) {
                ForEach(PaymentMethod.allCases, id: \.self) { method in
                    Label(method.localizedName, systemImage: method.symbolName)
                        .tag(method)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        }
    }

    private var summarySection: some View {
        Section(String(localized: "sale.new.section.summary", bundle: .tinyStockCore)) {
            LabeledContent {
                Text(total.currencyText)
                    .font(.headline)
            } label: {
                Text(String(localized: "sale.new.total", bundle: .tinyStockCore))
            }

            LabeledContent {
                Text(profit.currencyText)
                    .foregroundStyle(profit < 0 ? Color.red : Color.primary)
            } label: {
                Text(String(localized: "sale.new.profit", bundle: .tinyStockCore))
            }
        }
    }

    // MARK: - Confirmação

    private func confirm() {
        guard let selectedProduct else { return }

        do {
            try SaleService.register(
                lines: [SaleLine(product: selectedProduct, quantity: quantity)],
                paymentMethod: paymentMethod,
                in: modelContext
            )
            dismiss()
        } catch let error as SaleError {
            // Chega aqui se o estoque mudou entre escolher e confirmar.
            errorMessage = error.localizedMessage
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NewSaleView()
        .modelContainer(for: Product.self, inMemory: true)
}
