// ⌘
//  TinyStockCore/Services/StoreSession.swift
//
//  Propósito: Manter e persistir a loja selecionada em um único estado observável.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-25.
// ⌘

import Foundation
import Observation
import SwiftData

// MARK: - Sessão da loja

/// Estado compartilhado pelas abas para que todas consultem a mesma loja.
@MainActor
@Observable
public final class StoreSession {

    public static let selectedStoreKey = "app.selectedStoreID"

    public private(set) var selectedStoreID: UUID

    @ObservationIgnored
    private let defaults: UserDefaults

    public init(
        selectedStoreID: UUID,
        defaults: UserDefaults = .standard
    ) {
        self.selectedStoreID = selectedStoreID
        self.defaults = defaults
        persistSelection()
    }

    /// Cria a loja inicial quando necessário e recupera uma seleção ainda válida.
    public static func bootstrap(
        in context: ModelContext,
        defaults: UserDefaults = .standard
    ) throws -> StoreSession {
        let defaultStore = try StoreProfileService.ensureDefaultStore(in: context)
        let activeStores = try context.fetch(
            FetchDescriptor<StoreProfile>(predicate: #Predicate { !$0.isArchived })
        )

        let storedID = defaults.string(forKey: selectedStoreKey).flatMap(UUID.init(uuidString:))
        let selectedStore = activeStores.first { $0.id == storedID } ?? defaultStore

        return StoreSession(selectedStoreID: selectedStore.id, defaults: defaults)
    }

    /// Troca a seleção somente para uma loja ativa.
    public func select(_ store: StoreProfile) throws {
        guard !store.isArchived else { throw StoreProfileError.archivedStore }

        selectedStoreID = store.id
        persistSelection()
    }

    private func persistSelection() {
        defaults.set(selectedStoreID.uuidString, forKey: Self.selectedStoreKey)
    }
}
