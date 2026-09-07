// Proposito: Mostrar resultados por periodo e a operacao atual da loja selecionada.
// Created by Jonathas Motta (@jonathaxs) on 2026-08-07.

import SwiftUI
import SwiftData
import TinyStockCore

struct ReportsView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let storeID: UUID
    private let openCalendar: (CalendarOrderFilter) -> Void
    @Query private var orders: [SalesOrder]

    @State private var selectedPeriod: SalesReportPeriod = .currentMonth
    @State private var usesCustomPeriod = false
    @State private var customStart = Date()
    @State private var customEnd = Date()
    @State private var showsCustomPeriod = false

    init(storeID: UUID, openCalendar: @escaping (CalendarOrderFilter) -> Void = { _ in }) {
        self.storeID = storeID
        self.openCalendar = openCalendar
        _orders = Query(
            filter: #Predicate<SalesOrder> { $0.storeID == storeID },
            sort: \SalesOrder.orderedAt,
            order: .reverse
        )
    }

    private var reportRange: SalesOrderReportRange {
        usesCustomPeriod
            ? .custom(start: customStart, end: customEnd)
            : .preset(selectedPeriod)
    }

    private var periodTitle: String {
        guard usesCustomPeriod else { return selectedPeriod.localizedName }
        let start = customStart.formatted(date: .abbreviated, time: .omitted)
        let end = customEnd.formatted(date: .abbreviated, time: .omitted)
        return "\(start) - \(end)"
    }

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 60)) { context in
                reportBody(now: context.date)
            }
            .navigationTitle(String(localized: "tab.reports", bundle: .tinyStockCore))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { StoreSwitcherView() }
            }
            .sheet(isPresented: $showsCustomPeriod) {
                ReportCustomPeriodView(initialStart: customStart, initialEnd: customEnd) { start, end in
                    customStart = start
                    customEnd = end
                    usesCustomPeriod = true
                }
            }
        }
        .onChange(of: storeID) { _, _ in
            selectedPeriod = .currentMonth
            usesCustomPeriod = false
            customStart = Date()
            customEnd = Date()
        }
    }

    private func reportBody(now: Date) -> some View {
        let summary = SalesOrderReportSummary(
            orders: orders,
            storeID: storeID,
            range: reportRange,
            reference: now,
            calendar: calendar
        )
        return Group {
            if orders.isEmpty {
                noDataState
            } else {
                VStack(spacing: 0) {
                    periodMenu
                    reportContent(summary: summary)
                }
            }
        }
    }

    private var periodMenu: some View {
        Menu {
            ForEach(SalesReportPeriod.allCases) { period in
                Button {
                    selectedPeriod = period
                    usesCustomPeriod = false
                } label: {
                    if !usesCustomPeriod && selectedPeriod == period {
                        Label(period.localizedName, systemImage: "checkmark")
                    } else {
                        Text(period.localizedName)
                    }
                }
            }
            Divider()
            Button {
                showsCustomPeriod = true
            } label: {
                if usesCustomPeriod {
                    Label(String(localized: "reports.period.custom", bundle: .tinyStockCore), systemImage: "checkmark")
                } else {
                    Text(String(localized: "reports.period.custom", bundle: .tinyStockCore))
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "calendar")
                Text(String(localized: "reports.period.label", bundle: .tinyStockCore))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 12)
                Text(periodTitle).lineLimit(1)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .accessibilityLabel(String(localized: "reports.period.label", bundle: .tinyStockCore))
        .accessibilityValue(periodTitle)
    }

    private func reportContent(summary: SalesOrderReportSummary) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                operationSection(summary.operations)

                if summary.received.isEmpty {
                    emptyPeriodState
                } else {
                    receivedSection(summary.received)
                    bestSellersSection(summary.bestSellingProducts())
                    channelsSection(summary.channelGroups)
                    dailySection(summary.dayGroups)
                }

                activitySection(summary)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Resultado do periodo

    private func receivedSection(_ totals: SalesOrderReportTotals) -> some View {
        reportSection(title: String(localized: "reports.received.title", bundle: .tinyStockCore)) {
            LazyVGrid(columns: metricColumns, spacing: 12) {
                ReportMetricView(
                    title: String(localized: "reports.metric.revenue", bundle: .tinyStockCore),
                    value: totals.revenue.currencyText,
                    symbolName: "brazilianrealsign",
                    tint: .green
                )
                ReportMetricView(
                    title: String(localized: "reports.metric.netProfit", bundle: .tinyStockCore),
                    value: totals.netProfit.currencyText,
                    symbolName: "chart.line.uptrend.xyaxis",
                    tint: totals.netProfit < 0 ? .red : .blue
                )
                ReportMetricView(
                    title: String(localized: "reports.metric.orders", bundle: .tinyStockCore),
                    value: totals.orderCount.formatted(),
                    symbolName: "cart.fill",
                    tint: .orange
                )
                ReportMetricView(
                    title: String(localized: "reports.metric.units", bundle: .tinyStockCore),
                    value: totals.unitCount.formatted(.number.precision(.fractionLength(0))),
                    symbolName: "shippingbox.fill",
                    tint: .teal
                )
                ReportMetricView(
                    title: String(localized: "reports.metric.cost", bundle: .tinyStockCore),
                    value: totals.cost.currencyText,
                    symbolName: "wrench.and.screwdriver.fill",
                    tint: .indigo
                )
                ReportMetricView(
                    title: String(localized: "reports.metric.fees", bundle: .tinyStockCore),
                    value: totals.channelFees.currencyText,
                    symbolName: "percent",
                    tint: .pink
                )
            }
        }
    }

    private func activitySection(_ summary: SalesOrderReportSummary) -> some View {
        reportSection(title: String(localized: "reports.activity.title", bundle: .tinyStockCore)) {
            VStack(spacing: 0) {
                ReportCountRowView(
                    title: String(localized: "reports.activity.dispatched", bundle: .tinyStockCore),
                    count: summary.dispatched.orderCount,
                    symbolName: "paperplane.fill",
                    tint: .blue
                )
                activityDivider
                ReportCountRowView(
                    title: String(localized: "reports.activity.completed", bundle: .tinyStockCore),
                    count: summary.completed.orderCount,
                    symbolName: "checkmark.circle.fill",
                    tint: .green
                )
                activityDivider
                ReportCountRowView(
                    title: String(localized: "reports.activity.cancelled", bundle: .tinyStockCore),
                    count: summary.cancelled.orderCount,
                    symbolName: "xmark.circle.fill",
                    tint: .red
                )
            }
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Operacao atual

    private func operationSection(_ operations: SalesOrderOperationalSummary) -> some View {
        reportSection(title: String(localized: "reports.operation.title", bundle: .tinyStockCore)) {
            VStack(spacing: 0) {
                operationButton(
                    title: String(localized: "reports.operation.toProduce", bundle: .tinyStockCore),
                    queue: operations.toProduce,
                    symbolName: "hammer.fill",
                    tint: .orange,
                    filter: .production
                )
                operationDivider
                operationButton(
                    title: String(localized: "reports.operation.readyToShip", bundle: .tinyStockCore),
                    queue: operations.readyToShip,
                    symbolName: "shippingbox.fill",
                    tint: .blue,
                    filter: .status(.readyToShip)
                )
                operationDivider
                operationButton(
                    title: String(localized: "reports.operation.overdue", bundle: .tinyStockCore),
                    queue: operations.overdue,
                    symbolName: "exclamationmark.triangle.fill",
                    tint: .red,
                    filter: .overdue
                )
                operationDivider
                operationButton(
                    title: String(localized: "reports.operation.shipped", bundle: .tinyStockCore),
                    queue: operations.shipped,
                    symbolName: "paperplane.fill",
                    tint: .green,
                    filter: .status(.shipped)
                )
            }
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private func operationButton(
        title: String,
        queue: SalesOrderReportQueue,
        symbolName: String,
        tint: Color,
        filter: CalendarOrderFilter
    ) -> some View {
        Button { openCalendar(filter) } label: {
            ReportOperationRowView(
                title: title,
                orderCount: queue.orderCount,
                unitCount: queue.unitCount,
                symbolName: symbolName,
                tint: tint
            )
        }
        .buttonStyle(.plain)
    }

    private var operationDivider: some View {
        Divider().padding(.leading, 52)
    }

    private var activityDivider: some View {
        Divider().padding(.leading, 52)
    }

    // MARK: - Detalhamentos

    private func bestSellersSection(_ rankings: [SalesOrderProductRanking]) -> some View {
        reportSection(title: String(localized: "reports.bestSellers.title", bundle: .tinyStockCore)) {
            groupedRows(rankings) { index, ranking in
                BestSellingRowView(position: index + 1, ranking: ranking)
            }
        }
    }

    private func channelsSection(_ channels: [SalesOrderChannelSummary]) -> some View {
        reportSection(title: String(localized: "reports.channels.title", bundle: .tinyStockCore)) {
            groupedRows(channels) { _, channel in
                ReportChannelRowView(channel: channel)
            }
        }
    }

    private func dailySection(_ groups: [SalesOrderReportDay]) -> some View {
        reportSection(title: String(localized: "reports.daily.title", bundle: .tinyStockCore)) {
            groupedRows(groups) { _, group in
                ReportDayRowView(group: group)
            }
        }
    }

    private func reportSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            content()
        }
    }

    private func groupedRows<Item: Identifiable, Row: View>(
        _ items: [Item],
        @ViewBuilder row: @escaping (Int, Item) -> Row
    ) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                row(index, item)
                if index < items.count - 1 { Divider().padding(.leading, 16) }
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var metricColumns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }

    private var noDataState: some View {
        ContentUnavailableView {
            Label(String(localized: "reports.placeholder.title", bundle: .tinyStockCore), systemImage: "chart.bar")
        } description: {
            Text(String(localized: "reports.placeholder.message", bundle: .tinyStockCore))
        }
    }

    private var emptyPeriodState: some View {
        ContentUnavailableView {
            Label(String(localized: "reports.empty.period.title", bundle: .tinyStockCore), systemImage: "calendar.badge.exclamationmark")
        } description: {
            Text(String(localized: "reports.empty.period.message", bundle: .tinyStockCore))
        }
        .frame(maxWidth: .infinity, minHeight: 220)
    }
}

#Preview {
    let storeID = UUID()
    ReportsView(storeID: storeID)
        .environment(StoreSession(selectedStoreID: storeID))
        .modelContainer(for: [StoreProfile.self, Product.self, ProductVariant.self, StockMovement.self, SalesOrder.self, SalesOrderItem.self], inMemory: true)
}
