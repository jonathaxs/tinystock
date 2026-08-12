// ⌘
//  TinyStockCore/Models/SaleItem.swift
//
//  Propósito: Item de uma venda, guardando o retrato do produto no momento em que ela aconteceu.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-11.
// ⌘

import Foundation
import SwiftData

// MARK: - Item da venda

/// Uma linha da venda: qual produto, quantos e por quanto.
///
/// De propósito NÃO tem relação com `Product`. O item guarda uma cópia do nome, do preço
/// e do custo do dia da venda. Assim, se o preço do amigurumi subir mês que vem ou o
/// produto for excluído, o histórico e o lucro já registrados continuam contando a verdade.
@Model
public final class SaleItem {

    public var id: UUID = UUID()

    /// Só o identificador do produto, usado pra somar "mais vendidos" nos relatórios.
    /// Não é uma relação, então excluir o produto não apaga a venda.
    public var productID: UUID = UUID()

    /// Nome do produto como estava no dia da venda.
    public var productName: String = ""

    /// Preço unitário cobrado nessa venda.
    public var unitPrice: Decimal = 0

    /// Custo unitário na data da venda, usado pra calcular o lucro real do período.
    public var unitCost: Decimal = 0

    public var quantity: Int = 0

    /// Venda dona deste item. Opcional porque o CloudKit exige relação opcional.
    public var sale: Sale?

    // MARK: - Inicializador

    public init(
        id: UUID = UUID(),
        productID: UUID = UUID(),
        productName: String = "",
        unitPrice: Decimal = 0,
        unitCost: Decimal = 0,
        quantity: Int = 0,
        sale: Sale? = nil
    ) {
        self.id = id
        self.productID = productID
        self.productName = productName
        self.unitPrice = unitPrice
        self.unitCost = unitCost
        self.quantity = quantity
        self.sale = sale
    }

    /// Cria o item já copiando os dados atuais do produto.
    ///
    /// É função estática, e não `convenience init`, de propósito: dentro de uma classe
    /// `@Model` o `self.init(...)` acaba resolvendo pro `init(backingData:)` que o macro
    /// gera, e o app quebra ao abrir o banco.
    public static func from(product: Product, quantity: Int) -> SaleItem {
        SaleItem(
            productID: product.id,
            productName: product.name,
            unitPrice: product.salePrice,
            unitCost: product.costPrice,
            quantity: quantity
        )
    }

    // MARK: - Derivados (não persistidos)

    /// Quanto essa linha somou na venda.
    public var subtotal: Decimal {
        unitPrice * Decimal(quantity)
    }

    /// Quanto essa linha custou pra produzir ou comprar.
    public var subtotalCost: Decimal {
        unitCost * Decimal(quantity)
    }

    /// Lucro da linha.
    public var profit: Decimal {
        subtotal - subtotalCost
    }
}
