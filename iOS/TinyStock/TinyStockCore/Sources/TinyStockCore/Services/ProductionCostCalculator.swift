// ⌘
//  TinyStockCore/Services/ProductionCostCalculator.swift
//
//  Propósito: Calcular custo de produção e preço sugerido pela margem desejada.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-18.
// ⌘

import Foundation

/// Um componente livre do custo, como tecido, filamento, embalagem ou tinta.
public struct ProductionCostComponent: Equatable, Sendable {
    public let quantity: Decimal
    public let unitCost: Decimal

    public init(quantity: Decimal, unitCost: Decimal) {
        self.quantity = quantity
        self.unitCost = unitCost
    }
}

public struct ProductionCostInput: Equatable, Sendable {
    public let components: [ProductionCostComponent]
    public let productionHours: Decimal
    public let hourlyCost: Decimal
    public let additionalCost: Decimal
    public let desiredMarginPercentage: Decimal

    public init(
        components: [ProductionCostComponent],
        productionHours: Decimal,
        hourlyCost: Decimal,
        additionalCost: Decimal,
        desiredMarginPercentage: Decimal
    ) {
        self.components = components
        self.productionHours = productionHours
        self.hourlyCost = hourlyCost
        self.additionalCost = additionalCost
        self.desiredMarginPercentage = desiredMarginPercentage
    }
}

public struct ProductionCostResult: Equatable, Sendable {
    public let materialsCost: Decimal
    public let timeCost: Decimal
    public let additionalCost: Decimal
    public let totalCost: Decimal
    public let suggestedPrice: Decimal
    public let expectedProfit: Decimal

    public init(
        materialsCost: Decimal,
        timeCost: Decimal,
        additionalCost: Decimal,
        totalCost: Decimal,
        suggestedPrice: Decimal,
        expectedProfit: Decimal
    ) {
        self.materialsCost = materialsCost
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
        let componentValues = input.components.flatMap { [$0.quantity, $0.unitCost] }
        let numericValues = componentValues + [
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

        let rawMaterialsCost = input.components.reduce(Decimal.zero) { partialResult, component in
            partialResult + (component.quantity * component.unitCost)
        }
        let rawTimeCost = input.productionHours * input.hourlyCost
        let materialsCost = rounded(rawMaterialsCost)
        let timeCost = rounded(rawTimeCost)
        let additionalCost = rounded(input.additionalCost)
        let totalCost = rounded(rawMaterialsCost + rawTimeCost + input.additionalCost)
        let marginFactor = 1 - (input.desiredMarginPercentage / 100)
        let suggestedPrice = roundedUp(totalCost / marginFactor)

        return ProductionCostResult(
            materialsCost: materialsCost,
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
