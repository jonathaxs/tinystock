// Proposito: Exportar, validar e restaurar o banco completo por backup JSON.
// Created by Jonathas Motta (@jonathaxs) on 2026-08-16.

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
    public static let currentVersion = 2

    // MARK: - Exportacao

    @MainActor
    public static func export(
        from context: ModelContext,
        selectedStoreID: UUID,
        exportedAt: Date = Date()
    ) throws -> Data {
        // Um contexto proprio evita incluir rascunhos ainda nao salvos pela interface.
        let snapshotContext = ModelContext(context.container)
        snapshotContext.autosaveEnabled = false
        let stores = try snapshotContext.fetch(FetchDescriptor<StoreProfile>()).sorted { $0.id.uuidString < $1.id.uuidString }
        let products = try snapshotContext.fetch(FetchDescriptor<Product>()).sorted { $0.id.uuidString < $1.id.uuidString }
        let variants = try snapshotContext.fetch(FetchDescriptor<ProductVariant>()).sorted { $0.id.uuidString < $1.id.uuidString }
        let movements = try snapshotContext.fetch(FetchDescriptor<StockMovement>()).sorted { $0.id.uuidString < $1.id.uuidString }
        let orders = try snapshotContext.fetch(FetchDescriptor<SalesOrder>()).sorted { $0.id.uuidString < $1.id.uuidString }
        let activeStores = stores.filter { !$0.isArchived }
        guard let selectedID = activeStores.first(where: { $0.id == selectedStoreID })?.id
            ?? activeStores.first?.id else { throw BackupError.invalidFile }

        let payload = BackupPayload(
            version: currentVersion,
            exportedAt: exportedAt,
            products: products.map(productSnapshot),
            sales: [],
            selectedStoreID: selectedID,
            stores: stores.map(storeSnapshot),
            variants: variants.map(variantSnapshot),
            stockMovements: movements.map(movementSnapshot),
            orders: orders.map(orderSnapshot)
        )
        guard isValidV2(payload) else { throw BackupError.invalidFile }
        return try encode(payload)
    }

    // MARK: - Decodificacao

    @MainActor
    public static func decode(_ data: Data) throws -> BackupPayload {
        let payload: BackupPayload
        do {
            payload = try decoder().decode(BackupPayload.self, from: data)
        } catch {
            throw BackupError.invalidFile
        }
        switch payload.version {
        case 1:
            guard isValidV1(payload) else { throw BackupError.invalidFile }
        case currentVersion:
            guard isValidV2(payload) else { throw BackupError.invalidFile }
        default:
            throw BackupError.unsupportedVersion(payload.version)
        }
        return payload
    }

    // MARK: - Restauracao

    @MainActor
    @discardableResult
    public static func apply(
        _ payload: BackupPayload,
        into context: ModelContext,
        storeID: UUID = StoreScope.unassignedStoreID
    ) throws -> BackupRestoreResult {
        try apply(payload, into: context, storeID: storeID, saving: { try $0.save() })
    }

    @MainActor
    static func apply(
        _ payload: BackupPayload,
        into context: ModelContext,
        storeID: UUID,
        saving: (ModelContext) throws -> Void
    ) throws -> BackupRestoreResult {
        switch payload.version {
        case 1 where isValidV1(payload):
            return try restoreV1(payload, into: context, storeID: storeID, saving: saving)
        case currentVersion where isValidV2(payload):
            return try restoreV2(payload, into: context, saving: saving)
        case 1, currentVersion:
            throw BackupError.invalidFile
        default:
            throw BackupError.unsupportedVersion(payload.version)
        }
    }

    @MainActor
    private static func restoreV2(
        _ payload: BackupPayload,
        into context: ModelContext,
        saving: (ModelContext) throws -> Void
    ) throws -> BackupRestoreResult {
        guard let selectedID = payload.selectedStoreID else { throw BackupError.invalidFile }
        try context.save()
        do {
            try context.transaction {
                try deleteAllData(in: context)
                for snapshot in payload.stores {
                    context.insert(StoreProfile(
                        id: snapshot.id, name: snapshot.name, imageData: snapshot.imageData,
                        isArchived: snapshot.isArchived, createdAt: snapshot.createdAt,
                        updatedAt: snapshot.updatedAt
                    ))
                }
                for snapshot in payload.products {
                    guard let storeID = snapshot.storeID else { throw BackupError.invalidFile }
                    context.insert(product(from: snapshot, storeID: storeID))
                }
                for snapshot in payload.variants {
                    context.insert(ProductVariant(
                        id: snapshot.id, storeID: snapshot.storeID, productID: snapshot.productID,
                        name: snapshot.name, quantity: snapshot.quantity,
                        createdAt: snapshot.createdAt, updatedAt: snapshot.updatedAt
                    ))
                }
                for snapshot in payload.stockMovements { context.insert(movement(from: snapshot)) }
                for snapshot in payload.orders { context.insert(order(from: snapshot)) }
                try saving(context)
            }
            return BackupRestoreResult(
                selectedStoreID: selectedID,
                migratedLegacyBackup: false,
                summary: payload.summary
            )
        } catch {
            context.rollback()
            throw error
        }
    }

    @MainActor
    private static func restoreV1(
        _ payload: BackupPayload,
        into context: ModelContext,
        storeID: UUID,
        saving: (ModelContext) throws -> Void
    ) throws -> BackupRestoreResult {
        let store = try context.fetch(FetchDescriptor<StoreProfile>(predicate: #Predicate {
            $0.id == storeID && !$0.isArchived
        })).first
        guard store != nil else { throw BackupError.invalidFile }
        try context.save()
        do {
            try context.transaction {
                try deleteStoreData(storeID: storeID, in: context)
                for snapshot in payload.products {
                    context.insert(product(from: snapshot, storeID: storeID))
                    let quantity = max(0, snapshot.quantity)
                    let variant = ProductVariant(
                        id: snapshot.id, storeID: storeID, productID: snapshot.id,
                        name: String(localized: "backup.legacy.variant.default", bundle: .tinyStockCore),
                        quantity: quantity, createdAt: snapshot.createdAt, updatedAt: snapshot.updatedAt
                    )
                    context.insert(variant)
                    if quantity > 0 {
                        context.insert(StockMovement(
                            storeID: storeID, productID: snapshot.id, variantID: variant.id,
                            kind: .initialStock, quantityDelta: quantity, balanceAfter: quantity,
                            createdAt: snapshot.createdAt
                        ))
                    }
                }
                for snapshot in payload.sales { context.insert(migratedOrder(from: snapshot, storeID: storeID)) }
                try saving(context)
            }
            return BackupRestoreResult(
                selectedStoreID: storeID,
                migratedLegacyBackup: true,
                summary: payload.summary
            )
        } catch {
            context.rollback()
            throw error
        }
    }

    // MARK: - Exclusao controlada

    @MainActor
    private static func deleteAllData(in context: ModelContext) throws {
        // Exclusoes individuais permanecem no transaction log e podem ser desfeitas.
        for value in try context.fetch(FetchDescriptor<SalesOrderItem>()) { context.delete(value) }
        for value in try context.fetch(FetchDescriptor<SalesOrder>()) { context.delete(value) }
        for value in try context.fetch(FetchDescriptor<SaleItem>()) { context.delete(value) }
        for value in try context.fetch(FetchDescriptor<Sale>()) { context.delete(value) }
        for value in try context.fetch(FetchDescriptor<StockMovement>()) { context.delete(value) }
        for value in try context.fetch(FetchDescriptor<ProductVariant>()) { context.delete(value) }
        for value in try context.fetch(FetchDescriptor<Product>()) { context.delete(value) }
        for value in try context.fetch(FetchDescriptor<StoreProfile>()) { context.delete(value) }
    }

    @MainActor
    private static func deleteStoreData(storeID: UUID, in context: ModelContext) throws {
        let orders = try context.fetch(FetchDescriptor<SalesOrder>(predicate: #Predicate { $0.storeID == storeID }))
        let sales = try context.fetch(FetchDescriptor<Sale>(predicate: #Predicate { $0.storeID == storeID }))
        let movements = try context.fetch(FetchDescriptor<StockMovement>(predicate: #Predicate { $0.storeID == storeID }))
        let variants = try context.fetch(FetchDescriptor<ProductVariant>(predicate: #Predicate { $0.storeID == storeID }))
        let products = try context.fetch(FetchDescriptor<Product>(predicate: #Predicate { $0.storeID == storeID }))
        for order in orders { context.delete(order) }
        for sale in sales { context.delete(sale) }
        for movement in movements { context.delete(movement) }
        for variant in variants { context.delete(variant) }
        for product in products { context.delete(product) }
    }

    // MARK: - Reconstrucao

    private static func product(from snapshot: BackupPayload.ProductSnapshot, storeID: UUID) -> Product {
        Product(
            id: snapshot.id, storeID: storeID, name: snapshot.name, category: snapshot.category,
            quantity: snapshot.quantity, minimumStock: snapshot.minimumStock,
            costPrice: snapshot.costPrice, salePrice: snapshot.salePrice,
            imageData: snapshot.imageData, createdAt: snapshot.createdAt, updatedAt: snapshot.updatedAt
        )
    }

    private static func movement(from snapshot: BackupPayload.StockMovementSnapshot) -> StockMovement {
        let movement = StockMovement(
            id: snapshot.id, storeID: snapshot.storeID, productID: snapshot.productID,
            variantID: snapshot.variantID,
            kind: StockMovementKind(rawValue: snapshot.kind) ?? .adjustment,
            quantityDelta: snapshot.quantityDelta, balanceAfter: snapshot.balanceAfter,
            note: snapshot.note, referenceID: snapshot.referenceID,
            reversedMovementID: snapshot.reversedMovementID, reversedAt: snapshot.reversedAt,
            createdAt: snapshot.createdAt
        )
        movement.kindRawValue = snapshot.kind
        return movement
    }

    private static func order(from snapshot: BackupPayload.SalesOrderSnapshot) -> SalesOrder {
        let order = SalesOrder(
            id: snapshot.id, storeID: snapshot.storeID,
            channel: SalesChannel(rawValue: snapshot.channel) ?? .direct,
            customChannelName: snapshot.customChannelName,
            fulfillment: OrderFulfillment(rawValue: snapshot.fulfillment) ?? .readyStock,
            status: SalesOrderStatus(rawValue: snapshot.status), buyerName: snapshot.buyerName,
            externalReference: snapshot.externalReference, orderedAt: snapshot.orderedAt,
            productionDueAt: snapshot.productionDueAt, shippingDueAt: snapshot.shippingDueAt,
            cancellationReason: snapshot.cancellationReason, trackingCode: snapshot.trackingCode,
            note: snapshot.note, channelFeePercentage: snapshot.channelFeePercentage,
            channelFeeAmount: snapshot.channelFeeAmount,
            createdAt: snapshot.createdAt, updatedAt: snapshot.updatedAt
        )
        order.channelRawValue = snapshot.channel
        order.fulfillmentRawValue = snapshot.fulfillment
        order.statusRawValue = snapshot.status
        order.productionStartedAt = snapshot.productionStartedAt
        order.producedAt = snapshot.producedAt
        order.shippedAt = snapshot.shippedAt
        order.completedAt = snapshot.completedAt
        order.cancelledAt = snapshot.cancelledAt
        order.items = snapshot.items.map { item in
            let restored = SalesOrderItem(
                id: item.id, storeID: item.storeID, productID: item.productID,
                variantID: item.variantID, productName: item.productName,
                variantName: item.variantName, unitPrice: item.unitPrice,
                unitCost: item.unitCost, quantity: item.quantity, position: item.position
            )
            restored.order = order
            return restored
        }
        return order
    }

    private static func migratedOrder(from snapshot: BackupPayload.SaleSnapshot, storeID: UUID) -> SalesOrder {
        let channel: SalesChannel = snapshot.paymentMethod == PaymentMethod.shopee.rawValue ? .shopee : .direct
        let order = SalesOrder(
            id: snapshot.id, storeID: storeID, channel: channel,
            fulfillment: .readyStock, status: .completed,
            orderedAt: snapshot.date, shippingDueAt: snapshot.date,
            note: snapshot.note, channelFeePercentage: snapshot.channelFeePercentage,
            channelFeeAmount: snapshot.channelFeeAmount,
            createdAt: snapshot.date, updatedAt: snapshot.date
        )
        order.shippedAt = snapshot.date
        order.completedAt = snapshot.date
        order.items = snapshot.items.enumerated().map { position, item in
            let restored = SalesOrderItem(
                id: item.id, storeID: storeID, productID: item.productID,
                variantID: item.productID, productName: item.productName,
                variantName: String(localized: "backup.legacy.variant.default", bundle: .tinyStockCore),
                unitPrice: item.unitPrice, unitCost: item.unitCost,
                quantity: item.quantity, position: position
            )
            restored.order = order
            return restored
        }
        return order
    }

    // MARK: - Snapshots

    private static func storeSnapshot(_ value: StoreProfile) -> BackupPayload.StoreSnapshot {
        .init(id: value.id, name: value.name, imageData: value.imageData,
              isArchived: value.isArchived, createdAt: value.createdAt, updatedAt: value.updatedAt)
    }

    private static func productSnapshot(_ value: Product) -> BackupPayload.ProductSnapshot {
        .init(id: value.id, name: value.name, category: value.category,
              quantity: value.quantity, minimumStock: value.minimumStock,
              costPrice: value.costPrice, salePrice: value.salePrice,
              imageData: value.imageData, createdAt: value.createdAt,
              updatedAt: value.updatedAt, storeID: value.storeID)
    }

    private static func variantSnapshot(_ value: ProductVariant) -> BackupPayload.ProductVariantSnapshot {
        .init(id: value.id, storeID: value.storeID, productID: value.productID,
              name: value.name, quantity: value.quantity,
              createdAt: value.createdAt, updatedAt: value.updatedAt)
    }

    private static func movementSnapshot(_ value: StockMovement) -> BackupPayload.StockMovementSnapshot {
        .init(id: value.id, storeID: value.storeID, productID: value.productID,
              variantID: value.variantID, kind: value.kindRawValue,
              quantityDelta: value.quantityDelta, balanceAfter: value.balanceAfter,
              note: value.note, referenceID: value.referenceID,
              reversedMovementID: value.reversedMovementID, reversedAt: value.reversedAt,
              createdAt: value.createdAt)
    }

    private static func orderSnapshot(_ value: SalesOrder) -> BackupPayload.SalesOrderSnapshot {
        .init(
            id: value.id, storeID: value.storeID, channel: value.channelRawValue,
            customChannelName: value.customChannelName, fulfillment: value.fulfillmentRawValue,
            status: value.statusRawValue, buyerName: value.buyerName,
            externalReference: value.externalReference, orderedAt: value.orderedAt,
            productionDueAt: value.productionDueAt, shippingDueAt: value.shippingDueAt,
            productionStartedAt: value.productionStartedAt, producedAt: value.producedAt,
            shippedAt: value.shippedAt, completedAt: value.completedAt,
            cancelledAt: value.cancelledAt, cancellationReason: value.cancellationReason,
            trackingCode: value.trackingCode, note: value.note,
            channelFeePercentage: value.channelFeePercentage,
            channelFeeAmount: value.channelFeeAmount, createdAt: value.createdAt,
            updatedAt: value.updatedAt,
            items: value.itemList.map {
                .init(id: $0.id, storeID: $0.storeID, productID: $0.productID,
                      variantID: $0.variantID, productName: $0.productName,
                      variantName: $0.variantName, unitPrice: $0.unitPrice,
                      unitCost: $0.unitCost, quantity: $0.quantity, position: $0.position)
            }
        )
    }

    // MARK: - Integridade

    private static func isValidV1(_ payload: BackupPayload) -> Bool {
        guard payload.version == 1, payload.stores.isEmpty, payload.variants.isEmpty,
              payload.stockMovements.isEmpty, payload.orders.isEmpty,
              payload.exportedAt.timeIntervalSinceReferenceDate.isFinite else { return false }
        let itemIDs = payload.sales.flatMap(\.items).map(\.id)
        return hasUniqueIDs(payload.products.map(\.id))
            && hasUniqueIDs(payload.sales.map(\.id))
            && hasUniqueIDs(itemIDs)
            && payload.products.allSatisfy { valid($0.createdAt, $0.updatedAt) && valid($0.costPrice, $0.salePrice) }
            && payload.sales.allSatisfy { sale in
                sale.date.timeIntervalSinceReferenceDate.isFinite
                    && valid(sale.channelFeePercentage, sale.channelFeeAmount)
                    && sale.items.allSatisfy { $0.quantity > 0 && valid($0.unitPrice, $0.unitCost) }
            }
    }

    private static func isValidV2(_ payload: BackupPayload) -> Bool {
        guard payload.version == currentVersion, payload.sales.isEmpty,
              payload.exportedAt.timeIntervalSinceReferenceDate.isFinite,
              !payload.stores.isEmpty else { return false }
        let storeIDs = Set(payload.stores.map(\.id))
        let activeIDs = Set(payload.stores.filter { !$0.isArchived }.map(\.id))
        guard hasUniqueIDs(payload.stores.map(\.id)), !activeIDs.isEmpty,
              let selectedStoreID = payload.selectedStoreID,
              activeIDs.contains(selectedStoreID),
              !storeIDs.contains(StoreScope.unassignedStoreID),
              payload.stores.allSatisfy({ valid($0.createdAt, $0.updatedAt) }) else { return false }

        guard hasUniqueIDs(payload.products.map(\.id)) else { return false }
        let productsByID = Dictionary(uniqueKeysWithValues: payload.products.map { ($0.id, $0) })
        guard
              payload.products.allSatisfy({ snapshot in
                  guard let storeID = snapshot.storeID else { return false }
                  return storeIDs.contains(storeID)
                      && valid(snapshot.createdAt, snapshot.updatedAt)
                      && valid(snapshot.costPrice, snapshot.salePrice)
              }) else { return false }

        guard hasUniqueIDs(payload.variants.map(\.id)) else { return false }
        let variantsByID = Dictionary(uniqueKeysWithValues: payload.variants.map { ($0.id, $0) })
        guard
              payload.variants.allSatisfy({ snapshot in
                  snapshot.quantity >= 0
                      && productsByID[snapshot.productID]?.storeID == snapshot.storeID
                      && valid(snapshot.createdAt, snapshot.updatedAt)
              }) else { return false }

        let movementIDs = Set(payload.stockMovements.map(\.id))
        guard movementIDs.count == payload.stockMovements.count,
              payload.stockMovements.allSatisfy({ snapshot in
                  productsByID[snapshot.productID]?.storeID == snapshot.storeID
                      && variantsByID[snapshot.variantID]?.productID == snapshot.productID
                      && variantsByID[snapshot.variantID]?.storeID == snapshot.storeID
                      && snapshot.createdAt.timeIntervalSinceReferenceDate.isFinite
                      && snapshot.reversedAt?.timeIntervalSinceReferenceDate.isFinite != false
                      && snapshot.reversedMovementID.map { $0 != snapshot.id && movementIDs.contains($0) } != false
              }) else { return false }

        let itemIDs = payload.orders.flatMap(\.items).map(\.id)
        return hasUniqueIDs(payload.orders.map(\.id))
            && hasUniqueIDs(itemIDs)
            && payload.orders.allSatisfy { order in
                storeIDs.contains(order.storeID)
                    && validOrderDates(order)
                    && valid(order.channelFeePercentage, order.channelFeeAmount)
                    && order.items.allSatisfy {
                        $0.storeID == order.storeID && $0.quantity > 0 && valid($0.unitPrice, $0.unitCost)
                    }
            }
    }

    private static func validOrderDates(_ order: BackupPayload.SalesOrderSnapshot) -> Bool {
        let dates = [order.orderedAt, order.createdAt, order.updatedAt]
        let optionalDates = [order.productionDueAt, order.shippingDueAt, order.productionStartedAt,
                             order.producedAt, order.shippedAt, order.completedAt, order.cancelledAt]
        return dates.allSatisfy { $0.timeIntervalSinceReferenceDate.isFinite }
            && optionalDates.allSatisfy { $0?.timeIntervalSinceReferenceDate.isFinite != false }
    }

    private static func valid(_ values: Decimal...) -> Bool { values.allSatisfy { !$0.isNaN } }
    private static func valid(_ dates: Date...) -> Bool {
        dates.allSatisfy { $0.timeIntervalSinceReferenceDate.isFinite }
    }
    private static func hasUniqueIDs(_ values: [UUID]) -> Bool { Set(values).count == values.count }
    // MARK: - Formato do arquivo

    private static func encode(_ payload: BackupPayload) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(date.timeIntervalSince1970)
        }
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(payload)
    }

    private static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            if let seconds = try? container.decode(Double.self) {
                return Date(timeIntervalSince1970: seconds)
            }
            let value = try container.decode(String.self)
            let withFraction = ISO8601DateFormatter()
            withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = withFraction.date(from: value) { return date }
            let standard = ISO8601DateFormatter()
            guard let date = standard.date(from: value) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date")
            }
            return date
        }
        return decoder
    }

    public static func suggestedFilename(relativeTo date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return "tinystock-backup-\(formatter.string(from: date)).json"
    }
}
