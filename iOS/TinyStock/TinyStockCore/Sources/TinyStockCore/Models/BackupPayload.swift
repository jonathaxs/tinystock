// ⌘
//  TinyStockCore/Models/BackupPayload.swift
//
//  Propósito: Representar todos os dados persistidos do app num arquivo JSON versionado.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-16.
// ⌘

import Foundation

// MARK: - Conteúdo completo do backup

public struct BackupPayload: Codable, Equatable, Sendable {
    public let version: Int
    public let exportedAt: Date
    public let products: [ProductSnapshot]
    public let sales: [SaleSnapshot]

    public init(
        version: Int,
        exportedAt: Date,
        products: [ProductSnapshot],
        sales: [SaleSnapshot]
    ) {
        self.version = version
        self.exportedAt = exportedAt
        self.products = products
        self.sales = sales
    }

    public struct ProductSnapshot: Codable, Equatable, Sendable {
        public let id: UUID
        public let name: String
        public let category: String
        public let quantity: Int
        public let minimumStock: Int
        public let costPrice: Decimal
        public let salePrice: Decimal
        public let imageData: Data?
        public let createdAt: Date
        public let updatedAt: Date

        public init(
            id: UUID,
            name: String,
            category: String,
            quantity: Int,
            minimumStock: Int,
            costPrice: Decimal,
            salePrice: Decimal,
            imageData: Data?,
            createdAt: Date,
            updatedAt: Date
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
    }

    public struct SaleSnapshot: Codable, Equatable, Sendable {
        public let id: UUID
        public let date: Date
        public let paymentMethod: String
        public let note: String
        public let channelFeePercentage: Decimal
        public let channelFeeAmount: Decimal
        public let items: [SaleItemSnapshot]

        public init(
            id: UUID,
            date: Date,
            paymentMethod: String,
            note: String,
            channelFeePercentage: Decimal = 0,
            channelFeeAmount: Decimal = 0,
            items: [SaleItemSnapshot]
        ) {
            self.id = id
            self.date = date
            self.paymentMethod = paymentMethod
            self.note = note
            self.channelFeePercentage = channelFeePercentage
            self.channelFeeAmount = channelFeeAmount
            self.items = items
        }

        private enum CodingKeys: String, CodingKey {
            case id
            case date
            case paymentMethod
            case note
            case channelFeePercentage
            case channelFeeAmount
            case items
        }

        /// Campos ausentes em backups anteriores entram como zero.
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(UUID.self, forKey: .id)
            date = try container.decode(Date.self, forKey: .date)
            paymentMethod = try container.decode(String.self, forKey: .paymentMethod)
            note = try container.decode(String.self, forKey: .note)
            channelFeePercentage = try container.decodeIfPresent(
                Decimal.self,
                forKey: .channelFeePercentage
            ) ?? 0
            channelFeeAmount = try container.decodeIfPresent(
                Decimal.self,
                forKey: .channelFeeAmount
            ) ?? 0
            items = try container.decode([SaleItemSnapshot].self, forKey: .items)
        }
    }

    public struct SaleItemSnapshot: Codable, Equatable, Sendable {
        public let id: UUID
        public let productID: UUID
        public let productName: String
        public let unitPrice: Decimal
        public let unitCost: Decimal
        public let quantity: Int

        public init(
            id: UUID,
            productID: UUID,
            productName: String,
            unitPrice: Decimal,
            unitCost: Decimal,
            quantity: Int
        ) {
            self.id = id
            self.productID = productID
            self.productName = productName
            self.unitPrice = unitPrice
            self.unitCost = unitCost
            self.quantity = quantity
        }
    }
}
