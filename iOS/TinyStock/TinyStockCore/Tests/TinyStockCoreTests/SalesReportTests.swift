// ⌘
//  TinyStockCoreTests/SalesReportTests.swift
//
//  Propósito: Testes dos períodos e totais do relatório financeiro.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-15.
// ⌘

import Testing
import Foundation
import SwiftData
@testable import TinyStockCore

/// Serializada e com banco compartilhado: ver [TestDatabase] para o porquê.
@Suite(.serialized)
@MainActor
struct SalesReportTests {

    let calendar = Calendar(identifier: .gregorian)
    let reference = Date(timeIntervalSince1970: 1_786_742_200) // 15/08/2026 15:30 UTC

    func makeContext() throws -> ModelContext {
        try TestDatabase.makeCleanContext()
    }

    func date(daysFromReference: Int, hour: Int = 12) -> Date {
        let shifted = calendar.date(byAdding: .day, value: daysFromReference, to: reference) ?? reference
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: shifted) ?? shifted
    }

    @discardableResult
    func sell(
        _ product: Product,
        quantity: Int,
        daysFromReference: Int,
        in context: ModelContext
    ) throws -> Sale {
        try SaleService.register(
            lines: [SaleLine(product: product, quantity: quantity)],
            paymentMethod: .pix,
            date: date(daysFromReference: daysFromReference),
            in: context
        )
    }

    // MARK: - Períodos

    @Test func hojeAceitaDoInicioAteAntesDaProximaMeiaNoite() {
        let start = calendar.startOfDay(for: reference)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? reference

        #expect(SalesReportPeriod.today.contains(start, relativeTo: reference, calendar: calendar))
        #expect(SalesReportPeriod.today.contains(end.addingTimeInterval(-1), relativeTo: reference, calendar: calendar))
        #expect(!SalesReportPeriod.today.contains(end, relativeTo: reference, calendar: calendar))
    }

    @Test func seteDiasIncluemHojeEMaisSeisDias() {
        #expect(SalesReportPeriod.lastSevenDays.contains(date(daysFromReference: 0), relativeTo: reference, calendar: calendar))
        #expect(SalesReportPeriod.lastSevenDays.contains(date(daysFromReference: -6), relativeTo: reference, calendar: calendar))
        #expect(!SalesReportPeriod.lastSevenDays.contains(date(daysFromReference: -7), relativeTo: reference, calendar: calendar))
    }

    @Test func mesAtualNaoAceitaODiaPrimeiroDoMesSeguinte() throws {
        let interval = try #require(SalesReportPeriod.currentMonth.dateInterval(relativeTo: reference, calendar: calendar))

        #expect(SalesReportPeriod.currentMonth.contains(interval.start, relativeTo: reference, calendar: calendar))
        #expect(!SalesReportPeriod.currentMonth.contains(interval.end, relativeTo: reference, calendar: calendar))
    }

    @Test func tudoAceitaQualquerData() {
        #expect(SalesReportPeriod.allTime.contains(.distantPast, relativeTo: reference, calendar: calendar))
        #expect(SalesReportPeriod.allTime.contains(.distantFuture, relativeTo: reference, calendar: calendar))
    }

    // MARK: - Totais

    @Test func resumoSomaApenasAsVendasDoPeriodo() throws {
        let context = try makeContext()
        let product = Product(name: "Amigurumi Gato", quantity: 30, costPrice: 20, salePrice: 45)
        context.insert(product)

        try sell(product, quantity: 2, daysFromReference: 0, in: context)
        try sell(product, quantity: 1, daysFromReference: -3, in: context)
        try sell(product, quantity: 4, daysFromReference: -8, in: context)

        let summary = SalesReportSummary(
            sales: try context.fetch(FetchDescriptor<Sale>()),
            period: .lastSevenDays,
            reference: reference,
            calendar: calendar
        )

        #expect(summary.revenue == 135)
        #expect(summary.profit == 75)
        #expect(summary.saleCount == 2)
        #expect(summary.unitCount == 3)
        #expect(summary.dayGroups.count == 2)
    }

    @Test func resumoVazioTemTodosOsTotaisZerados() {
        let summary = SalesReportSummary(sales: [], period: .currentMonth, reference: reference, calendar: calendar)

        #expect(summary.isEmpty)
        #expect(summary.revenue == 0)
        #expect(summary.profit == 0)
        #expect(summary.saleCount == 0)
        #expect(summary.unitCount == 0)
        #expect(summary.dayGroups.isEmpty)
    }

    @Test func diasDoResumoVemDoMaisRecenteProMaisAntigo() throws {
        let context = try makeContext()
        let product = Product(name: "Tapete Redondo", quantity: 10, costPrice: 30, salePrice: 90)
        context.insert(product)

        try sell(product, quantity: 1, daysFromReference: -4, in: context)
        try sell(product, quantity: 1, daysFromReference: 0, in: context)
        try sell(product, quantity: 1, daysFromReference: -2, in: context)

        let summary = SalesReportSummary(
            sales: try context.fetch(FetchDescriptor<Sale>()),
            period: .allTime,
            reference: reference,
            calendar: calendar
        )

        let days = summary.dayGroups.map(\.day)
        #expect(days == days.sorted(by: >))
    }

    @Test func todoPeriodoTemNomeCurto() {
        for period in SalesReportPeriod.allCases {
            #expect(!period.localizedName.isEmpty)
            #expect(period.localizedName.count <= 10)
        }
    }
}
