// ⌘
//  TinyStockCore/Services/ProductionCostCalculator.swift
//
//  Propósito: Calcular custo de produção e preço sugerido pela margem desejada.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-18.
// ⌘

import Foundation

public enum ProductionMethod: String, CaseIterable, Identifiable, Sendable {
    case printing3D
    case crochet

    public var id: String { rawValue }

    public var localizedName: String {
        switch self {
        case .printing3D:
            String(localized: "costCalculator.method.printing3D", bundle: .tinyStockCore)
        case .crochet:
            String(localized: "costCalculator.method.crochet", bundle: .tinyStockCore)
        }
    }
}

public struct ProductionCostInput: Equatable, Sendable {
    public let method: ProductionMethod
    public let materialQuantity: Decimal
    public let materialUnitPrice: Decimal
    public let productionHours: Decimal
    public let hourlyCost: Decimal
    public let additionalCost: Decimal
    public let desiredMarginPercentage: Decimal

    public init(
        method: ProductionMethod,
        materialQuantity: Decimal,
        materialUnitPrice: Decimal,
        productionHours: Decimal,
        hourlyCost: Decimal,
        additionalCost: Decimal,
        desiredMarginPercentage: Decimal
    ) {
        self.method = method
        self.materialQuantity = materialQuantity
        self.materialUnitPrice = materialUnitPrice
        self.productionHours = productionHours
        self.hourlyCost = hourlyCost
        self.additionalCost = additionalCost
        self.desiredMarginPercentage = desiredMarginPercentage
    }
}

public struct ProductionCostResult: Equatable, Sendable {
    public let materialCost: Decimal
    public let timeCost: Decimal
    public let additionalCost: Decimal
    public let totalCost: Decimal
    public let suggestedPrice: Decimal
    public let expectedProfit: Decimal

    public init(
        materialCost: Decimal,
        timeCost: Decimal,
        additionalCost: Decimal,
        totalCost: Decimal,
        suggestedPrice: Decimal,
        expectedProfit: Decimal
    ) {
        self.materialCost = materialCost
        self.timeCost = timeCost
        self.additionalCost = additionalCost
        self.totalCost = totalCost
        self.suggestedPrice = suggestedPrice
        self.expectedProfit = expectedProfit
    }
}

public enum ProductionCostError: Error, Equatable, Sendable {
    case negativeValue
    case invalidMargin
}

public enum ProductionCostCalculator {
    public static func calculate(_ input: ProductionCostInput) throws -> ProductionCostResult {
        let numericValues = [
            input.materialQuantity,
            input.materialUnitPrice,
            input.productionHours,
            input.hourlyCost,
            input.additionalCost
        ]
        guard numericValues.allSatisfy({ $0 >= 0 }) else {
            throw ProductionCostError.negativeValue
        }
        guard input.desiredMarginPercentage >= 0, input.desiredMarginPercentage < 100 else {
            throw ProductionCostError.invalidMargin
        }

        let rawMaterialCost: Decimal
        switch input.method {
        case .printing3D:
            // Na impressão 3D a quantidade entra em gramas e o filamento em preço por quilo.
            rawMaterialCost = (input.materialQuantity / 1_000) * input.materialUnitPrice
        case .crochet:
            // No crochê a quantidade representa novelos, inclusive frações de novelo.
            rawMaterialCost = input.materialQuantity * input.materialUnitPrice
        }

        let rawTimeCost = input.productionHours * input.hourlyCost
        let materialCost = rounded(rawMaterialCost)
        let timeCost = rounded(rawTimeCost)
        let additionalCost = rounded(input.additionalCost)
        let totalCost = rounded(rawMaterialCost + rawTimeCost + input.additionalCost)
        let marginFactor = 1 - (input.desiredMarginPercentage / 100)
        let suggestedPrice = roundedUp(totalCost / marginFactor)

        return ProductionCostResult(
            materialCost: materialCost,
            timeCost: timeCost,
            additionalCost: additionalCost,
            totalCost: totalCost,
            suggestedPrice: suggestedPrice,
            expectedProfit: rounded(suggestedPrice - totalCost)
        )
    }

    /// Custos usam arredondamento comercial; o preço sobe o centavo pra não perder a margem.
    private static func rounded(_ value: Decimal) -> Decimal {
        var value = value
        var result = Decimal.zero
        NSDecimalRound(&result, &value, 2, .plain)
        return result
    }

    private static func roundedUp(_ value: Decimal) -> Decimal {
        var value = value
        var result = Decimal.zero
        NSDecimalRound(&result, &value, 2, .up)
        return result
    }
}
