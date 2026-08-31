// TinyStockCore/Sources/TinyStockCore/Services/ProductFormService.swift
//
// Proposito: Validar e aplicar produto e variacoes como um unico cadastro.
//
// Created by Jonathas Motta (@jonathaxs) on 2026-08-30.

import Foundation
import SwiftData

/// Valores de uma variacao no formulario, sem modificar o banco durante a edicao.
public struct ProductVariantInput: Identifiable, Sendable {
    public let id: UUID
    public let existingID: UUID?
    public var name: String
    public var initialQuantity: Int

    public init(id: UUID = UUID(), existingID: UUID? = nil, name: String = "", initialQuantity: Int = 0) {
        self.id = id
        self.existingID = existingID
        self.name = name
        self.initialQuantity = initialQuantity
    }
}

/// Coordena o cadastro completo. O chamador salva o contexto ou desfaz em caso de erro.
public enum ProductFormService {
    @discardableResult
    public static func apply(
        to product: Product? = nil,
        storeID: UUID,
        name: String,
        costPrice: Decimal,
        salePrice: Decimal,
        imageData: Data?,
        variants: [ProductVariantInput],
        in context: ModelContext
    ) throws -> Product {
        if let product, product.storeID != storeID {
            throw ProductVariantError.productMismatch
        }

        // Valida toda a lista antes de alterar produto, nomes ou saldos.
        let existing = try product.map { try ProductVariantService.variants(for: $0, in: context) } ?? []
        try ProductVariantService.validateEdits(variants, existing: existing)

        let savedProduct: Product
        if let product {
            try ProductService.update(product, name: name, costPrice: costPrice,
                                      salePrice: salePrice, imageData: imageData, in: context)
            savedProduct = product
        } else {
            savedProduct = try ProductService.create(storeID: storeID, name: name, costPrice: costPrice,
                                                     salePrice: salePrice, imageData: imageData, in: context)
        }

        try ProductVariantService.applyEdits(variants, existing: existing, for: savedProduct, in: context)
        return savedProduct
    }
}
