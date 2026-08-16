// ⌘
//  TinyStock/Views/ReportsView/ReportsView.swift
//
//  Propósito: Mostrar receita, lucro e volume de vendas dentro do período escolhido.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-07.
// ⌘

import SwiftUI
import SwiftData
import TinyStockCore

struct ReportsView: View {

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query(sort: \Sale.date, order: .reverse) private var sales: [Sale]

    @State private var selectedPeriod: SalesReportPeriod = .currentMonth

    private var summary: SalesReportSummary {
        SalesReportSummary(sales: sales, period: selectedPeriod)
    }

    var body: some View {
        NavigationStack {
            Group {
                if sales.isEmpty {
                    noDataState
                } else {
                    VStack(spacing: 0) {
                        periodPicker

                        if summary.isEmpty {
                            emptyPeriodState
                        } else {
                            reportContent
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "tab.reports", bundle: .tinyStockCore))
        }
    }

    // MARK: - Período

    private var periodPicker: some View {
        Picker(
            String(localized: "tab.reports", bundle: .tinyStockCore),
            selection: $selectedPeriod
        ) {
            ForEach(SalesReportPeriod.allCases) { period in
                Text(period.localizedName).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    // MARK: - Conteúdo

    private var reportContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                metricsGrid

                VStack(alignment: .leading, spacing: 10) {
                    Text(String(localized: "reports.daily.title", bundle: .tinyStockCore))
                        .font(.headline)

                    VStack(spacing: 0) {
                        ForEach(Array(summary.dayGroups.enumerated()), id: \.element.id) { index, group in
                            ReportDayRowView(group: group)

                            if index < summary.dayGroups.count - 1 {
                                Divider()
                                    .padding(.leading, 16)
                            }
                        }
                    }
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private var metricsGrid: some View {
        LazyVGrid(
            columns: metricColumns,
            spacing: 12
        ) {
            ReportMetricView(
                title: String(localized: "reports.metric.revenue", bundle: .tinyStockCore),
                value: summary.revenue.currencyText,
                symbolName: "brazilianrealsign",
                tint: .green
            )

            ReportMetricView(
                title: String(localized: "reports.metric.profit", bundle: .tinyStockCore),
                value: summary.profit.currencyText,
                symbolName: "chart.line.uptrend.xyaxis",
                tint: .blue
            )

            ReportMetricView(
                title: String(localized: "reports.metric.sales", bundle: .tinyStockCore),
                value: summary.saleCount.formatted(),
                symbolName: "cart.fill",
                tint: .orange
            )

            ReportMetricView(
                title: String(localized: "reports.metric.units", bundle: .tinyStockCore),
                value: summary.unitCount.formatted(),
                symbolName: "shippingbox.fill",
                tint: .teal
            )
        }
    }

    private var metricColumns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.flexible())]
        }

        return [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    // MARK: - Estados vazios

    private var noDataState: some View {
        ContentUnavailableView {
            Label(
                String(localized: "reports.placeholder.title", bundle: .tinyStockCore),
                systemImage: "chart.bar"
            )
        } description: {
            Text(String(localized: "reports.placeholder.message", bundle: .tinyStockCore))
        }
    }

    private var emptyPeriodState: some View {
        ContentUnavailableView {
            Label(
                String(localized: "reports.empty.period.title", bundle: .tinyStockCore),
                systemImage: "calendar.badge.exclamationmark"
            )
        } description: {
            Text(String(localized: "reports.empty.period.message", bundle: .tinyStockCore))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ReportsView()
        .modelContainer(for: [Product.self, Sale.self, SaleItem.self], inMemory: true)
}
