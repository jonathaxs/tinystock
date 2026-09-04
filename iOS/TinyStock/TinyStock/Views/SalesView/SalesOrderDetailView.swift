// Proposito: Exibir o pedido e oferecer suas operacoes validas.
// Created by Jonathas Motta (@jonathaxs) on 2026-09-03.

import SwiftUI
import SwiftData
import TinyStockCore

struct SalesOrderDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var order: SalesOrder
    @State private var isEditing = false
    @State private var isConfirmingCancellation = false
    @State private var cancellationReason = ""
    @State private var errorMessage: String?

    var body: some View {
        List {
            statusSection
            itemsSection
            customerSection
            datesSection
            financialSection
            additionalSection
            actionsSection
        }
        .navigationTitle(String(localized: "order.detail.title", bundle: .tinyStockCore))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(String(localized: "common.edit", bundle: .tinyStockCore)) { isEditing = true }
                    .disabled(!SalesOrderPresentation.canEdit(order))
            }
        }
        .sheet(isPresented: $isEditing) { SalesOrderEditView(order: order) }
        .alert(String(localized: "order.cancel.title", bundle: .tinyStockCore), isPresented: $isConfirmingCancellation) {
            TextField(String(localized: "order.cancel.reason", bundle: .tinyStockCore), text: $cancellationReason)
            Button(String(localized: "common.cancel", bundle: .tinyStockCore), role: .cancel) { cancellationReason = "" }
            Button(String(localized: "order.action.cancel", bundle: .tinyStockCore), role: .destructive, action: cancelOrder)
        } message: {
            Text(String(localized: "order.cancel.message", bundle: .tinyStockCore))
        }
        .alert(String(localized: "order.operation.error.title", bundle: .tinyStockCore), isPresented: Binding(
            get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }

    private var statusSection: some View {
        Section {
            LabeledContent(String(localized: "order.detail.status", bundle: .tinyStockCore)) {
                Text(order.status?.localizedName ?? String(localized: "order.queue.unknown", bundle: .tinyStockCore))
                    .fontWeight(.semibold)
            }
            LabeledContent(String(localized: "order.form.fulfillment", bundle: .tinyStockCore)) {
                Text(order.fulfillment?.localizedName ?? String(localized: "order.queue.unknown", bundle: .tinyStockCore))
            }
        }
    }

    private var itemsSection: some View {
        Section(String(localized: "order.detail.items", bundle: .tinyStockCore)) {
            ForEach(order.itemList) { item in
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.productName).fontWeight(.medium)
                        Text(item.variantName).font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 12)
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(item.subtotal.currencyText)
                        Text(item.quantity, format: .number).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var customerSection: some View {
        Section(String(localized: "order.form.section.customer", bundle: .tinyStockCore)) {
            if !order.buyerName.isEmpty {
                LabeledContent(String(localized: "order.detail.buyer", bundle: .tinyStockCore), value: order.buyerName)
            }
            if !order.externalReference.isEmpty {
                LabeledContent(String(localized: "order.detail.reference", bundle: .tinyStockCore), value: order.externalReference)
            }
            LabeledContent(String(localized: "order.form.channel", bundle: .tinyStockCore), value: order.channelDisplayName)
        }
    }

    private var datesSection: some View {
        Section(String(localized: "order.form.section.dates", bundle: .tinyStockCore)) {
            dateRow("order.form.orderedAt", order.orderedAt)
            if let date = order.productionDueAt { dateRow("order.form.productionDueAt", date) }
            if let date = order.shippingDueAt { dateRow("order.form.shippingDueAt", date) }
            if let date = order.productionStartedAt { dateRow("order.detail.productionStartedAt", date, includesTime: true) }
            if let date = order.producedAt { dateRow("order.detail.producedAt", date, includesTime: true) }
            if let date = order.shippedAt { dateRow("order.detail.shippedAt", date, includesTime: true) }
            if let date = order.completedAt { dateRow("order.detail.completedAt", date, includesTime: true) }
            if let date = order.cancelledAt { dateRow("order.detail.cancelledAt", date, includesTime: true) }
        }
    }

    private var financialSection: some View {
        Section(String(localized: "order.form.section.summary", bundle: .tinyStockCore)) {
            LabeledContent(String(localized: "order.form.total", bundle: .tinyStockCore), value: order.total.currencyText)
            LabeledContent(String(localized: "order.form.fee", bundle: .tinyStockCore), value: order.channelFeeAmount.currencyText)
            LabeledContent(String(localized: "order.detail.grossProfit", bundle: .tinyStockCore), value: order.grossProfit.currencyText)
            LabeledContent(String(localized: "order.form.netProfit", bundle: .tinyStockCore), value: order.netProfit.currencyText)
        }
    }

    @ViewBuilder
    private var additionalSection: some View {
        if !order.trackingCode.isEmpty || !order.note.isEmpty || !order.cancellationReason.isEmpty {
            Section(String(localized: "order.detail.additional", bundle: .tinyStockCore)) {
                if !order.trackingCode.isEmpty {
                    LabeledContent(String(localized: "order.edit.tracking", bundle: .tinyStockCore), value: order.trackingCode)
                }
                if !order.note.isEmpty { Text(order.note) }
                if !order.cancellationReason.isEmpty {
                    LabeledContent(String(localized: "order.detail.cancellationReason", bundle: .tinyStockCore), value: order.cancellationReason)
                }
            }
        }
    }

    @ViewBuilder
    private var actionsSection: some View {
        if let action = SalesOrderPresentation.quickAction(for: order) {
            Section {
                Button { transition(to: action.status) } label: {
                    Label(action.title, systemImage: action.systemImage)
                }
            }
        }
        if SalesOrderPresentation.canCancel(order) {
            Section {
                Button(role: .destructive) { isConfirmingCancellation = true } label: {
                    Label(String(localized: "order.action.cancel", bundle: .tinyStockCore), systemImage: "xmark.circle")
                }
            }
        }
    }

    private func dateRow(_ key: String.LocalizationValue, _ date: Date, includesTime: Bool = false) -> some View {
        LabeledContent(String(localized: key, bundle: .tinyStockCore)) {
            Text(includesTime ? date.formatted(date: .abbreviated, time: .shortened) : date.formatted(date: .abbreviated, time: .omitted))
        }
    }

    private func transition(to status: SalesOrderStatus) {
        do {
            try SalesOrderService.transition(id: order.id, to: status, in: modelContext)
        } catch {
            errorMessage = SalesOrderPresentation.message(for: error)
        }
    }

    private func cancelOrder() {
        do {
            try SalesOrderService.cancel(id: order.id, reason: cancellationReason, in: modelContext)
            cancellationReason = ""
        } catch {
            errorMessage = SalesOrderPresentation.message(for: error)
        }
    }
}
