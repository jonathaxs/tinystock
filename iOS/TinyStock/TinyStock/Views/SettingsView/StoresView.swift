// ⌘
//  TinyStock/Views/SettingsView/StoresView.swift
//
//  Propósito: Gerenciar, selecionar, ordenar e excluir as lojas do TinyStock.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-25.
// ⌘

import SwiftData
import SwiftUI
import TinyStockCore

struct StoresView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(StoreSession.self) private var storeSession
    @Query private var stores: [StoreProfile]

    @State private var formRoute: StoreFormRoute?
    @State private var deletionRequest: StoreDeletionRequest?
    @State private var errorMessage: String?

    private var activeStores: [StoreProfile] {
        StoreProfileService.orderedForDisplay(stores.filter { !$0.isArchived })
    }

    private var archivedStores: [StoreProfile] {
        StoreProfileService.orderedForDisplay(stores.filter(\.isArchived))
    }

    var body: some View {
        List {
            Section {
                ForEach(activeStores) { store in
                    activeRow(store)
                }
                .onMove(perform: moveActiveStores)
                .onDelete { requestDeletion(from: activeStores, at: $0) }
            } header: {
                Text(String(localized: "stores.section.active", bundle: .tinyStockCore))
            } footer: {
                Text(String(localized: "stores.section.footer", bundle: .tinyStockCore))
            }

            if !archivedStores.isEmpty {
                Section(String(localized: "stores.section.archived", bundle: .tinyStockCore)) {
                    ForEach(archivedStores) { store in
                        archivedRow(store)
                    }
                    .onDelete { requestDeletion(from: archivedStores, at: $0) }
                }
            }
        }
        .navigationTitle(String(localized: "stores.title", bundle: .tinyStockCore))
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                EditButton()

                Button {
                    formRoute = StoreFormRoute(store: nil)
                } label: {
                    Label(
                        String(localized: "stores.add", bundle: .tinyStockCore),
                        systemImage: "plus"
                    )
                }
            }
        }
        .sheet(item: $formRoute) { route in
            StoreFormView(store: route.store)
        }
        .alert(
            String(localized: "stores.delete.confirm.title", bundle: .tinyStockCore),
            isPresented: Binding(
                get: { deletionRequest != nil },
                set: { if !$0 { deletionRequest = nil } }
            ),
            presenting: deletionRequest
        ) { request in
            Button(
                String(localized: "common.delete", bundle: .tinyStockCore),
                role: .destructive
            ) {
                deletePermanently(request.store)
            }
            Button(String(localized: "common.cancel", bundle: .tinyStockCore), role: .cancel) {}
        } message: { request in
            Text(deletionMessage(for: request))
        }
        .alert(
            String(localized: "stores.error.title", bundle: .tinyStockCore),
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button(String(localized: "common.ok", bundle: .tinyStockCore)) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func activeRow(_ store: StoreProfile) -> some View {
        HStack(spacing: 12) {
            Button {
                select(store)
            } label: {
                StoreManagementRow(
                    store: store,
                    isSelected: store.id == storeSession.selectedStoreID
                )
            }
            .buttonStyle(.plain)
            .accessibilityHint(String(localized: "stores.select.hint", bundle: .tinyStockCore))
            .accessibilityAddTraits(store.id == storeSession.selectedStoreID ? [.isSelected] : [])

            Menu {
                Button {
                    formRoute = StoreFormRoute(store: store)
                } label: {
                    Label(
                        String(localized: "common.edit", bundle: .tinyStockCore),
                        systemImage: "pencil"
                    )
                }

                Button(role: .destructive) {
                    requestDeletion(store)
                } label: {
                    Label(
                        String(localized: "common.delete", bundle: .tinyStockCore),
                        systemImage: "trash"
                    )
                }
                .disabled(activeStores.count == 1)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .frame(width: 44, height: 44)
                    .contentShape(.rect)
            }
            .accessibilityLabel(
                String(
                    format: String(localized: "stores.actions.accessibility", bundle: .tinyStockCore),
                    store.name
                )
            )
        }
    }

    private func archivedRow(_ store: StoreProfile) -> some View {
        HStack(spacing: 12) {
            StoreManagementRow(store: store, isSelected: false)
                .opacity(0.65)

            Menu {
                Button {
                    restore(store)
                } label: {
                    Label(
                        String(localized: "stores.restore", bundle: .tinyStockCore),
                        systemImage: "arrow.uturn.backward"
                    )
                }

                Button {
                    formRoute = StoreFormRoute(store: store)
                } label: {
                    Label(
                        String(localized: "common.edit", bundle: .tinyStockCore),
                        systemImage: "pencil"
                    )
                }

                Button(role: .destructive) {
                    requestDeletion(store)
                } label: {
                    Label(
                        String(localized: "common.delete", bundle: .tinyStockCore),
                        systemImage: "trash"
                    )
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .frame(width: 44, height: 44)
                    .contentShape(.rect)
            }
            .accessibilityLabel(
                String(
                    format: String(localized: "stores.actions.accessibility", bundle: .tinyStockCore),
                    store.name
                )
            )
        }
    }

    private func select(_ store: StoreProfile) {
        do {
            try storeSession.select(store)
        } catch let error as StoreProfileError {
            errorMessage = error.localizedMessage
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func requestDeletion(_ store: StoreProfile) {
        do {
            let summary = try StoreProfileService.deletionSummary(for: store, in: modelContext)
            deletionRequest = StoreDeletionRequest(store: store, summary: summary)
        } catch let error as StoreProfileError {
            errorMessage = error.localizedMessage
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func requestDeletion(from stores: [StoreProfile], at offsets: IndexSet) {
        guard let index = offsets.first, stores.indices.contains(index) else { return }
        requestDeletion(stores[index])
    }

    private func deletePermanently(_ store: StoreProfile) {
        let isSelected = store.id == storeSession.selectedStoreID

        do {
            let replacement = try StoreProfileService.deletePermanently(store, in: modelContext)
            try modelContext.save()

            if isSelected, let replacement {
                try storeSession.select(replacement)
            }
            deletionRequest = nil
        } catch let error as StoreProfileError {
            modelContext.rollback()
            errorMessage = error.localizedMessage
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
        }
    }

    private func deletionMessage(for request: StoreDeletionRequest) -> String {
        let format = String(
            localized: "stores.delete.confirm.message",
            bundle: .tinyStockCore
        )
        return String(
            format: format,
            locale: .autoupdatingCurrent,
            request.storeName,
            request.summary.productCount.formatted(),
            request.summary.variantCount.formatted(),
            request.summary.stockMovementCount.formatted(),
            request.summary.orderCount.formatted()
        )
    }

    private func restore(_ store: StoreProfile) {
        do {
            StoreProfileService.restore(store)
            try modelContext.save()
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
        }
    }

    private func moveActiveStores(from source: IndexSet, to destination: Int) {
        var reorderedStores = activeStores
        reorderedStores.move(fromOffsets: source, toOffset: destination)

        do {
            try StoreProfileService.setDisplayOrder(reorderedStores)
            try modelContext.save()
        } catch let error as StoreProfileError {
            modelContext.rollback()
            errorMessage = error.localizedMessage
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
        }
    }
}

private struct StoreManagementRow: View {
    let store: StoreProfile
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            StoreImageView(imageData: store.imageData)

            Text(store.name)
                .foregroundStyle(.primary)
                .lineLimit(2)

            Spacer(minLength: 8)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .accessibilityLabel(
                        String(localized: "stores.current", bundle: .tinyStockCore)
                    )
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .contentShape(.rect)
    }
}

private struct StoreFormRoute: Identifiable {
    let id = UUID()
    let store: StoreProfile?
}

private struct StoreDeletionRequest: Identifiable {
    let id: UUID
    let store: StoreProfile
    let storeName: String
    let summary: StoreDeletionSummary

    init(store: StoreProfile, summary: StoreDeletionSummary) {
        id = store.id
        self.store = store
        storeName = store.name
        self.summary = summary
    }
}
