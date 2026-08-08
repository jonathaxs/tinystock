// ⌘
//  TinyStock/Views/SettingsView/SettingsView.swift
//
//  Propósito: Ajustes do app (backup e preferências). Placeholder na Fase 0; backup JSON/iCloud chega na Fase 3.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-07.
// ⌘

import SwiftUI
import TinyStockCore

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label(String(localized: "settings.placeholder.title", bundle: .tinyStockCore), systemImage: "gearshape")
            } description: {
                Text(String(localized: "settings.placeholder.message", bundle: .tinyStockCore))
            }
            .navigationTitle(String(localized: "tab.settings", bundle: .tinyStockCore))
        }
    }
}

#Preview {
    SettingsView()
}
