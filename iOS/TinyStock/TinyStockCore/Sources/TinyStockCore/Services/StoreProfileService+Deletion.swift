// Proposito: Excluir uma loja e todos os dados associados com validacao previa.
// Created by Jonathas Motta (@jonathaxs) on 2026-09-11.

import Foundation
import SwiftData

public struct StoreDeletionSummary: Equatable, Sendable {
    public let productCount: Int
    public let variantCount: Int
    public let stockMovementCount: Int
    public let orderCount: Int

    public init(
        productCount: Int,
        variantCount: Int,
        stockMovementCount: Int,
        orderCount: Int
    ) {
        self.productCount = productCount
        self.variantCount = variantCount
        self.stockMovementCount = stockMovementCount
        self.orderCount = orderCount
    }
}

public extension StoreProfileService {

    /// Calcula o impacto antes de apresentar a confirmacao ao usuario.
    @MainActor
    static func deletionSummary(
        for store: StoreProfile,
        in context: ModelContext
    ) throws -> StoreDeletionSummary {
        try validateDeletion(of: store, in: context)
        let storeID = store.id

        let products = try context.fetchCount(
            FetchDescriptor<Product>(predicate: #Predicate { $0.storeID == storeID })
        )
        let variants = try context.fetchCount(
            FetchDescriptor<ProductVariant>(predicate: #Predicate { $0.storeID == storeID })
        )
        let movements = try context.fetchCount(
            FetchDescriptor<StockMovement>(predicate: #Predicate { $0.storeID == storeID })
        )
        let orders = try context.fetchCount(
            FetchDescriptor<SalesOrder>(predicate: #Predicate { $0.storeID == storeID })
        )
        let legacySales = try context.fetchCount(
            FetchDescriptor<Sale>(predicate: #Predicate { $0.storeID == storeID })
        )

        return StoreDeletionSummary(
            productCount: products,
            variantCount: variants,
            stockMovementCount: movements,
            orderCount: orders + legacySales
        )
    }

    /// Exclui o escopo completo. O chamador salva ou desfaz o contexto ao terminar.
    @MainActor
    @discardableResult
    static func deletePermanently(
        _ store: StoreProfile,
        date: Date = Date(),
        in context: ModelContext
    ) throws -> StoreProfile? {
        let stores = try context.fetch(FetchDescriptor<StoreProfile>())
        let remainingActiveStores = orderedForDisplay(
            stores.filter { $0.id != store.id && !$0.isArchived }
        )
        guard store.isArchived || !remainingActiveStores.isEmpty else {
            throw StoreProfileError.lastActiveStore
        }

        let deletedStoreID = store.id
        try deleteData(storeID: deletedStoreID, in: context)
        context.delete(store)

        // A identidade inicial precisa continuar existindo para a reconciliacao entre dispositivos.
        if deletedStoreID == StoreScope.primaryStoreID,
           let replacement = remainingActiveStores.first {
            let previousID = replacement.id
            try remapStoreScope(from: previousID, to: StoreScope.primaryStoreID, in: context)
            replacement.id = StoreScope.primaryStoreID
            replacement.updatedAt = date
        }

        try setDisplayOrder(remainingActiveStores, date: date)
        return remainingActiveStores.first
    }

    @MainActor
    private static func validateDeletion(
        of store: StoreProfile,
        in context: ModelContext
    ) throws {
        guard !store.isArchived else { return }
        let storeID = store.id
        let remainingActiveCount = try context.fetchCount(
            FetchDescriptor<StoreProfile>(predicate: #Predicate {
                !$0.isArchived && $0.id != storeID
            })
        )
        guard remainingActiveCount > 0 else { throw StoreProfileError.lastActiveStore }
    }

    @MainActor
    private static func deleteData(storeID: UUID, in context: ModelContext) throws {
        let orderItems = try context.fetch(
            FetchDescriptor<SalesOrderItem>(predicate: #Predicate { $0.storeID == storeID })
        )
        let orders = try context.fetch(
            FetchDescriptor<SalesOrder>(predicate: #Predicate { $0.storeID == storeID })
        )
        let legacySales = try context.fetch(
            FetchDescriptor<Sale>(predicate: #Predicate { $0.storeID == storeID })
        )
        let movements = try context.fetch(
            FetchDescriptor<StockMovement>(predicate: #Predicate { $0.storeID == storeID })
        )
        let variants = try context.fetch(
            FetchDescriptor<ProductVariant>(predicate: #Predicate { $0.storeID == storeID })
        )
        let products = try context.fetch(
            FetchDescriptor<Product>(predicate: #Predicate { $0.storeID == storeID })
        )

        for item in orderItems { context.delete(item) }
        for order in orders { context.delete(order) }
        for sale in legacySales { context.delete(sale) }
        for movement in movements { context.delete(movement) }
        for variant in variants { context.delete(variant) }
        for product in products { context.delete(product) }
    }
}
