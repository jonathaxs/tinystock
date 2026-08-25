// ⌘
//  TinyStockCoreTests/BackupManagerTests.swift
//
//  Propósito: Garantir a integridade da exportação e restauração do backup JSON.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-16.
// ⌘

import Testing
import Foundation
import SwiftData
@testable import TinyStockCore

@Suite(.serialized)
@MainActor
struct BackupManagerTests {
    let reference = Date(timeIntervalSince1970: 1_786_838_400)

    func makeContext() throws -> ModelContext {
        try TestDatabase.makeCleanContext()
    }

    @Test func exportacaoPreservaProdutosFotosVendasEItens() throws {
        let context = try makeContext()
        let imageData = Data([0x01, 0x02, 0x03])
        let product = Product(
            name: "Amigurumi Gato",
            category: "Crochê",
            quantity: 8,
            minimumStock: 3,
            costPrice: 20,
            salePrice: 45,
            imageData: imageData,
            createdAt: reference,
            updatedAt: reference
        )
        context.insert(product)
        let sale = try SaleService.register(
            lines: [SaleLine(product: product, quantity: 2)],
            paymentMethod: .shopee,
            date: reference,
            note: "Pedido 123",
            channelFeePercentage: 14,
            in: context
        )

        let data = try BackupManager.export(products: [product], sales: [sale], exportedAt: reference)
        let payload = try BackupManager.decode(data)
        let productSnapshot = try #require(payload.products.first)
        let saleSnapshot = try #require(payload.sales.first)
        let itemSnapshot = try #require(saleSnapshot.items.first)

        #expect(payload.version == 1)
        #expect(payload.exportedAt == reference)
        #expect(productSnapshot.id == product.id)
        #expect(productSnapshot.imageData == imageData)
        #expect(productSnapshot.quantity == 6)
        #expect(saleSnapshot.id == sale.id)
        #expect(saleSnapshot.paymentMethod == PaymentMethod.shopee.rawValue)
        #expect(saleSnapshot.note == "Pedido 123")
        #expect(saleSnapshot.channelFeePercentage == 14)
        #expect(saleSnapshot.channelFeeAmount == Decimal(string: "12.60"))
        #expect(itemSnapshot.productID == product.id)
        #expect(itemSnapshot.quantity == 2)
        #expect(itemSnapshot.unitPrice == 45)
        #expect(itemSnapshot.unitCost == 20)

        try BackupManager.apply(payload, into: context)

        let restoredProduct = try #require(context.fetch(FetchDescriptor<Product>()).first)
        let restoredSale = try #require(context.fetch(FetchDescriptor<Sale>()).first)
        #expect(restoredProduct.imageData == imageData)
        #expect(restoredProduct.quantity == 6)
        #expect(restoredSale.paymentMethod == .shopee)
        #expect(restoredSale.total == 90)
        #expect(restoredSale.channelFeePercentage == 14)
        #expect(restoredSale.channelFeeAmount == Decimal(string: "12.60"))
        #expect(restoredSale.netProfit == Decimal(string: "37.40"))
    }

    @Test func restauracaoSubstituiOBancoERefazRelacionamentos() throws {
        let context = try makeContext()
        context.insert(Product(name: "Produto antigo", quantity: 1))
        try context.save()

        let productID = UUID()
        let payload = BackupPayload(
            version: 1,
            exportedAt: reference,
            products: [
                .init(
                    id: productID,
                    name: "Vaso 3D",
                    category: "Impressão 3D",
                    quantity: 4,
                    minimumStock: 2,
                    costPrice: 8,
                    salePrice: 25,
                    imageData: nil,
                    createdAt: reference,
                    updatedAt: reference
                )
            ],
            sales: [
                .init(
                    id: UUID(),
                    date: reference,
                    paymentMethod: PaymentMethod.pix.rawValue,
                    note: "",
                    items: [
                        .init(
                            id: UUID(),
                            productID: productID,
                            productName: "Vaso 3D",
                            unitPrice: 25,
                            unitCost: 8,
                            quantity: 2
                        )
                    ]
                )
            ]
        )

        try BackupManager.apply(payload, into: context)

        let products = try context.fetch(FetchDescriptor<Product>())
        let sales = try context.fetch(FetchDescriptor<Sale>())
        let restoredSale = try #require(sales.first)

        #expect(products.map(\.name) == ["Vaso 3D"])
        #expect(restoredSale.itemList.count == 1)
        #expect(restoredSale.total == 50)
        #expect(restoredSale.profit == 34)
        #expect(restoredSale.itemList.first?.sale?.id == restoredSale.id)
    }

