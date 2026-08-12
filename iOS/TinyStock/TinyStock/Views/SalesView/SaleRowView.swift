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

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                // Com um item só, o nome do produto diz mais do que "1 un".
                Text(sale.itemList.first?.productName ?? quantityText)
                    .font(.headline)

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
