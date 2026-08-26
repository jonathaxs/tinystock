// ⌘
//  TinyStock/Views/SettingsView/StoresView.swift
//
//  Propósito: Gerenciar, selecionar e arquivar as lojas do TinyStock.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-25.
// ⌘

import SwiftData
import SwiftUI
import TinyStockCore

struct StoresView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(StoreSession.self) private var storeSession
    @Query(sort: \StoreProfile.createdAt) private var stores: [StoreProfile]

    @State private var formRoute: StoreFormRoute?
    @State private var errorMessage: String?

    private var activeStores: [StoreProfile] {
        stores.filter { !$0.isArchived }
    }

    private var archivedStores: [StoreProfile] {
        stores.filter(\.isArchived)
    }

    var body: some View {
        List {
            Section {
                ForEach(activeStores) { store in
                    activeRow(store)
                }
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
                }
            }
        }
        .navigationTitle(String(localized: "stores.title", bundle: .tinyStockCore))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
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
            String(localized: "store.error.title", bundle: .tinyStockCore),
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK") {
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
                    archive(store)
                } label: {
                    Label(
                        String(localized: "stores.archive", bundle: .tinyStockCore),
                        systemImage: "archivebox"
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

    private func archive(_ store: StoreProfile) {
        do {
            let replacement = activeStores.first { $0.id != store.id }
            try StoreProfileService.archive(store, in: modelContext)
            try modelContext.save()

            if store.id == storeSession.selectedStoreID, let replacement {
                try storeSession.select(replacement)
            }
        } catch let error as StoreProfileError {
            modelContext.rollback()
            errorMessage = error.localizedMessage
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
        }
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
