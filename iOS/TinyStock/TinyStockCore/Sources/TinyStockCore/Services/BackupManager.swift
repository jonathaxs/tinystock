// ⌘
//  TinyStockCore/Services/BackupManager.swift
//
//  Propósito: Exportar, validar e restaurar o banco completo por meio de um backup JSON.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-16.
// ⌘

import Foundation
import SwiftData

public enum BackupError: Error, Equatable, Sendable {
    case invalidFile
    case unsupportedVersion(Int)
}

extension BackupError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidFile:
            String(localized: "backup.error.invalidFile", bundle: .tinyStockCore)
        case .unsupportedVersion:
            String(localized: "backup.error.unsupportedVersion", bundle: .tinyStockCore)
        }
    }
}

public enum BackupManager {
    public static let currentVersion = 1

    // MARK: - Exportar

    public static func export(
        products: [Product],
        sales: [Sale],
        exportedAt: Date = Date()
    ) throws -> Data {
        let payload = BackupPayload(
            version: currentVersion,
            exportedAt: exportedAt,
            products: products.map(productSnapshot),
            sales: sales.map(saleSnapshot)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(payload)
    }

    // MARK: - Decodificar e validar

    public static func decode(_ data: Data) throws -> BackupPayload {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let payload: BackupPayload
        do {
            payload = try decoder.decode(BackupPayload.self, from: data)
        } catch {
            throw BackupError.invalidFile
        }

        guard payload.version == currentVersion else {
            throw BackupError.unsupportedVersion(payload.version)
        }
        guard isValid(payload) else {
            throw BackupError.invalidFile
        }

        return payload
    }

    // MARK: - Restaurar

    /// Substitui o banco dentro de uma transação. Qualquer falha desfaz todas as alterações.
    public static func apply(_ payload: BackupPayload, into context: ModelContext) throws {
        guard payload.version == currentVersion else {
            throw BackupError.unsupportedVersion(payload.version)
        }
        guard isValid(payload) else {
            throw BackupError.invalidFile
        }

        try context.transaction {
            try context.delete(model: SaleItem.self)
            try context.delete(model: Sale.self)
            try context.delete(model: Product.self)

            for snapshot in payload.products {
                context.insert(
                    Product(
                        id: snapshot.id,
                        name: snapshot.name,
                        category: snapshot.category,
                        quantity: snapshot.quantity,
                        minimumStock: snapshot.minimumStock,
                        costPrice: snapshot.costPrice,
                        salePrice: snapshot.salePrice,
                        imageData: snapshot.imageData,
                        createdAt: snapshot.createdAt,
                        updatedAt: snapshot.updatedAt
                    )
                )
            }

            for snapshot in payload.sales {
                let sale = Sale(
                    id: snapshot.id,
                    date: snapshot.date,
                    paymentMethod: PaymentMethod(rawValue: snapshot.paymentMethod) ?? .pix,
                    note: snapshot.note,
                    channelFeePercentage: snapshot.channelFeePercentage,
                    channelFeeAmount: snapshot.channelFeeAmount
                )
                // Preserva o texto original mesmo se uma versão antiga tiver gravado outro valor.
                sale.paymentMethodRawValue = snapshot.paymentMethod
                sale.items = snapshot.items.map {
                    SaleItem(
                        id: $0.id,
                        productID: $0.productID,
                        productName: $0.productName,
                        unitPrice: $0.unitPrice,
                        unitCost: $0.unitCost,
                        quantity: $0.quantity,
                        sale: sale
                    )
                }
                context.insert(sale)
            }

            try context.save()
        }
    }

    // MARK: - Nome sugerido

    public static func suggestedFilename(relativeTo date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return "tinystock-backup-\(formatter.string(from: date)).json"
    }

    // MARK: - Snapshots

    private static func productSnapshot(_ product: Product) -> BackupPayload.ProductSnapshot {
        BackupPayload.ProductSnapshot(
            id: product.id,
            name: product.name,
            category: product.category,
            quantity: product.quantity,
            minimumStock: product.minimumStock,
            costPrice: product.costPrice,
            salePrice: product.salePrice,
            imageData: product.imageData,
            createdAt: product.createdAt,
            updatedAt: product.updatedAt
        )
    }

    private static func saleSnapshot(_ sale: Sale) -> BackupPayload.SaleSnapshot {
        BackupPayload.SaleSnapshot(
            id: sale.id,
            date: sale.date,
            paymentMethod: sale.paymentMethodRawValue,
            note: sale.note,
            channelFeePercentage: sale.channelFeePercentage,
            channelFeeAmount: sale.channelFeeAmount,
            items: sale.itemList.map {
                BackupPayload.SaleItemSnapshot(
                    id: $0.id,
                    productID: $0.productID,
                    productName: $0.productName,
                    unitPrice: $0.unitPrice,
                    unitCost: $0.unitCost,
                    quantity: $0.quantity
                )
            }
        )
    }

    // MARK: - Integridade

    private static func isValid(_ payload: BackupPayload) -> Bool {
        let productIDs = payload.products.map(\.id)
        let saleIDs = payload.sales.map(\.id)
        let items = payload.sales.flatMap(\.items)
        let itemIDs = items.map(\.id)

        guard
            Set(productIDs).count == productIDs.count,
            Set(saleIDs).count == saleIDs.count,
            Set(itemIDs).count == itemIDs.count
        else { return false }

        return true
    }
}
