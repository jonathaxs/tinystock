// ⌘
//  TinyStockCoreTests/ProductionCostCalculatorTests.swift
//
//  Propósito: Testar componentes de custo livres e preço sugerido por margem.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-18.
// ⌘

import Testing
import Foundation
@testable import TinyStockCore

struct ProductionCostCalculatorTests {
    @Test func somaVariosMateriaisTempoEOutrosCustos() throws {
        let result = try ProductionCostCalculator.calculate(
            ProductionCostInput(
                components: [
                    ProductionCostComponent(quantity: 0.25, unitCost: 80),
                    ProductionCostComponent(quantity: 2, unitCost: 3)
                ],
                productionHours: 5,
                hourlyCost: 1.20,
                additionalCost: 4,
                desiredMarginPercentage: 25
            )
        )

        #expect(result.materialsCost == 26)
        #expect(result.timeCost == 6)
        #expect(result.additionalCost == 4)
        #expect(result.totalCost == 36)
        #expect(result.suggestedPrice == 48)
        #expect(result.expectedProfit == 12)
    }

    @Test func componenteAceitaQuantidadeFracionada() throws {
        let result = try ProductionCostCalculator.calculate(
            ProductionCostInput(
                components: [ProductionCostComponent(quantity: 2.5, unitCost: 12)],
                productionHours: 4,
                hourlyCost: 15,
                additionalCost: 5,
                desiredMarginPercentage: 50
            )
        )

        #expect(result.materialsCost == 30)
        #expect(result.timeCost == 60)
        #expect(result.totalCost == 95)
        #expect(result.suggestedPrice == 190)
        #expect(result.expectedProfit == 95)
    }

    @Test func margemZeroSugereOProprioCusto() throws {
        let result = try ProductionCostCalculator.calculate(
            ProductionCostInput(
                components: [ProductionCostComponent(quantity: 1, unitCost: 20)],
                productionHours: 0,
                hourlyCost: 0,
                additionalCost: 0,
                desiredMarginPercentage: 0
            )
        )

        #expect(result.totalCost == 20)
        #expect(result.suggestedPrice == 20)
        #expect(result.expectedProfit == 0)
    }

    @Test func precoArredondaPraCimaSemPerderMargem() throws {
        let result = try ProductionCostCalculator.calculate(
            ProductionCostInput(
                components: [ProductionCostComponent(quantity: 1, unitCost: 10)],
                productionHours: 0,
                hourlyCost: 0,
                additionalCost: 0,
                desiredMarginPercentage: 30
            )
        )

        #expect(result.suggestedPrice == Decimal(string: "14.29"))
    }

    @Test func calculaSemMaterialQuandoExisteOutroCusto() throws {
        let result = try ProductionCostCalculator.calculate(
            ProductionCostInput(
                components: [],
                productionHours: 2,
                hourlyCost: 10,
                additionalCost: 5,
                desiredMarginPercentage: 0
            )
        )

        #expect(result.materialsCost == 0)
        #expect(result.totalCost == 25)
    }

    @Test func margemCemOuMaiorEhRecusada() {
        for margin in [Decimal(100), Decimal(120)] {
            let input = ProductionCostInput(
                components: [ProductionCostComponent(quantity: 1, unitCost: 10)],
                productionHours: 1,
                hourlyCost: 1,
                additionalCost: 0,
                desiredMarginPercentage: margin
            )

            #expect(throws: ProductionCostError.invalidMargin) {
                try ProductionCostCalculator.calculate(input)
            }
        }
    }

    @Test func valorNegativoEhRecusado() {
        let input = ProductionCostInput(
            components: [ProductionCostComponent(quantity: -1, unitCost: 10)],
            productionHours: 1,
            hourlyCost: 10,
            additionalCost: 0,
            desiredMarginPercentage: 30
        )

        #expect(throws: ProductionCostError.negativeValue) {
            try ProductionCostCalculator.calculate(input)
        }
    }
}
