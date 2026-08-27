// ⌘
//  TinyStockCore/Services/ProductService.swift
//
//  Propósito: Centralizar as regras do cadastro canônico de produtos.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-26.
// ⌘

import Foundation
import SwiftData

// MARK: - Erros

public enum ProductError: Error, Equatable, Sendable {
    case emptyName
    case duplicateName
    case negativeCostPrice
    case negativeSalePrice
}

public extension ProductError {

    var localizedMessage: String {
        switch self {
        case .emptyName:
            String(localized: "product.error.emptyName", bundle: .tinyStockCore)
        case .duplicateName:
            String(localized: "product.error.duplicateName", bundle: .tinyStockCore)
        case .negativeCostPrice:
            String(localized: "product.error.negativeCostPrice", bundle: .tinyStockCore)
        case .negativeSalePrice:
            String(localized: "product.error.negativeSalePrice", bundle: .tinyStockCore)
        }
    }
}

// MARK: - Serviço

public enum ProductService {

    /// Cria somente os dados que pertencem ao produto. Variações e estoque
    /// serão associados em serviços próprios nas próximas etapas.
    @discardableResult
    public static func create(
        storeID: UUID,
        name: String,
        costPrice: Decimal = 0,
        salePrice: Decimal = 0,
        imageData: Data? = nil,
        date: Date = Date(),
        in context: ModelContext
    ) throws -> Product {
        let cleanName = try validatedName(
            name,
            storeID: storeID,
            excluding: nil,
            in: context
        )
        try validatePrices(costPrice: costPrice, salePrice: salePrice)

        let product = Product(
            storeID: storeID,
            name: cleanName,
            costPrice: costPrice,
            salePrice: salePrice,
            imageData: imageData,
            createdAt: date,
            updatedAt: date
        )
        context.insert(product)
        return product
    }

    /// Edita os dados canônicos sem alterar a loja ou a data de criação.
    public static func update(
        _ product: Product,
        name: String,
        costPrice: Decimal,
        salePrice: Decimal,
        imageData: Data?,
        date: Date = Date(),
        in context: ModelContext
    ) throws {
        let cleanName = try validatedName(
            name,
            storeID: product.storeID,
            excluding: product.id,
            in: context
        )
        try validatePrices(costPrice: costPrice, salePrice: salePrice)

        product.name = cleanName
        product.costPrice = costPrice
        product.salePrice = salePrice
        product.imageData = imageData
        product.updatedAt = date
    }

    // MARK: - Validação

    private static func validatedName(
        _ name: String,
        storeID: UUID,
        excluding productID: UUID?,
        in context: ModelContext
    ) throws -> String {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { throw ProductError.emptyName }

        let descriptor = FetchDescriptor<Product>(
            predicate: #Predicate { $0.storeID == storeID }
        )
        let candidate = comparableName(cleanName)
        let isDuplicate = try context.fetch(descriptor).contains {
            $0.id != productID && comparableName($0.name) == candidate
        }

        guard !isDuplicate else { throw ProductError.duplicateName }
        return cleanName
    }

    private static func validatePrices(
        costPrice: Decimal,
        salePrice: Decimal
    ) throws {
        guard costPrice >= 0 else { throw ProductError.negativeCostPrice }
        guard salePrice >= 0 else { throw ProductError.negativeSalePrice }
    }

    /// Compara como uma pessoa espera ao cadastrar nomes: sem diferença por
    /// maiúsculas, minúsculas ou acentos.
    private static func comparableName(_ name: String) -> String {
        name.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: Locale(identifier: "pt_BR")
        )
        .lowercased()
    }
}
