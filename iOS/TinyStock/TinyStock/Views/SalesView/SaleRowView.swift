// ⌘
//  TinyStock/Views/SalesView/SaleRowView.swift
//
//  Propósito: Linha do histórico de vendas, com itens, forma de pagamento, horário e total.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-11.
// ⌘

import SwiftUI
import SwiftData
import TinyStockCore

struct SaleRowView: View {

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let sale: Sale

    private var quantityText: String {
        String(
            format: String(localized: "sales.row.quantity", bundle: .tinyStockCore),
            sale.totalQuantity
        )
    }

    /// Com um produto só, o nome dele diz mais do que "1 un". Com vários, o nome
    /// sozinho enganaria: pareceria que aquele produto custou o total da venda.
    private var titleText: String {
        let items = sale.itemList

        guard let first = items.first else { return quantityText }
        guard items.count > 1 else { return first.productName }

        return String(
            format: String(localized: "sales.row.moreItems", bundle: .tinyStockCore),
            first.productName,
            items.count - 1
        )
    }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    saleInformation
                    financialInformation
                }
            } else {
                HStack(spacing: 12) {
                    saleInformation

                    Spacer(minLength: 12)

                    financialInformation
                }
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    private var saleInformation: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titleText)
                .font(.headline)

            Label(metadataText, systemImage: sale.paymentMethod.symbolName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var financialInformation: some View {
        VStack(
            alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing,
            spacing: 2
        ) {
            Text(sale.total.currencyText)
                .font(.headline)

            if sale.channelFeeAmount > 0 {
                Text(netProfitText)
                    .font(.caption)
                    .foregroundStyle(sale.netProfit < 0 ? Color.red : Color.secondary)
            }
        }
    }

    private var metadataText: String {
        let time = sale.date.formatted(.dateTime.hour().minute())
        return "\(sale.paymentMethod.localizedName) · \(quantityText) · \(time)"
    }

    private var netProfitText: String {
        String(
            format: String(localized: "sales.row.netProfit", bundle: .tinyStockCore),
            sale.netProfit.currencyText
        )
    }
}

#Preview {
    List {
        SaleRowView(sale: Sale(paymentMethod: .pix))
    }
}
