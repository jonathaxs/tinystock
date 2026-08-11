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

@Test func lowStockDesligaQuandoEstoqueEstaAcimaDoMinimo() {
    let produto = Product(name: "Tapete Redondo", quantity: 10, minimumStock: 3)
    #expect(produto.isLowStock == false)
}

@Test func lowStockLigaComEstoqueZeradoEMinimoDefinido() {
    // Estoque acabou de vez, que é justamente quando o alerta mais importa.
    let produto = Product(name: "Vaso 3D", quantity: 0, minimumStock: 2)
    #expect(produto.isLowStock == true)
}

// MARK: - Busca

@Test func buscaVaziaDevolveTodosOsProdutos() {
    let produto = Product(name: "Amigurumi Gato", category: "Crochê")
    #expect(produto.matches(searchText: "") == true)
    #expect(produto.matches(searchText: "   ") == true)
}

@Test func buscaEncontraPorPedacoDoNome() {
    let produto = Product(name: "Amigurumi Gato", category: "Crochê")
    #expect(produto.matches(searchText: "gato") == true)
}

@Test func buscaIgnoraAcentoEMaiuscula() {
    // O comerciante digita rápido e sem acento, e a busca tem que achar do mesmo jeito.
    let produto = Product(name: "Amigurumi Gato", category: "Crochê")
    #expect(produto.matches(searchText: "CROCHE") == true)
}

@Test func buscaEncontraPelaCategoria() {
    let produto = Product(name: "Suporte de Fone", category: "Impressão 3D")
    #expect(produto.matches(searchText: "impressao") == true)
}

@Test func buscaNaoEncontraOQueNaoExiste() {
    let produto = Product(name: "Amigurumi Gato", category: "Crochê")
    #expect(produto.matches(searchText: "caneca") == false)
}

// MARK: - Lucro

@Test func lucroPotencialMultiplicaOLucroPelaQuantidade() {
    let produto = Product(name: "Suporte de Fone", quantity: 4, costPrice: 10, salePrice: 25)
    #expect(produto.potentialProfit == 60)
}

@Test func lucroPotencialEhZeroComEstoqueVazio() {
    let produto = Product(name: "Tapete Redondo", quantity: 0, costPrice: 30, salePrice: 90)
    #expect(produto.potentialProfit == 0)
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

@Test @MainActor func edicaoAlteraOsCamposEPreservaACriacao() throws {
    let container = try ModelContainer(
        for: Product.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext

    let criadoEm = Date(timeIntervalSince1970: 1_700_000_000)
    let produto = Product(name: "Suporte de Fone", quantity: 2, salePrice: 25, createdAt: criadoEm, updatedAt: criadoEm)
    context.insert(produto)

    // Mesma operação que o formulário faz ao salvar uma edição.
    produto.name = "Suporte de Fone V2"
    produto.quantity = 10
    produto.salePrice = 30
    produto.updatedAt = Date()

    let salvos = try context.fetch(FetchDescriptor<Product>())

    #expect(salvos.count == 1, "editar não pode criar um segundo registro")
    #expect(salvos.first?.name == "Suporte de Fone V2")
    #expect(salvos.first?.quantity == 10)
    #expect(salvos.first?.createdAt == criadoEm, "a data de cadastro original tem que sobreviver")
    #expect(salvos.first?.updatedAt != criadoEm)
}

@Test @MainActor func exclusaoTiraOProdutoDoEstoque() throws {
    let container = try ModelContainer(
        for: Product.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext

    let amigurumi = Product(name: "Amigurumi Gato", quantity: 12)
    let tapete = Product(name: "Tapete Redondo", quantity: 8)
    context.insert(amigurumi)
    context.insert(tapete)

    context.delete(amigurumi)

    let restantes = try context.fetch(FetchDescriptor<Product>())

    #expect(restantes.count == 1)
    #expect(restantes.first?.name == "Tapete Redondo")
}
