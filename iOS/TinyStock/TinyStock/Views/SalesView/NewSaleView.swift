// ⌘
//  TinyStock/Views/SalesView/NewSaleView.swift
//
//  Propósito: Registrar uma venda com um ou vários produtos, quantidade e forma de pagamento.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-11.
// ⌘

import SwiftUI
import SwiftData
import TinyStockCore

struct NewSaleView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Itens escolhidos até agora. Somar produto repetido e parar no estoque
    /// é regra, então mora no carrinho, no Core, e não aqui.
    @State private var cart = SaleCart()

    @State private var paymentMethod: PaymentMethod = .pix

    /// Guarda a última taxa informada pra próxima venda feita pela Shopee.
    @AppStorage("sale.shopeeFeePercentage") private var shopeeFeePercentageText = ""

    /// Mensagem do erro devolvido pelo Core. Não nil significa alerta na tela.
    @State private var errorMessage: String?

    private var channelFeePercentage: Decimal {
        guard paymentMethod == .shopee else { return 0 }
        return CurrencyFormatter.decimal(from: shopeeFeePercentageText) ?? 0
    }

    private var isChannelFeeValid: Bool {
        channelFeePercentage >= 0 && channelFeePercentage <= 100
    }

    private var channelFeeAmount: Decimal {
        cart.channelFee(percentage: channelFeePercentage)
    }

    private var netProfit: Decimal {
        cart.netProfit(channelFeePercentage: channelFeePercentage)
    }

    private var canSave: Bool {
        !cart.isEmpty && isChannelFeeValid
    }

    // MARK: - Corpo

    var body: some View {
        NavigationStack {
            Form {
                itemsSection

                // Sem item escolhido não há o que pagar nem o que somar.
                if !cart.isEmpty {
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
                    .disabled(!canSave)
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

    // MARK: - Itens

    private var itemsSection: some View {
        Section {
            ForEach(cart.lines, id: \.product.id) { line in
                lineRow(for: line)
            }
            .onDelete { offsets in
                cart.remove(atOffsets: offsets)
            }

            NavigationLink {
                // O picker devolve o produto e volta. A quantidade se ajusta
                // na própria linha, que é onde a pessoa está olhando.
                ProductPickerView(
                    remainingStock: { cart.remainingStock(of: $0) },
                    onSelect: { cart.add($0) }
                )
            } label: {
                Label(
                    String(localized: "sale.new.addProduct", bundle: .tinyStockCore),
                    systemImage: "plus.circle.fill"
                )
            }
        } header: {
            Text(String(localized: "sale.new.section.items", bundle: .tinyStockCore))
        } footer: {
            Text(String(localized: "sale.new.quantity.footer", bundle: .tinyStockCore))
        }
    }

    private func lineRow(for line: SaleLine) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 4) {
                    Text(line.product.name)
                        .font(.headline)

                    Text(subtotal(of: line).currencyText)
                        .font(.headline)
                }
            } else {
                HStack {
                    Text(line.product.name)
                        .font(.headline)

                    Spacer(minLength: 12)

                    Text(subtotal(of: line).currencyText)
                        .font(.headline)
                }
            }

            HStack {
                Text(unitText(for: line))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                // Trava no estoque do produto, então não dá pra montar
                // um carrinho que a confirmação vai recusar.
                Stepper(
                    String(localized: "sale.new.section.quantity", bundle: .tinyStockCore),
                    value: quantityBinding(for: line.product),
                    in: 1...max(1, line.product.quantity)
                )
                .labelsHidden()
                .fixedSize()
                .accessibilityLabel(stepperAccessibilityLabel(for: line.product))
                .accessibilityValue(Text(line.quantity, format: .number))
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Pagamento e resumo

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

            if paymentMethod == .shopee {
                LabeledContent {
                    HStack(spacing: 4) {
                        TextField("0", text: $shopeeFeePercentageText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 72)

                        Text(verbatim: "%")
                            .foregroundStyle(.secondary)
                    }
                } label: {
                    Label(
                        String(localized: "sale.new.channelFeePercentage", bundle: .tinyStockCore),
                        systemImage: "percent"
                    )
                }
            }
        }
    }

    private var summarySection: some View {
        Section(String(localized: "sale.new.section.summary", bundle: .tinyStockCore)) {
            LabeledContent {
                Text(cart.unitCount, format: .number)
                    .font(.body.monospacedDigit())
            } label: {
                Text(String(localized: "sale.new.section.quantity", bundle: .tinyStockCore))
            }

            LabeledContent {
                Text(cart.total.currencyText)
                    .font(.headline)
            } label: {
                Text(String(localized: "sale.new.total", bundle: .tinyStockCore))
            }

            LabeledContent {
                Text(cart.profit.currencyText)
            } label: {
                Text(String(localized: "sale.new.grossProfit", bundle: .tinyStockCore))
            }

            if paymentMethod == .shopee {
                LabeledContent {
                    Text(channelFeeText)
                } label: {
                    Text(String(localized: "sale.new.channelFee", bundle: .tinyStockCore))
                }
            }

            LabeledContent {
                Text(netProfit.currencyText)
                    .font(.headline)
                    .foregroundStyle(netProfit < 0 ? Color.red : Color.primary)
            } label: {
                Text(String(localized: "sale.new.netProfit", bundle: .tinyStockCore))
            }
        }
    }

    // MARK: - Apoio

    private func subtotal(of line: SaleLine) -> Decimal {
        line.product.salePrice * Decimal(line.quantity)
    }

    /// Texto do tipo "2 × R$ 45,00", que explica de onde saiu o subtotal.
    private func unitText(for line: SaleLine) -> String {
        String(
            format: String(localized: "sale.new.line.unit", bundle: .tinyStockCore),
            line.quantity,
            line.product.salePrice.currencyText
        )
    }

    private func stepperAccessibilityLabel(for product: Product) -> String {
        String(
            format: String(localized: "sale.new.quantity.accessibility", bundle: .tinyStockCore),
            product.name
        )
    }

    private func quantityBinding(for product: Product) -> Binding<Int> {
        Binding(
            get: { cart.quantity(of: product) },
            set: { cart.setQuantity($0, for: product) }
        )
    }

    private var channelFeeText: String {
        guard channelFeeAmount > 0 else { return Decimal.zero.currencyText }
        return "- \(channelFeeAmount.currencyText)"
    }

    // MARK: - Confirmação

    private func confirm() {
        guard !cart.isEmpty else { return }

        do {
            try SaleService.register(
                lines: cart.lines,
                paymentMethod: paymentMethod,
                channelFeePercentage: channelFeePercentage,
                in: modelContext
            )
            dismiss()
        } catch let error as SaleError {
            // Chega aqui se o estoque mudou entre montar o carrinho e confirmar.
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
