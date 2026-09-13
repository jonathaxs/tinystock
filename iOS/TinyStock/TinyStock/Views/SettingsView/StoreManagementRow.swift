// ⌘
//  TinyStock/Views/SettingsView/StoreManagementRow.swift
//
//  Propósito: Apresentar uma loja e suas ações de gerenciamento.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-09-12.
// ⌘

import SwiftUI
import TinyStockCore

struct StoreManagementRow: View {
    let store: StoreProfile
    let isSelected: Bool
    let canDelete: Bool
    let onSelect: (() -> Void)?
    let onEdit: () -> Void
    let onRestore: (() -> Void)?
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if store.isArchived {
                content
                    .opacity(0.65)
            } else {
                Button {
                    onSelect?()
                } label: {
                    content
                }
                .buttonStyle(.plain)
                .accessibilityHint(String(localized: "stores.select.hint", bundle: .tinyStockCore))
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }

            actionsMenu
        }
    }

    private var content: some View {
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

    private var actionsMenu: some View {
        Menu {
            if store.isArchived, let onRestore {
                Button(action: onRestore) {
                    Label(
                        String(localized: "stores.restore", bundle: .tinyStockCore),
                        systemImage: "arrow.uturn.backward"
                    )
                }
            }

            Button(action: onEdit) {
                Label(
                    String(localized: "common.edit", bundle: .tinyStockCore),
                    systemImage: "pencil"
                )
            }

            Button(role: .destructive, action: onDelete) {
                Label(
                    String(localized: "common.delete", bundle: .tinyStockCore),
                    systemImage: "trash"
                )
            }
            .disabled(!canDelete)
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
