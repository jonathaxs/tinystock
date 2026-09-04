// Proposito: Exibir a fila operacional de pedidos da loja selecionada.
// Created by Jonathas Motta (@jonathaxs) on 2026-08-07.

import SwiftUI
import SwiftData
import TinyStockCore

struct SalesView: View {
    @Environment(\.modelContext) private var modelContext
    private let storeID: UUID
    @Query private var orders: [SalesOrder]
    @State private var pendingCancellation: SalesOrder?
    @State private var cancellationReason = ""
    @State private var errorMessage: String?

    init(storeID: UUID) {
        self.storeID = storeID
        _orders = Query(
            filter: #Predicate<SalesOrder> { $0.storeID == storeID },
            sort: \SalesOrder.orderedAt,
            order: .reverse
        )
    }

    private var sections: [SalesOrderQueueSection] {
        SalesOrderQueueSection.make(from: orders)
    }

    var body: some View {
        NavigationStack {
            Group {
                if orders.isEmpty { emptyState } else { orderList }
            }
            .navigationTitle(String(localized: "tab.sales", bundle: .tinyStockCore))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { StoreSwitcherView() }
            }
            .alert(String(localized: "order.cancel.title", bundle: .tinyStockCore), isPresented: Binding(
                get: { pendingCancellation != nil },
                set: { if !$0 { clearCancellation() } }
            )) {
                TextField(String(localized: "order.cancel.reason", bundle: .tinyStockCore), text: $cancellationReason)
                Button(String(localized: "common.cancel", bundle: .tinyStockCore), role: .cancel, action: clearCancellation)
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
        .onChange(of: storeID) { _, _ in
            clearCancellation()
            errorMessage = nil
        }
    }

    private var orderList: some View {
        List {
            ForEach(sections) { section in
                Section {
                    ForEach(section.orders) { order in
                        NavigationLink {
                            SalesOrderDetailView(order: order)
                        } label: {
                            SalesOrderRowView(order: order)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            if let action = SalesOrderPresentation.quickAction(for: order) {
                                Button { transition(order, to: action.status) } label: {
                                    Label(action.title, systemImage: action.systemImage)
                                }
                                .tint(action.tint)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if SalesOrderPresentation.canCancel(order) {
                                Button(role: .destructive) { pendingCancellation = order } label: {
                                    Label(String(localized: "order.action.cancel", bundle: .tinyStockCore), systemImage: "xmark")
                                }
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text(section.title)
                        Spacer()
                        Text(section.orders.count, format: .number)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label(String(localized: "order.queue.empty.title", bundle: .tinyStockCore), systemImage: "calendar.badge.clock")
        } description: {
            Text(String(localized: "order.queue.empty.message", bundle: .tinyStockCore))
        }
    }

    private func transition(_ order: SalesOrder, to status: SalesOrderStatus) {
        do {
            try SalesOrderService.transition(id: order.id, to: status, in: modelContext)
        } catch {
            errorMessage = SalesOrderPresentation.message(for: error)
        }
    }

    private func cancelOrder() {
        guard let order = pendingCancellation else { return }
        do {
            try SalesOrderService.cancel(id: order.id, reason: cancellationReason, in: modelContext)
            clearCancellation()
        } catch {
            clearCancellation()
            errorMessage = SalesOrderPresentation.message(for: error)
        }
    }

    private func clearCancellation() {
        pendingCancellation = nil
        cancellationReason = ""
    }
}

private struct SalesOrderQueueSection: Identifiable {
    let id: String
    let title: String
    let orders: [SalesOrder]

    static func make(from orders: [SalesOrder]) -> [SalesOrderQueueSection] {
        var result = SalesOrderStatus.allCases.compactMap { status -> SalesOrderQueueSection? in
            let matches = orders.filter { $0.status == status }
            guard !matches.isEmpty else { return nil }
            return SalesOrderQueueSection(
                id: status.rawValue,
                title: status.localizedName,
                orders: sorted(matches, terminal: status.isTerminal)
            )
        }
        let unknown = orders.filter { $0.status == nil }
        if !unknown.isEmpty {
            result.append(SalesOrderQueueSection(
                id: "unknown",
                title: String(localized: "order.queue.unknown", bundle: .tinyStockCore),
                orders: sorted(unknown, terminal: false)
            ))
        }
        return result
    }

    private static func sorted(_ orders: [SalesOrder], terminal: Bool) -> [SalesOrder] {
        orders.sorted {
            let left = SalesOrderPresentation.queueDate(for: $0)
            let right = SalesOrderPresentation.queueDate(for: $1)
            if left == right { return $0.id.uuidString < $1.id.uuidString }
            return terminal ? left > right : left < right
        }
    }
}

#Preview {
    let storeID = UUID()
    SalesView(storeID: storeID)
        .environment(StoreSession(selectedStoreID: storeID))
        .modelContainer(for: [StoreProfile.self, Product.self, ProductVariant.self, StockMovement.self, SalesOrder.self, SalesOrderItem.self], inMemory: true)
}
