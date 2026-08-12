// ⌘
//  TinyStockCore/Services/SaleService.swift
//
//  Propósito: Registrar uma venda validando o estoque e dando baixa nos produtos.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-11.
// ⌘

import Foundation
import SwiftData

// MARK: - Erros da venda

/// Motivos pelos quais uma venda não pode ser registrada.
public enum SaleError: Error, Equatable, Sendable {

    /// Nenhum item foi escolhido.
    case emptySale

    /// Quantidade zero ou negativa em algum item.
    case invalidQuantity(productName: String)

    /// Não há estoque suficiente. Carrega os números pra tela poder explicar direito.
    case insufficientStock(productName: String, available: Int, requested: Int)
}

// MARK: - Linha da venda em montagem

/// O que a tela monta antes de fechar a venda: um produto e quantas unidades.
///
/// Não é Sendable de propósito: carrega um `@Model`, que vive preso ao contexto
/// do SwiftData e não pode atravessar threads.
public struct SaleLine {

    public let product: Product
    public let quantity: Int

    public init(product: Product, quantity: Int) {
        self.product = product
        self.quantity = quantity
    }
}

// MARK: - Registro da venda

/// Concentra a regra mais importante do app: vender dá baixa no estoque,
/// e só dá pra vender o que existe.
public enum SaleService {

    /// Valida as linhas, cria a venda e desconta o estoque dos produtos.
    ///
    /// Ou tudo funciona, ou nada é alterado: as validações acontecem todas antes
    /// de qualquer escrita, então uma venda recusada não deixa estoque pela metade.
    ///
    /// - Throws: `SaleError` quando a venda está vazia, tem quantidade inválida ou falta estoque.
    @discardableResult
    public static func register(
        lines: [SaleLine],
        paymentMethod: PaymentMethod,
        date: Date = Date(),
        note: String = "",
        in context: ModelContext
    ) throws -> Sale {

        guard !lines.isEmpty else { throw SaleError.emptySale }

        // Quantidade tem que fazer sentido antes de qualquer conta.
        for line in lines where line.quantity <= 0 {
            throw SaleError.invalidQuantity(productName: line.product.name)
        }

        // O mesmo produto pode ter sido adicionado duas vezes na tela. Somar antes de
        // validar evita liberar uma venda de 3 + 3 unidades quando só existem 5 em estoque.
        let mergedLines = merge(lines)

        for line in mergedLines where line.quantity > line.product.quantity {
            throw SaleError.insufficientStock(
                productName: line.product.name,
                available: line.product.quantity,
                requested: line.quantity
            )
        }

        // Daqui pra baixo nada mais pode falhar, então já pode escrever.
        let sale = Sale(date: date, paymentMethod: paymentMethod, note: note)
        context.insert(sale)

        let now = Date()

        for line in mergedLines {
            let item = SaleItem.from(product: line.product, quantity: line.quantity)
            item.sale = sale
            context.insert(item)

            // A baixa de estoque em si.
            line.product.quantity -= line.quantity
            line.product.updatedAt = now
        }

        return sale
    }

    /// Junta linhas repetidas do mesmo produto numa só, somando as quantidades.
    /// Mantém a ordem em que os produtos apareceram, pra venda ficar igual ao que a pessoa montou.
    private static func merge(_ lines: [SaleLine]) -> [SaleLine] {
        var totals: [UUID: Int] = [:]
        var order: [UUID] = []
        var products: [UUID: Product] = [:]

        for line in lines {
            let id = line.product.id

            if totals[id] == nil {
                order.append(id)
                products[id] = line.product
            }

            totals[id, default: 0] += line.quantity
        }

        return order.compactMap { id in
            guard let product = products[id], let quantity = totals[id] else { return nil }
            return SaleLine(product: product, quantity: quantity)
        }
    }
}
