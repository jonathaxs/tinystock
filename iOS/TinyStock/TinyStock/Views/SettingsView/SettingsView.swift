// ⌘
//  TinyStock/Views/SettingsView/SettingsView.swift
//
//  Propósito: Reunir o backup dos dados e as preferências do app.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-07.
// ⌘

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import TinyStockCore

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Product.name) private var products: [Product]
    @Query(sort: \Sale.date, order: .forward) private var sales: [Sale]

    @State private var exportDocument: BackupDocument?
    @State private var exportFilename = ""
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var pendingPayload: BackupPayload?
    @State private var isConfirmingImport = false
    @State private var presentedMessage: PresentedMessage?

    var body: some View {
        NavigationStack {
            List {
                localBackupSection
            }
            .navigationTitle(String(localized: "tab.settings", bundle: .tinyStockCore))
        }
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument ?? BackupDocument(data: Data()),
            contentType: .json,
            defaultFilename: exportFilename
        ) { result in
            switch result {
            case .success:
                showMessage(
                    titleKey: "settings.backup.success.title",
                    messageKey: "settings.backup.export.success"
                )
            case .failure(let error):
                show(error)
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json]
        ) { result in
            switch result {
            case .success(let url):
                prepareImport(from: url)
            case .failure(let error):
                show(error)
            }
        }
        .alert(
            String(localized: "settings.backup.import.confirm.title", bundle: .tinyStockCore),
            isPresented: $isConfirmingImport
        ) {
            Button(
                String(localized: "settings.backup.import.confirm.action", bundle: .tinyStockCore),
                role: .destructive,
                action: restorePendingBackup
            )
            Button(String(localized: "common.cancel", bundle: .tinyStockCore), role: .cancel) {
                pendingPayload = nil
            }
        } message: {
            if let payload = pendingPayload {
                Text(importConfirmationMessage(for: payload))
            }
        }
        .alert(item: $presentedMessage) { message in
            Alert(
                title: Text(message.title),
                message: Text(message.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // MARK: - Backup local

    private var localBackupSection: some View {
        Section {
            Button(action: prepareExport) {
                Label(
                    String(localized: "settings.backup.export", bundle: .tinyStockCore),
                    systemImage: "square.and.arrow.up"
                )
            }

            Button {
                isImporting = true
            } label: {
                Label(
                    String(localized: "settings.backup.import", bundle: .tinyStockCore),
                    systemImage: "square.and.arrow.down"
                )
            }
        } header: {
            Text(String(localized: "settings.backup.section.local", bundle: .tinyStockCore))
        } footer: {
            Text(String(localized: "settings.backup.section.footer", bundle: .tinyStockCore))
        }
    }

    private func prepareExport() {
        do {
            let data = try BackupManager.export(products: products, sales: sales)
            exportDocument = BackupDocument(data: data)
            exportFilename = BackupManager.suggestedFilename()
            isExporting = true
        } catch {
            show(error)
        }
    }

    private func prepareImport(from url: URL) {
        let isAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if isAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let data = try Data(contentsOf: url)
            pendingPayload = try BackupManager.decode(data)
            isConfirmingImport = true
        } catch {
            show(error)
        }
    }

    private func restorePendingBackup() {
        guard let pendingPayload else { return }

        do {
            try BackupManager.apply(pendingPayload, into: modelContext)
            self.pendingPayload = nil
            showMessage(
                titleKey: "settings.backup.success.title",
                messageKey: "settings.backup.import.success"
            )
        } catch {
            show(error)
        }
    }

    private func importConfirmationMessage(for payload: BackupPayload) -> String {
        String(
            format: String(localized: "settings.backup.import.confirm.message", bundle: .tinyStockCore),
            payload.products.count,
            payload.sales.count
        )
    }

    // MARK: - Retorno das ações

    private func showMessage(titleKey: String.LocalizationValue, messageKey: String.LocalizationValue) {
        presentedMessage = PresentedMessage(
            title: String(localized: titleKey, bundle: .tinyStockCore),
            message: String(localized: messageKey, bundle: .tinyStockCore)
        )
    }

    private func show(_ error: Error) {
        let nsError = error as NSError
        guard !(nsError.domain == NSCocoaErrorDomain && nsError.code == NSUserCancelledError) else {
            return
        }

        presentedMessage = PresentedMessage(
            title: String(localized: "settings.backup.error.title", bundle: .tinyStockCore),
            message: error.localizedDescription
        )
    }
}

private struct PresentedMessage: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

#Preview {
    SettingsView()
        .modelContainer(for: [Product.self, Sale.self, SaleItem.self], inMemory: true)
}
