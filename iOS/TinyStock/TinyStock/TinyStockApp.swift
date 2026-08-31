// ⌘
//  TinyStock/TinyStockApp.swift
//
//  Propósito: Ponto de entrada do app; configura o container do SwiftData e mostra a navegação principal.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-07.
// ⌘

import SwiftUI
import SwiftData
import TinyStockCore

@main
struct TinyStockApp: App {

    // Sinaliza falha ao abrir o banco (disco cheio, arquivo corrompido, etc.).
    // Quando true, o app mostra uma tela de erro em vez de travar.
    private let containerInitFailed: Bool
    private let sharedModelContainer: ModelContainer
    private let storeSession: StoreSession

    init() {
        let schema = Schema([
            StoreProfile.self,
            Product.self,
            ProductVariant.self,
            StockMovement.self,
            Sale.self,
            SaleItem.self
        ])
        // URL explícita + cloudKitDatabase: .none evita que o iOS ligue o mirror do CloudKit
        // só por causa de um entitlement de iCloud Documents (usado no futuro pro backup).
        // O arquivo v2 preserva o banco antigo enquanto o novo domínio é construído.
        let storeURL = URL.applicationSupportDirectory.appending(path: "TinyStock-v2.store")
        let config = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = ModelContext(container)
            let session = try StoreSession.bootstrap(in: context)
            try context.save()

            sharedModelContainer = container
            storeSession = session
            containerInitFailed = false
        } catch {
            // Cai pra um container em memória pra o app conseguir mostrar a tela de erro.
            // Nesse estado os dados não são salvos, mas o app não trava.
            let container = try! ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
            )
            let context = ModelContext(container)

            sharedModelContainer = container
            storeSession = try! StoreSession.bootstrap(in: context)
            containerInitFailed = true
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if containerInitFailed {
                    DataStoreErrorView()
                } else {
                    MainView()
                }
            }
            .environment(storeSession)
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Tela de erro do banco de dados

// Exibida no caso raro em que o container do SwiftData não pode ser criado.
private struct DataStoreErrorView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange)

            Text(String(localized: "app.error.dataStore.title", bundle: .tinyStockCore))
                .font(.title2.bold())

            Text(String(localized: "app.error.dataStore.message", bundle: .tinyStockCore))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}
