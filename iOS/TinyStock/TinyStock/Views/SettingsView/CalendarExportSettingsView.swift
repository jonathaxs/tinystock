// Proposito: Controlar a exibicao da exportacao opcional para o Calendario.
// Created by Jonathas Motta (@jonathaxs) on 2026-09-09.

import SwiftUI
import TinyStockCore

struct CalendarExportSettingsView: View {
    @AppStorage(OrderCalendarExportSettings.isEnabledKey) private var isEnabled = true

    var body: some View {
        Form {
            Section {
                Toggle(
                    String(localized: "settings.calendar.showExport", bundle: .tinyStockCore),
                    isOn: $isEnabled
                )
            } footer: {
                Text(String(localized: "settings.calendar.showExport.footer", bundle: .tinyStockCore))
            }

            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(String(localized: "settings.calendar.privacy", bundle: .tinyStockCore))
                        .font(.subheadline.weight(.medium))

                    Text(String(localized: "settings.calendar.privacy.message", bundle: .tinyStockCore))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .navigationTitle(String(localized: "settings.calendar.title", bundle: .tinyStockCore))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { CalendarExportSettingsView() }
}
