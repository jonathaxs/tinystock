// ⌘
//  TinyStockCoreTests/ProductTests.swift
//
//  Propósito: Testes do model Product cobrindo o alerta de estoque baixo e o lucro unitário.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-07.
// ⌘

import Testing
import Foundation
import SwiftData
@testable import TinyStockCore

// MARK: - Testes do Product

@Test func lowStockLigaQuandoQuantidadeAtingeMinimo() {
    // Estoque igual ou abaixo do mínimo deve acender o alerta.
    let produto = Product(name: "Amigurumi", quantity: 3, minimumStock: 5)
    #expect(produto.isLowStock == true)
}

@Test func lowStockDesligaQuandoMinimoZero() {
    // Mínimo zero significa "sem alerta", mesmo com estoque zerado.
    let produto = Product(name: "Chaveiro 3D", quantity: 0, minimumStock: 0)
    #expect(produto.isLowStock == false)
}

@Test func lucroUnitarioEhPrecoMenosCusto() {
    let produto = Product(name: "Vaso 3D", costPrice: 8, salePrice: 25)
    #expect(produto.unitProfit == 17)
}

// MARK: - Persistência

@Test @MainActor func produtoSalvoPodeSerLidoDeVolta() throws {
    // Container em memória imita o que o formulário faz de verdade,
    // sem depender do banco no disco do aparelho.
    let container = try ModelContainer(
        for: Product.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext

    context.insert(
        Product(name: "Amigurumi Gato", category: "Crochê", quantity: 12, costPrice: 20, salePrice: 45)
    )

    let salvos = try context.fetch(FetchDescriptor<Product>())

    #expect(salvos.count == 1)
    #expect(salvos.first?.name == "Amigurumi Gato")
    #expect(salvos.first?.category == "Crochê")
    #expect(salvos.first?.quantity == 12)
    #expect(salvos.first?.unitProfit == 25)
}
