// ⌘
//  TinyStockCore/Models/PaymentMethod.swift
//
//  Propósito: Formas de pagamento aceitas no registro de uma venda.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-11.
// ⌘

import Foundation

// MARK: - Forma de pagamento

/// Como o cliente pagou. Shopee entra aqui porque a taxa do canal muda o lucro
/// líquido, e isso vai ser calculado à parte mais pra frente.
public enum PaymentMethod: String, CaseIterable, Codable, Sendable {
    case pix
    case cash
    case card
    case shopee

    /// Nome pronto pra tela, traduzido pelo bundle do Core.
    public var localizedName: String {
        switch self {
        case .pix:
            String(localized: "payment.pix", bundle: .tinyStockCore)
        case .cash:
            String(localized: "payment.cash", bundle: .tinyStockCore)
        case .card:
            String(localized: "payment.card", bundle: .tinyStockCore)
        case .shopee:
            String(localized: "payment.shopee", bundle: .tinyStockCore)
        }
    }

    /// Ícone do SF Symbols usado nas listas de venda.
    public var symbolName: String {
        switch self {
        case .pix: "qrcode"
        case .cash: "banknote"
        case .card: "creditcard"
        case .shopee: "bag"
        }
    }
}
