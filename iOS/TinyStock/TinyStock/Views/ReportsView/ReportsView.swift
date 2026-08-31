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
    @Query private var sales: [Sale]
    @Query private var products: [Product]

    @State private var selectedPeriod: SalesReportPeriod = .currentMonth

    init(storeID: UUID) {
        _sales = Query(
            filter: #Predicate<Sale> { $0.storeID == storeID },
            sort: \Sale.date,
            order: .reverse
        )
        _products = Query(
            filter: #Predicate<Product> { $0.storeID == storeID },
            sort: \Product.name
        )
    }

    private var summary: SalesReportSummary {
        SalesReportSummary(sales: sales, period: selectedPeriod)
    }

    private var bestSellingProducts: [ProductSalesRanking] {
        summary.bestSellingProducts()
    }

    private var productsToRestock: [Product] {
        products
            .filter(\.isLowStock)
            .sorted {
                if $0.quantity != $1.quantity {
                    return $0.quantity < $1.quantity
                }

                return $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sales.isEmpty && productsToRestock.isEmpty {
                    noDataState
                } else {
                    VStack(spacing: 0) {
                        if !sales.isEmpty {
                            periodPicker
                        }

                        reportContent
                    }
                }
            }
            .navigationTitle(String(localized: "tab.reports", bundle: .tinyStockCore))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    StoreSwitcherView()
                }
            }
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
                if sales.isEmpty {
                    noDataState
                        .frame(maxWidth: .infinity, minHeight: 260)
                } else if summary.isEmpty {
                    emptyPeriodState
                } else {
                    metricsGrid

                    bestSellersSection
                }

                if !productsToRestock.isEmpty {
                    restockSection
                }

                if !summary.isEmpty {
                    dailySection
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private var dailySection: some View {
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

    private var bestSellersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "reports.bestSellers.title", bundle: .tinyStockCore))
                .font(.headline)

            VStack(spacing: 0) {
                ForEach(Array(bestSellingProducts.enumerated()), id: \.element.id) { index, ranking in
                    BestSellingRowView(position: index + 1, ranking: ranking)

                    if index < bestSellingProducts.count - 1 {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private var restockSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "reports.restock.title", bundle: .tinyStockCore))
                .font(.headline)

            VStack(spacing: 0) {
                ForEach(Array(productsToRestock.enumerated()), id: \.element.id) { index, product in
                    NavigationLink {
                        ProductDetailView(product: product)
                    } label: {
                        RestockProductRowView(product: product)
                    }
                    .buttonStyle(.plain)

                    if index < productsToRestock.count - 1 {
                        Divider()
                            .padding(.leading, 84)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
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
        .frame(maxWidth: .infinity, minHeight: 260)
    }
}

#Preview {
    ReportsView(storeID: UUID())
        .modelContainer(for: [StoreProfile.self, Product.self, ProductVariant.self, StockMovement.self, Sale.self, SaleItem.self], inMemory: true)
}
