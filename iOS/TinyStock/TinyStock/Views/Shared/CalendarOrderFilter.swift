// Proposito: Compartilhar filtros ao navegar dos relatorios para o calendario.
// Created by Jonathas Motta (@jonathaxs) on 2026-09-06.

import Foundation
import TinyStockCore

enum CalendarOrderFilter: Hashable {
    case all
    case overdue
    case production
    case status(SalesOrderStatus)

    var title: String {
        switch self {
        case .all:
            String(localized: "order.calendar.allStatuses", bundle: .tinyStockCore)
        case .overdue:
            String(localized: "order.calendar.overdue", bundle: .tinyStockCore)
        case .production:
            String(localized: "reports.operation.toProduce", bundle: .tinyStockCore)
        case .status(let status):
            status.localizedName
        }
    }

    func includes(_ order: SalesOrder, now: Date, calendar: Calendar) -> Bool {
        switch self {
        case .all:
            true
        case .overdue:
            SalesOrderSchedule.isOverdue(order, now: now, calendar: calendar)
        case .production:
            order.status == .awaitingProduction || order.status == .inProduction
        case .status(let status):
            order.status == status
        }
    }
}
