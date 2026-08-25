// ⌘
//  TinyStock/Views/ProductsView/ProductFormView.swift
//
//  Propósito: Formulário de cadastro e edição de produto, com leitura dos preços e gravação no SwiftData.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-08.
// ⌘

import SwiftUI
import SwiftData
import PhotosUI
import TinyStockCore

struct ProductFormView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// Produto sendo editado. Nil significa cadastro novo.
    private let editingProduct: Product?
    private let storeID: UUID

    // MARK: - Campos do formulário

    @State private var name: String
    @State private var category: String
    @State private var quantity: Int
    @State private var minimumStock: Int

    // Dinheiro entra como texto livre e só vira Decimal na leitura abaixo.
    // Assim o usuário digita "45,90" ou "45.90" sem o campo brigar com ele.
    @State private var costPriceText: String
    @State private var salePriceText: String

    /// Foto já reduzida, pronta pra ir pro banco.
    @State private var imageData: Data?

    /// Item devolvido pelo seletor de fotos, usado só como gatilho do carregamento.
    @State private var pickerItem: PhotosPickerItem?

    /// Segura a interface enquanto a foto é carregada e reduzida.
    @State private var isLoadingPhoto = false

    /// Controla a calculadora sem persistir os campos auxiliares no produto.
    @State private var isPresentingCostCalculator = false

    // MARK: - Inicializador

    /// Sem argumento abre em branco pra cadastrar; com um produto abre preenchido pra editar.
    init(storeID: UUID, product: Product? = nil) {
        self.storeID = storeID
        editingProduct = product

        _name = State(initialValue: product?.name ?? "")
        _category = State(initialValue: product?.category ?? "")
        _quantity = State(initialValue: product?.quantity ?? 0)
        _minimumStock = State(initialValue: product?.minimumStock ?? 0)

        // Preço vira texto de edição, ou seja, sem símbolo e sem separador de milhar.
        _costPriceText = State(
            initialValue: CurrencyFormatter.editableText(from: product?.costPrice ?? 0)
        )
        _salePriceText = State(
            initialValue: CurrencyFormatter.editableText(from: product?.salePrice ?? 0)
        )

        _imageData = State(initialValue: product?.imageData)
    }

    // MARK: - Valores derivados

    /// Campo vazio conta como zero, que é o padrão do model.
    private var costPrice: Decimal {
        CurrencyFormatter.decimal(from: costPriceText) ?? 0
    }

    private var salePrice: Decimal {
        CurrencyFormatter.decimal(from: salePriceText) ?? 0
    }

    private var unitProfit: Decimal {
        salePrice - costPrice
    }

    /// Nome é o único campo obrigatório. O resto tem padrão que faz sentido.
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Chave literal nos dois lados pra ferramenta de localização conseguir enxergar ambas.
    private var photoButtonTitle: String {
        imageData == nil
            ? String(localized: "product.form.photo.choose", bundle: .tinyStockCore)
            : String(localized: "product.form.photo.change", bundle: .tinyStockCore)
    }

    /// Chave literal nos dois lados pra ferramenta de localização conseguir enxergar ambas.
    private var navigationTitle: String {
        editingProduct == nil
            ? String(localized: "product.form.title.new", bundle: .tinyStockCore)
            : String(localized: "product.form.title.edit", bundle: .tinyStockCore)
    }

    /// Placeholder dos campos de dinheiro sai do próprio formatador, então
    /// acompanha o idioma do aparelho sem string fixa espalhada na view.
    private var currencyPlaceholder: String {
        Decimal.zero.currencyText
    }

    // MARK: - Corpo

    var body: some View {
        NavigationStack {
            Form {
                photoSection
                identificationSection
                stockSection
                pricesSection
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel", bundle: .tinyStockCore)) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.save", bundle: .tinyStockCore)) {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
        }
        .sheet(isPresented: $isPresentingCostCalculator) {
            ProductionCostCalculatorView { result in
                costPriceText = CurrencyFormatter.editableText(from: result.totalCost)
                salePriceText = CurrencyFormatter.editableText(from: result.suggestedPrice)
            }
        }
    }

    // MARK: - Seções

    private var photoSection: some View {
        Section {
            // Foto centralizada pra ficar claro que ela representa o produto inteiro.
            HStack {
                Spacer()
                ProductImageView(imageData: imageData, side: 120)
                    .overlay {
                        if isLoadingPhoto {
                            ProgressView()
                        }
                    }
                Spacer()
            }
            .listRowBackground(Color.clear)

            PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                Label(photoButtonTitle, systemImage: "photo")
            }

            if imageData != nil {
                Button(role: .destructive) {
                    imageData = nil
                    pickerItem = nil
                } label: {
                    Label(
                        String(localized: "product.form.photo.remove", bundle: .tinyStockCore),
                        systemImage: "trash"
                    )
                }
            }
        } header: {
            Text(String(localized: "product.form.section.photo", bundle: .tinyStockCore))
        } footer: {
            Text(String(localized: "product.form.photo.footer", bundle: .tinyStockCore))
        }
        .onChange(of: pickerItem) { _, newItem in
            Task { await loadPhoto(newItem) }
        }
    }

    private var identificationSection: some View {
        Section(String(localized: "product.form.section.identification", bundle: .tinyStockCore)) {
            TextField(
                String(localized: "product.form.name", bundle: .tinyStockCore),
                text: $name,
                prompt: Text(String(localized: "product.form.name.placeholder", bundle: .tinyStockCore))
            )

            TextField(
                String(localized: "product.form.category", bundle: .tinyStockCore),
                text: $category,
                prompt: Text(String(localized: "product.form.category.placeholder", bundle: .tinyStockCore))
            )
        }
    }

    private var stockSection: some View {
        Section {
            LabeledContent {
                TextField("0", value: $quantity, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
            } label: {
                Text(String(localized: "product.form.quantity", bundle: .tinyStockCore))
            }

            LabeledContent {
                TextField("0", value: $minimumStock, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
            } label: {
                Text(String(localized: "product.form.minimumStock", bundle: .tinyStockCore))
            }
        } header: {
            Text(String(localized: "product.form.section.stock", bundle: .tinyStockCore))
        } footer: {
            Text(String(localized: "product.form.stock.footer", bundle: .tinyStockCore))
        }
    }

    private var pricesSection: some View {
        Section {
            LabeledContent {
                TextField(currencyPlaceholder, text: $costPriceText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            } label: {
                Text(String(localized: "product.form.costPrice", bundle: .tinyStockCore))
            }

            LabeledContent {
                TextField(currencyPlaceholder, text: $salePriceText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            } label: {
                Text(String(localized: "product.form.salePrice", bundle: .tinyStockCore))
            }

            // Resumo em tempo real pra pessoa perceber na hora se está vendendo no prejuízo.
            LabeledContent {
                Text(unitProfit.currencyText)
                    .foregroundStyle(unitProfit < 0 ? Color.red : Color.primary)
            } label: {
                Text(String(localized: "product.form.unitProfit", bundle: .tinyStockCore))
            }

            Button {
                isPresentingCostCalculator = true
            } label: {
                Label(
                    String(localized: "product.form.costCalculator", bundle: .tinyStockCore),
                    systemImage: "calculator"
                )
            }
        } header: {
            Text(String(localized: "product.form.section.prices", bundle: .tinyStockCore))
        } footer: {
            Text(String(localized: "product.form.prices.footer", bundle: .tinyStockCore))
        }
    }

    // MARK: - Carregamento da foto

    /// Traz a foto escolhida e já reduz antes de guardar no estado.
    /// A redução roda fora da main thread pra não travar a interface com foto grande.
    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }

        isLoadingPhoto = true
        defer { isLoadingPhoto = false }

        guard let rawData = try? await item.loadTransferable(type: Data.self) else { return }

        let prepared = await Task.detached(priority: .userInitiated) {
            ProductImageProcessor.prepared(from: rawData)
        }.value

        // Se o arquivo não for uma imagem legível, mantém a foto anterior em vez de apagar.
        guard let prepared else { return }

        imageData = prepared
    }

    // MARK: - Gravação

    private func save() {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)

        // Trava em zero pra um valor negativo digitado não virar estoque inválido.
        let safeQuantity = max(0, quantity)
        let safeMinimumStock = max(0, minimumStock)

        if let product = editingProduct {
            // Edição altera o objeto que já está no banco, mantendo o createdAt original.
            product.name = cleanName
            product.category = cleanCategory
            product.quantity = safeQuantity
            product.minimumStock = safeMinimumStock
            product.costPrice = costPrice
            product.salePrice = salePrice
            product.imageData = imageData
            product.updatedAt = Date()
        } else {
            let now = Date()
            let product = Product(
                storeID: storeID,
                name: cleanName,
                category: cleanCategory,
                quantity: safeQuantity,
                minimumStock: safeMinimumStock,
                costPrice: costPrice,
                salePrice: salePrice,
                imageData: imageData,
                createdAt: now,
                updatedAt: now
            )
            // O contexto do ambiente tem autosave ligado, então basta inserir.
            modelContext.insert(product)
        }

        dismiss()
    }
}

#Preview("Cadastro") {
    ProductFormView(storeID: UUID())
        .modelContainer(for: [StoreProfile.self, Product.self], inMemory: true)
}

#Preview("Edição") {
    ProductFormView(
        storeID: StoreScope.unassignedStoreID,
        product: Product(name: "Amigurumi Gato", category: "Crochê", quantity: 12, costPrice: 20, salePrice: 45)
    )
    .modelContainer(for: [StoreProfile.self, Product.self], inMemory: true)
}
