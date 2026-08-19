// ⌘
//  TinyStockCoreTests/ProductionCostCalculatorTests.swift
//
//  Propósito: Testar custos de impressão 3D, crochê e preço sugerido por margem.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-18.
// ⌘

import Testing
import Foundation
@testable import TinyStockCore

struct ProductionCostCalculatorTests {
    @Test func impressao3DSomaFilamentoEnergiaEOutrosCustos() throws {
        let result = try ProductionCostCalculator.calculate(
            ProductionCostInput(
                method: .printing3D,
                materialQuantity: 250,
                materialUnitPrice: 80,
                productionHours: 5,
                hourlyCost: 1.20,
                additionalCost: 4,
                desiredMarginPercentage: 25
            )
        )

        #expect(result.materialCost == 20)
        #expect(result.timeCost == 6)
        #expect(result.additionalCost == 4)
        #expect(result.totalCost == 30)
        #expect(result.suggestedPrice == 40)
        #expect(result.expectedProfit == 10)
    }

    @Test func crocheAceitaFracaoDeNoveloEValorDaHora() throws {
        let result = try ProductionCostCalculator.calculate(
            ProductionCostInput(
                method: .crochet,
                materialQuantity: 2.5,
                materialUnitPrice: 12,
                productionHours: 4,
                hourlyCost: 15,
                additionalCost: 5,
                desiredMarginPercentage: 50
            )
        )

        #expect(result.materialCost == 30)
        #expect(result.timeCost == 60)
        #expect(result.totalCost == 95)
        #expect(result.suggestedPrice == 190)
        #expect(result.expectedProfit == 95)
    }

    @Test func margemZeroSugereOProprioCusto() throws {
        let result = try ProductionCostCalculator.calculate(
            ProductionCostInput(
                method: .crochet,
                materialQuantity: 1,
                materialUnitPrice: 20,
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
                method: .crochet,
                materialQuantity: 1,
                materialUnitPrice: 10,
                productionHours: 0,
                hourlyCost: 0,
                additionalCost: 0,
                desiredMarginPercentage: 30
            )
        )

        #expect(result.suggestedPrice == Decimal(string: "14.29"))
    }

    @Test func margemCemOuMaiorEhRecusada() {
        for margin in [Decimal(100), Decimal(120)] {
            let input = ProductionCostInput(
                method: .printing3D,
                materialQuantity: 100,
                materialUnitPrice: 80,
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
            method: .crochet,
            materialQuantity: -1,
            materialUnitPrice: 10,
            productionHours: 1,
            hourlyCost: 10,
            additionalCost: 0,
            desiredMarginPercentage: 30
        )

        #expect(throws: ProductionCostError.negativeValue) {
            try ProductionCostCalculator.calculate(input)
        }
    }

    @Test func todoMetodoTemNomeLocalizado() {
        for method in ProductionMethod.allCases {
            #expect(method.localizedName.isEmpty == false)
        }
    }
}
