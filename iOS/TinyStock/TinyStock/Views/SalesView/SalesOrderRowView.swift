// Proposito: Resumir um pedido na fila operacional.
// Created by Jonathas Motta (@jonathaxs) on 2026-09-03.

import SwiftUI
import TinyStockCore

struct SalesOrderRowView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let order: SalesOrder

    private var firstItem: SalesOrderItem? { order.itemList.first }
    private var title: String {
        guard let firstItem else { return String(localized: "order.queue.untitled", bundle: .tinyStockCore) }
        guard order.itemList.count > 1 else { return firstItem.productName }
        return String(
            format: String(localized: "order.queue.moreItems", bundle: .tinyStockCore),
            firstItem.productName, (order.itemList.count - 1).formatted()
        )
    }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    mainInformation
                    financialInformation
                }
            } else {
                HStack(spacing: 12) {
                    mainInformation
                    Spacer(minLength: 8)
                    financialInformation
                }
            }
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
    }

    private var mainInformation: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline).fixedSize(horizontal: false, vertical: true)
            if let firstItem {
                Text(String(
                    format: String(localized: "order.queue.itemMetadata", bundle: .tinyStockCore),
                    firstItem.variantName, order.totalQuantity.formatted()
                ))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Label(SalesOrderPresentation.deadlineTitle(for: order), systemImage: "calendar")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var financialInformation: some View {
        VStack(alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing, spacing: 3) {
            Text(order.total.currencyText).fontWeight(.semibold)
            Text(order.buyerName.isEmpty ? order.channelDisplayName : order.buyerName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }
}
