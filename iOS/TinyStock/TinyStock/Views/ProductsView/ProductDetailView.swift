// Proposito: Exibir dados atuais do produto nos atalhos de consulta.
// Created by Jonathas Motta (@jonathaxs) on 2026-08-08.

import SwiftUI
import SwiftData
import TinyStockCore

struct ProductDetailView: View {
    let product: Product
    @Query private var variants: [ProductVariant]
    @State private var isPresentingForm = false

    init(product: Product) {
        self.product = product
        let productID = product.id
        let storeID = product.storeID
        _variants = Query(filter: #Predicate<ProductVariant> {
            $0.productID == productID && $0.storeID == storeID
        }, sort: \ProductVariant.name)
    }

    private var quantity: Decimal {
        ProductVariantService.displayedQuantity(for: product, among: variants)
    }

    var body: some View {
        List {
            if product.imageData != nil {
                Section {
                    ProductImageView(imageData: product.imageData, side: 160)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                }
            }
            Section(String(localized: "product.form.variants", bundle: .tinyStockCore)) {
                ForEach(variants) { variant in
                    LabeledContent(variant.name) { Text(variant.quantity, format: .number) }
                }
                LabeledContent(String(localized: "product.form.variant.available", bundle: .tinyStockCore)) {
                    Text(quantity.formatted())
                }
            }
            Section(String(localized: "product.form.section.prices", bundle: .tinyStockCore)) {
                LabeledContent(String(localized: "product.form.salePrice", bundle: .tinyStockCore), value: product.salePrice.currencyText)
                LabeledContent(String(localized: "product.form.costPrice", bundle: .tinyStockCore), value: product.costPrice.currencyText)
                LabeledContent(String(localized: "product.form.unitProfit", bundle: .tinyStockCore), value: product.unitProfit.currencyText)
                LabeledContent(String(localized: "product.detail.potentialProfit", bundle: .tinyStockCore)) {
                    Text((product.unitProfit * quantity).currencyText)
                }
            }
        }
        .navigationTitle(product.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(String(localized: "common.edit", bundle: .tinyStockCore)) { isPresentingForm = true }
            }
        }
        .sheet(isPresented: $isPresentingForm) { ProductFormView(storeID: product.storeID, product: product) }
    }
}

#Preview {
    NavigationStack {
        ProductDetailView(product: Product(name: "Caneca", costPrice: 10, salePrice: 25))
    }
    .modelContainer(for: [Product.self, ProductVariant.self, StockMovement.self], inMemory: true)
}
