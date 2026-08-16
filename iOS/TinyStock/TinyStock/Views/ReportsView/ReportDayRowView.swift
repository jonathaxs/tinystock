// ⌘
//  TinyStock/Views/ReportsView/ReportDayRowView.swift
//
//  Propósito: Detalhar o total e o lucro de um dia dentro do relatório.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-15.
// ⌘

import SwiftUI
import TinyStockCore

struct ReportDayRowView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let group: SaleDayGroup

    private var salesCountText: String {
        if group.sales.count == 1 {
            return String(
                format: String(localized: "reports.daily.sales.one", bundle: .tinyStockCore),
                group.sales.count
            )
        }

        return String(
            format: String(localized: "reports.daily.sales.other", bundle: .tinyStockCore),
            group.sales.count
        )
    }

    private var profitText: String {
        String(
            format: String(localized: "reports.daily.profit", bundle: .tinyStockCore),
            group.profit.currencyText
        )
    }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 12) {
                    dayInformation
                    financialInformation
                }
            } else {
                HStack(spacing: 12) {
                    dayInformation

                    Spacer(minLength: 12)

                    financialInformation
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .padding(16)
        .accessibilityElement(children: .combine)
    }

    private var dayInformation: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(group.title())
                .font(.headline)

            Text(salesCountText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var financialInformation: some View {
        VStack(alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing, spacing: 4) {
            Text(group.total.currencyText)
                .font(.headline)
                .monospacedDigit()

            Text(profitText)
                .font(.subheadline)
                .foregroundStyle(group.profit < 0 ? Color.red : Color.secondary)
                .monospacedDigit()
        }
    }
}