    @Test func restauracaoDeUmaLojaPreservaAsDemais() throws {
        let context = try makeContext()
        let firstStoreID = UUID()
        let secondStoreID = UUID()
        context.insert(Product(storeID: firstStoreID, name: "Produto antigo", quantity: 1))
        context.insert(Product(storeID: secondStoreID, name: "Produto da outra loja", quantity: 3))

        let payload = BackupPayload(
            version: 1,
            exportedAt: reference,
            products: [
                .init(
                    id: UUID(),
                    name: "Produto restaurado",
                    category: "",
                    quantity: 4,
                    minimumStock: 0,
                    costPrice: 10,
                    salePrice: 20,
                    imageData: nil,
                    createdAt: reference,
                    updatedAt: reference
                )
            ],
            sales: []
        )

        try BackupManager.apply(payload, into: context, storeID: firstStoreID)

        let products = try context.fetch(FetchDescriptor<Product>())
        let firstStoreProducts = products.filter { $0.storeID == firstStoreID }
        let secondStoreProducts = products.filter { $0.storeID == secondStoreID }

        #expect(firstStoreProducts.map(\.name) == ["Produto restaurado"])
        #expect(secondStoreProducts.map(\.name) == ["Produto da outra loja"])
    }

    @Test func versaoDesconhecidaEhRecusadaSemApagarOBanco() throws {
        let context = try makeContext()
        context.insert(Product(name: "Produto atual", quantity: 3))
        try context.save()
        let payload = BackupPayload(version: 99, exportedAt: reference, products: [], sales: [])

        #expect(throws: BackupError.unsupportedVersion(99)) {
            try BackupManager.apply(payload, into: context)
        }
        #expect(try context.fetch(FetchDescriptor<Product>()).map(\.name) == ["Produto atual"])
    }

    @Test func jsonInvalidoEhRecusado() {
        #expect(throws: BackupError.invalidFile) {
            try BackupManager.decode(Data("nao e json".utf8))
        }
    }

    @Test func identificadorDeProdutoDuplicadoEhRecusado() throws {
        let productID = UUID()
        let product = BackupPayload.ProductSnapshot(
            id: productID,
            name: "Produto",
            category: "",
            quantity: 0,
            minimumStock: 0,
            costPrice: 0,
            salePrice: 0,
            imageData: nil,
            createdAt: reference,
            updatedAt: reference
        )
        let payload = BackupPayload(
            version: 1,
            exportedAt: reference,
            products: [product, product],
            sales: []
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(payload)

        #expect(throws: BackupError.invalidFile) {
            try BackupManager.decode(data)
        }
    }

    @Test func vendaVaziaEValoresIncomunsSaoPreservados() throws {
        let context = try makeContext()
        let payload = BackupPayload(
            version: 1,
            exportedAt: reference,
            products: [
                .init(
                    id: UUID(),
                    name: "Produto antigo",
                    category: "",
                    quantity: -1,
                    minimumStock: 0,
                    costPrice: -5,
                    salePrice: 0,
                    imageData: nil,
                    createdAt: reference,
                    updatedAt: reference
                )
            ],
            sales: [
                .init(id: UUID(), date: reference, paymentMethod: "legacy", note: "", items: [])
            ]
        )

        try BackupManager.apply(payload, into: context)

        #expect(try context.fetch(FetchDescriptor<Product>()).first?.quantity == -1)
        #expect(try context.fetch(FetchDescriptor<Sale>()).first?.paymentMethodRawValue == "legacy")
    }

    @Test func backupAnteriorSemTaxaContinuaCompativel() throws {
        let saleID = UUID()
        let json = """
        {
          "version": 1,
          "exportedAt": "2026-08-16T00:00:00Z",
          "products": [],
          "sales": [
            {
              "id": "\(saleID.uuidString)",
              "date": "2026-08-16T00:00:00Z",
              "paymentMethod": "shopee",
              "note": "",
              "items": []
            }
          ]
        }
        """

        let payload = try BackupManager.decode(Data(json.utf8))
        let sale = try #require(payload.sales.first)

        #expect(sale.channelFeePercentage == 0)
        #expect(sale.channelFeeAmount == 0)
    }

    @Test func nomeSugeridoUsaDataEstavel() {
        #expect(BackupManager.suggestedFilename(relativeTo: reference) == "tinystock-backup-2026-08-16.json")
    }

    @Test func todoErroTemMensagemLocalizada() {
        #expect(BackupError.invalidFile.localizedDescription.isEmpty == false)
        #expect(BackupError.unsupportedVersion(2).localizedDescription.isEmpty == false)
    }
}
