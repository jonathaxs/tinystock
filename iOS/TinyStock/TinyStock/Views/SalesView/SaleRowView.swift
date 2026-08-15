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
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(titleText)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Label(sale.paymentMethod.localizedName, systemImage: sale.paymentMethod.symbolName)

                    Text(verbatim: "·")

                    Text(quantityText)

                    Text(verbatim: "·")

                    Text(sale.date, format: .dateTime.hour().minute())
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(sale.total.currencyText)
                .font(.headline)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    List {
        SaleRowView(sale: Sale(paymentMethod: .pix))
    }
}
