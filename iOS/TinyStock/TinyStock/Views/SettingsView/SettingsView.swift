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
    @Query private var selectedStores: [StoreProfile]
    @Query private var products: [Product]
    @Query private var sales: [Sale]

    private let storeID: UUID

    @State private var exportDocument: BackupDocument?
    @State private var exportFilename = ""
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var pendingPayload: BackupPayload?
    @State private var isConfirmingImport = false
    @State private var presentedMessage: PresentedMessage?

    @State private var isICloudAvailable = ICloudBackupManager.isSignedIn
    @State private var iCloudLastBackup: Date?
    @State private var isSavingToICloud = false
    @State private var isRestoringFromICloud = false
    @State private var isConfirmingICloudRestore = false

    init(storeID: UUID) {
        self.storeID = storeID
        _selectedStores = Query(
            filter: #Predicate<StoreProfile> { $0.id == storeID }
        )
        _products = Query(
            filter: #Predicate<Product> { $0.storeID == storeID },
            sort: \Product.name
        )
        _sales = Query(
            filter: #Predicate<Sale> { $0.storeID == storeID },
            sort: \Sale.date,
            order: .forward
        )
    }

    var body: some View {
        NavigationStack {
            List {
                storeSection
                iCloudBackupSection
                localBackupSection
            }
            .navigationTitle(String(localized: "tab.settings", bundle: .tinyStockCore))
        }
        .task {
            await refreshICloudStatus()
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
        .alert(
            String(localized: "settings.backup.icloud.restore.confirm.title", bundle: .tinyStockCore),
            isPresented: $isConfirmingICloudRestore
        ) {
            Button(
                String(localized: "settings.backup.icloud.restore", bundle: .tinyStockCore),
                role: .destructive
            ) {
                Task { await restoreFromICloud() }
            }
            Button(String(localized: "common.cancel", bundle: .tinyStockCore), role: .cancel) { }
        } message: {
            Text(String(localized: "settings.backup.icloud.restore.confirm.message", bundle: .tinyStockCore))
        }
        .alert(item: $presentedMessage) { message in
            Alert(
                title: Text(message.title),
                message: Text(message.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // MARK: - Loja

    private var storeSection: some View {
        Section(String(localized: "settings.store.section", bundle: .tinyStockCore)) {
            NavigationLink {
                StoresView()
            } label: {
                HStack(spacing: 12) {
                    StoreImageView(imageData: selectedStores.first?.imageData)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedStores.first?.name ?? StoreProfileService.localizedDefaultName)
                            .foregroundStyle(.primary)

                        Text(String(localized: "settings.store.manage", bundle: .tinyStockCore))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Backup no iCloud Drive

    private var iCloudBackupSection: some View {
        Section {
            if isICloudAvailable {
                Button {
                    Task { await saveToICloud() }
                } label: {
                    HStack {
                        Label(
                            String(localized: "settings.backup.icloud.save", bundle: .tinyStockCore),
                            systemImage: "icloud.and.arrow.up"
                        )

                        if isSavingToICloud {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(isSavingToICloud || isRestoringFromICloud)

                Button {
                    isConfirmingICloudRestore = true
                } label: {
                    HStack {
                        Label(
                            String(localized: "settings.backup.icloud.restore", bundle: .tinyStockCore),
                            systemImage: "icloud.and.arrow.down"
                        )

                        if isRestoringFromICloud {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(isSavingToICloud || isRestoringFromICloud)
            } else {
                Label(
                    String(localized: "settings.backup.icloud.unavailable", bundle: .tinyStockCore),
                    systemImage: "icloud.slash"
                )
                .foregroundStyle(.secondary)
            }
        } header: {
            Text("iCloud Drive")
        } footer: {
            iCloudFooter
        }
    }

    @ViewBuilder
    private var iCloudFooter: some View {
        if let iCloudLastBackup {
            Text(
                String(
                    format: String(localized: "settings.backup.icloud.lastBackup", bundle: .tinyStockCore),
                    iCloudLastBackup.formatted(date: .abbreviated, time: .shortened)
                )
            )
        } else if isICloudAvailable {
            Text(String(localized: "settings.backup.icloud.noBackup", bundle: .tinyStockCore))
        } else {
            Text(String(localized: "settings.backup.icloud.unavailable.footer", bundle: .tinyStockCore))
        }
    }

    private func refreshICloudStatus() async {
        isICloudAvailable = ICloudBackupManager.isSignedIn
        iCloudLastBackup = isICloudAvailable
            ? await ICloudBackupManager.lastBackupDate()
            : nil
    }

    private func saveToICloud() async {
        isSavingToICloud = true

        do {
            let data = try BackupManager.export(products: products, sales: sales)
            try await ICloudBackupManager.save(data)
            await refreshICloudStatus()
            isSavingToICloud = false
            showMessage(
                titleKey: "settings.backup.success.title",
                messageKey: "settings.backup.icloud.save.success"
            )
        } catch {
            isSavingToICloud = false
            show(error)
        }
    }

    private func restoreFromICloud() async {
        isRestoringFromICloud = true

        do {
            guard let data = try await ICloudBackupManager.load() else {
                isRestoringFromICloud = false
                showMessage(
                    titleKey: "settings.backup.error.title",
                    messageKey: "settings.backup.icloud.noBackup"
                )
                return
            }

            let payload = try BackupManager.decode(data)
            try BackupManager.apply(payload, into: modelContext, storeID: storeID)
            await refreshICloudStatus()
            isRestoringFromICloud = false
            showMessage(
                titleKey: "settings.backup.success.title",
                messageKey: "settings.backup.icloud.restore.success"
            )
        } catch {
            isRestoringFromICloud = false
            show(error)
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
            try BackupManager.apply(pendingPayload, into: modelContext, storeID: storeID)
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
    SettingsView(storeID: UUID())
        .modelContainer(for: [StoreProfile.self, Product.self, Sale.self, SaleItem.self], inMemory: true)
}
