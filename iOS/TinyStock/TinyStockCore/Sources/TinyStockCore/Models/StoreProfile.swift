// ⌘
//  TinyStockCore/Models/StoreProfile.swift
//
//  Propósito: Model SwiftData que representa uma loja e delimita seus dados no TinyStock.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-24.
// ⌘

import Foundation
import SwiftData

// MARK: - Escopo sem loja

/// Identificador reservado para objetos criados fora de uma loja, como fixtures antigas.
/// O app sempre informa uma loja real ao criar dados novos.
public enum StoreScope {
    public static let unassignedStoreID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
}

// MARK: - Loja

/// Uma loja independente dentro do TinyStock.
///
/// Produtos, pedidos e relatórios serão associados a este identificador nas próximas etapas.
/// Todas as propriedades possuem valor padrão para manter a compatibilidade com CloudKit.
@Model
public final class StoreProfile {

    /// Identificador estável usado nas relações, no backup e na seleção da loja atual.
    public var id: UUID = UUID()

    /// Nome escolhido pelo comerciante, como VHS Plus ou Minha loja.
    public var name: String = ""

    /// Logo ou foto opcional. O arquivo fica fora do banco principal.
    @Attribute(.externalStorage) public var imageData: Data?

    /// Lojas arquivadas preservam o histórico, mas não aparecem no uso cotidiano.
    public var isArchived: Bool = false

    public var createdAt: Date = Date()
    public var updatedAt: Date = Date()

    public init(
        id: UUID = UUID(),
        name: String = "",
        imageData: Data? = nil,
        isArchived: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.imageData = imageData
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
