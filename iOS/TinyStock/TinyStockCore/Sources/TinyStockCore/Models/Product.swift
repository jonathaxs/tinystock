// ⌘
//  TinyStockCore/Models/Product.swift
//
//  Propósito: Model SwiftData que representa um produto no estoque, com custo, preço e alerta de estoque baixo.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-07.
// ⌘

import Foundation
import SwiftData

// MARK: - Modelo SwiftData

/// Product representa um item cadastrado no estoque do TinyStock.
/// Cada propriedade tem valor padrão, o que mantém o model compatível com uma
/// futura sincronização via CloudKit (que exige defaults ou opcionais).
@Model
public final class Product {

    /// Identificador estável usado no backup JSON e no snapshot da venda.
    /// Sem `.unique` de propósito, pra não quebrar o mirror do CloudKit no futuro.
    public var id: UUID = UUID()

    /// Nome do produto exibido nas listas.
    public var name: String = ""

    /// Categoria livre (ex.: "Crochê", "Impressão 3D"). Vazio significa sem categoria.
    public var category: String = ""

    /// Quantidade atual em estoque.
    public var quantity: Int = 0

    /// Estoque mínimo pro alerta de reposição. Zero desliga o alerta.
    public var minimumStock: Int = 0

    /// Custo unitário de produção ou compra. Decimal evita erro de ponto flutuante com dinheiro.
    public var costPrice: Decimal = 0

    /// Preço de venda unitário.
    public var salePrice: Decimal = 0

    /// Foto opcional do produto. Externa ao banco principal pra não pesar as consultas.
    @Attribute(.externalStorage) public var imageData: Data?

    /// Data de cadastro.
    public var createdAt: Date = Date()

    /// Data da última edição.
    public var updatedAt: Date = Date()

    // MARK: - Inicializador

    public init(
        id: UUID = UUID(),
        name: String = "",
        category: String = "",
        quantity: Int = 0,
        minimumStock: Int = 0,
        costPrice: Decimal = 0,
        salePrice: Decimal = 0,
        imageData: Data? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.quantity = quantity
        self.minimumStock = minimumStock
        self.costPrice = costPrice
        self.salePrice = salePrice
        self.imageData = imageData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Derivados (não persistidos)

    /// Indica se o estoque atingiu ou ficou abaixo do mínimo configurado.
    public var isLowStock: Bool {
        minimumStock > 0 && quantity <= minimumStock
    }

    /// Lucro unitário estimado (preço de venda menos custo).
    public var unitProfit: Decimal {
        salePrice - costPrice
    }

    /// Quanto o estoque parado ainda pode render, se tudo que existe hoje for vendido.
    public var potentialProfit: Decimal {
        unitProfit * Decimal(quantity)
    }
}
