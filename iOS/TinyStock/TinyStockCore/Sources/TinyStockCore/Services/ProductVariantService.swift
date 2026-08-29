// ⌘
//  TinyStockCore/Services/ProductVariantService.swift
//
//  Propósito: Validar e consultar variações dentro do produto e da loja corretos.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-27.
// ⌘

import Foundation
import SwiftData

// MARK: - Erros

public enum ProductVariantError: Error, Equatable, Sendable {
    case emptyName
    case duplicateName
    case negativeQuantity
    case productMismatch
}

public extension ProductVariantError {

    var localizedMessage: String {
        switch self {
        case .emptyName:
            String(localized: "variant.error.emptyName", bundle: .tinyStockCore)
        case .duplicateName:
            String(localized: "variant.error.duplicateName", bundle: .tinyStockCore)
        case .negativeQuantity:
            String(localized: "variant.error.negativeQuantity", bundle: .tinyStockCore)
        case .productMismatch:
            String(localized: "variant.error.productMismatch", bundle: .tinyStockCore)
        }
    }
}

// MARK: - Serviço

public enum ProductVariantService {

    /// Cria uma variação já vinculada ao produto e à loja dele.
    @discardableResult
    public static func create(
        for product: Product,
        name: String,
        initialQuantity: Int = 0,
        date: Date = Date(),
        in context: ModelContext
    ) throws -> ProductVariant {
        guard initialQuantity >= 0 else { throw ProductVariantError.negativeQuantity }
        let cleanName = try validatedName(
            name,
            for: product,
            excluding: nil,
            in: context
        )

        let variant = ProductVariant(
            storeID: product.storeID,
            productID: product.id,
            name: cleanName,
            quantity: initialQuantity,
            createdAt: date,
            updatedAt: date
        )
        context.insert(variant)
        return variant
    }

    /// Renomeia sem alterar o saldo, que será responsabilidade do serviço de estoque.
    public static func rename(
        _ variant: ProductVariant,
        to name: String,
        for product: Product,
        date: Date = Date(),
        in context: ModelContext
    ) throws {
        guard variant.belongs(to: product) else {
            throw ProductVariantError.productMismatch
        }

        variant.name = try validatedName(
            name,
            for: product,
            excluding: variant.id,
            in: context
        )
        variant.updatedAt = date
    }

    /// Consulta usando produto e loja para impedir vazamento entre perfis.
    public static func variants(
        for product: Product,
        in context: ModelContext
    ) throws -> [ProductVariant] {
        let productID = product.id
        let storeID = product.storeID
        let descriptor = FetchDescriptor<ProductVariant>(
            predicate: #Predicate {
                $0.productID == productID && $0.storeID == storeID
            },
            sortBy: [SortDescriptor(\ProductVariant.name)]
        )
        return try context.fetch(descriptor)
    }

    public static func totalQuantity(
        for product: Product,
        in context: ModelContext
    ) throws -> Int {
        try variants(for: product, in: context).reduce(0) { $0 + $1.quantity }
    }

    // MARK: - Validação

    private static func validatedName(
        _ name: String,
        for product: Product,
        excluding variantID: UUID?,
        in context: ModelContext
    ) throws -> String {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { throw ProductVariantError.emptyName }

        let existing = try variants(for: product, in: context)
        let candidate = comparableName(cleanName)
        let isDuplicate = existing.contains {
            $0.id != variantID && comparableName($0.name) == candidate
        }
        guard !isDuplicate else { throw ProductVariantError.duplicateName }

        return cleanName
    }

    private static func comparableName(_ name: String) -> String {
        name.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: Locale(identifier: "pt_BR")
        )
        .lowercased()
    }
}
