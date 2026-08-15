// ⌘
//  TinyStockCore/Models/Sale.swift
//
//  Propósito: Model SwiftData de uma venda, com seus itens, forma de pagamento e totais.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-11.
// ⌘

import Foundation
import SwiftData

// MARK: - Venda

/// Uma venda fechada, com um ou mais itens.
/// Como o `Product`, nasce com valor padrão em tudo pra continuar compatível com CloudKit.
@Model
public final class Sale {

    public var id: UUID = UUID()

    /// Quando a venda aconteceu. É por essa data que o histórico agrupa e os relatórios filtram.
    public var date: Date = Date()

    /// Forma de pagamento guardada como texto.
    ///
    /// Guardar o texto cru em vez do enum é feio, mas é o que deixa os filtros dos relatórios
    /// funcionarem sem dor: `#Predicate` do SwiftData não lida bem com enum. Quem usa o model
    /// mexe sempre em `paymentMethod` logo abaixo, então a feiura fica escondida aqui.
    public var paymentMethodRawValue: String = PaymentMethod.pix.rawValue

    /// Anotação livre, por exemplo o nome do cliente.
    public var note: String = ""

    /// Itens da venda. Apagar a venda apaga os itens junto.
    /// Opcional porque relação to-many precisa ser opcional pro CloudKit.
    @Relationship(deleteRule: .cascade, inverse: \SaleItem.sale)
    public var items: [SaleItem]?

    // MARK: - Inicializador

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        paymentMethod: PaymentMethod = .pix,
        note: String = ""
    ) {
        self.id = id
        self.date = date
        self.paymentMethodRawValue = paymentMethod.rawValue
        self.note = note
    }

    // MARK: - Forma de pagamento

    /// Acesso com tipo à forma de pagamento. Texto desconhecido cai no Pix,
    /// que é o padrão, em vez de quebrar a tela.
    ///
    /// Precisa de `@Transient`: por ter `set`, o SwiftData tentaria persistir essa
    /// propriedade como se fosse uma coluna, e o app quebra ao inserir a venda.
    @Transient
    public var paymentMethod: PaymentMethod {
        get { PaymentMethod(rawValue: paymentMethodRawValue) ?? .pix }
        set { paymentMethodRawValue = newValue.rawValue }
    }

    // MARK: - Derivados (não persistidos)

    /// Itens numa lista comum, já que a propriedade persistida é opcional.
    ///
    /// Ordenado por nome de propósito: relação to-many do SwiftData não guarda ordem,
    /// então sem isso a mesma venda apareceria com os itens embaralhados a cada abertura.
    /// Ordenar aqui custa pouco, porque venda de artesanato tem poucos itens.
    public var itemList: [SaleItem] {
        (items ?? []).sorted {
            $0.productName.localizedStandardCompare($1.productName) == .orderedAscending
        }
    }

    /// Quantas unidades saíram no total, somando todos os itens.
    public var totalQuantity: Int {
        itemList.reduce(0) { $0 + $1.quantity }
    }

    /// Valor total cobrado do cliente.
    public var total: Decimal {
        itemList.reduce(0) { $0 + $1.subtotal }
    }

    /// Quanto custou o que foi vendido.
    public var totalCost: Decimal {
        itemList.reduce(0) { $0 + $1.subtotalCost }
    }

    /// Lucro bruto da venda. A taxa de canal, tipo a da Shopee, entra depois.
    public var profit: Decimal {
        total - totalCost
    }
}
