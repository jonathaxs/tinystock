// ⌘
//  TinyStockCore/Services/StoreProfileService.swift
//
//  Propósito: Centralizar criação, edição e arquivamento seguro das lojas.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-24.
// ⌘

import Foundation
import SwiftData

// MARK: - Erros

public enum StoreProfileError: Error, Equatable, Sendable {
    case emptyName
    case duplicateName
    case lastActiveStore
    case archivedStore
}

public extension StoreProfileError {

    var localizedMessage: String {
        switch self {
        case .emptyName:
            String(localized: "store.error.emptyName", bundle: .tinyStockCore)
        case .duplicateName:
            String(localized: "store.error.duplicateName", bundle: .tinyStockCore)
        case .lastActiveStore:
            String(localized: "store.error.lastActiveStore", bundle: .tinyStockCore)
        case .archivedStore:
            String(localized: "store.error.archivedStore", bundle: .tinyStockCore)
        }
    }
}

// MARK: - Serviço

public enum StoreProfileService {

    /// Nome usado na primeira execução. O valor fica salvo e depois pode ser editado.
    public static var localizedDefaultName: String {
        String(localized: "store.default.name", bundle: .tinyStockCore)
    }

    /// Cria uma loja depois de normalizar e validar o nome.
    @discardableResult
    public static func create(
        name: String,
        imageData: Data? = nil,
        in context: ModelContext
    ) throws -> StoreProfile {
        let cleanName = sanitized(name)
        guard !cleanName.isEmpty else { throw StoreProfileError.emptyName }
        guard try !contains(name: cleanName, in: context) else {
            throw StoreProfileError.duplicateName
        }

        let store = StoreProfile(name: cleanName, imageData: imageData)
        context.insert(store)
        return store
    }

    /// Devolve uma loja ativa existente ou cria a loja inicial uma única vez.
    @discardableResult
    public static func ensureDefaultStore(
        name: String? = nil,
        in context: ModelContext
    ) throws -> StoreProfile {
        let descriptor = FetchDescriptor<StoreProfile>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\StoreProfile.createdAt)]
        )

        if let existing = try context.fetch(descriptor).first {
            return existing
        }

        // Um backup inconsistente pode chegar só com lojas arquivadas. Reativar a mais
        // antiga preserva os dados e evita criar outra loja com o mesmo nome.
        var archivedDescriptor = FetchDescriptor<StoreProfile>(
            predicate: #Predicate { $0.isArchived },
            sortBy: [SortDescriptor(\StoreProfile.createdAt)]
        )
        archivedDescriptor.fetchLimit = 1

        if let archived = try context.fetch(archivedDescriptor).first {
            archived.isArchived = false
            archived.updatedAt = Date()
            return archived
        }

        return try create(name: name ?? localizedDefaultName, in: context)
    }

    /// Atualiza os dados sem alterar a data original de criação.
    public static func update(
        _ store: StoreProfile,
        name: String,
        imageData: Data?,
        date: Date = Date(),
        in context: ModelContext
    ) throws {
        let cleanName = sanitized(name)
        guard !cleanName.isEmpty else { throw StoreProfileError.emptyName }
        guard try !contains(name: cleanName, excluding: store.id, in: context) else {
            throw StoreProfileError.duplicateName
        }

        store.name = cleanName
        store.imageData = imageData
        store.updatedAt = date
    }

    /// Arquiva sem apagar o histórico. A última loja ativa precisa permanecer disponível.
    public static func archive(
        _ store: StoreProfile,
        date: Date = Date(),
        in context: ModelContext
    ) throws {
        guard !store.isArchived else { return }

        let activeStores = try context.fetch(
            FetchDescriptor<StoreProfile>(predicate: #Predicate { !$0.isArchived })
        )
        guard activeStores.count > 1 else { throw StoreProfileError.lastActiveStore }

        store.isArchived = true
        store.updatedAt = date
    }

    /// Traz uma loja arquivada de volta sem alterar seus produtos ou histórico.
    public static func restore(
        _ store: StoreProfile,
        date: Date = Date()
    ) {
        guard store.isArchived else { return }

        store.isArchived = false
        store.updatedAt = date
    }

    // MARK: - Apoio

    private static func sanitized(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func contains(
        name: String,
        excluding storeID: UUID? = nil,
        in context: ModelContext
    ) throws -> Bool {
        let candidate = comparableName(name)

        return try context.fetch(FetchDescriptor<StoreProfile>()).contains {
            $0.id != storeID && comparableName($0.name) == candidate
        }
    }

    /// Evita duplicatas que diferem somente por maiúsculas ou acentos.
    private static func comparableName(_ name: String) -> String {
        sanitized(name)
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: Locale(identifier: "pt_BR")
            )
            .lowercased()
    }
}
