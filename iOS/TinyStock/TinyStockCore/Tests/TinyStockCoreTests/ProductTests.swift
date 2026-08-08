// ⌘
//  TinyStockCoreTests/ProductTests.swift
//
//  Propósito: Testes do model Product cobrindo o alerta de estoque baixo e o lucro unitário.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-07.
// ⌘

import Testing
import Foundation
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
