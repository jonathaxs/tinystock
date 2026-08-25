// ⌘
//  TinyStockCoreTests/StoreProfileTests.swift
//
//  Propósito: Testes do cadastro e arquivamento seguro das lojas.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-24.
// ⌘

import Foundation
import SwiftData
import Testing
@testable import TinyStockCore

/// Serializada e com banco compartilhado: ver [TestDatabase] para o porquê.
@Suite(.serialized)
@MainActor
struct StoreProfileTests {

    @Test func criacaoRemoveEspacosDoNome() throws {
        let context = try TestDatabase.makeCleanContext()

        let store = try StoreProfileService.create(name: "  VHS Plus  ", in: context)

        #expect(store.name == "VHS Plus")
        #expect(store.isArchived == false)
    }

    @Test func nomeVazioEhRecusado() throws {
        let context = try TestDatabase.makeCleanContext()

        #expect(throws: StoreProfileError.emptyName) {
            try StoreProfileService.create(name: "   \n", in: context)
        }
    }

    @Test func nomeDuplicadoIgnoraMaiusculasEAcentos() throws {
        let context = try TestDatabase.makeCleanContext()
        try StoreProfileService.create(name: "Impressões 3D", in: context)

        #expect(throws: StoreProfileError.duplicateName) {
            try StoreProfileService.create(name: "IMPRESSOES 3D", in: context)
        }
    }

    @Test func lojaPadraoEhCriadaUmaUnicaVez() throws {
        let context = try TestDatabase.makeCleanContext()

        let first = try StoreProfileService.ensureDefaultStore(
            name: "Minha loja",
            in: context
        )
        let second = try StoreProfileService.ensureDefaultStore(
            name: "Outra loja",
            in: context
        )
        let stores = try context.fetch(FetchDescriptor<StoreProfile>())

        #expect(stores.count == 1)
        #expect(first.id == second.id)
        #expect(second.name == "Minha loja")
    }

    @Test func edicaoPreservaDataDeCriacao() throws {
        let context = try TestDatabase.makeCleanContext()
        let createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        let updatedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let store = StoreProfile(name: "Loja 1", createdAt: createdAt, updatedAt: createdAt)
        context.insert(store)

        try StoreProfileService.update(
            store,
            name: "  Loja principal ",
            imageData: nil,
            date: updatedAt,
            in: context
        )

        #expect(store.name == "Loja principal")
        #expect(store.createdAt == createdAt)
        #expect(store.updatedAt == updatedAt)
    }

    @Test func lojaPadraoReativaLojaArquivadaEmBancoInconsistente() throws {
        let context = try TestDatabase.makeCleanContext()
        let archived = StoreProfile(name: "VHS Plus", isArchived: true)
        context.insert(archived)

        let recovered = try StoreProfileService.ensureDefaultStore(in: context)
        let stores = try context.fetch(FetchDescriptor<StoreProfile>())

        #expect(stores.count == 1)
        #expect(recovered.id == archived.id)
        #expect(recovered.isArchived == false)
    }

    @Test func ultimaLojaAtivaNaoPodeSerArquivada() throws {
        let context = try TestDatabase.makeCleanContext()
        let store = try StoreProfileService.create(name: "Minha loja", in: context)

        #expect(throws: StoreProfileError.lastActiveStore) {
            try StoreProfileService.archive(store, in: context)
        }
        #expect(store.isArchived == false)
    }

    @Test func lojaPodeSerArquivadaQuandoExisteOutraAtiva() throws {
        let context = try TestDatabase.makeCleanContext()
        let first = try StoreProfileService.create(name: "VHS Plus", in: context)
        try StoreProfileService.create(name: "Impressões 3D", in: context)
        let archivedAt = Date(timeIntervalSince1970: 1_800_000_000)

        try StoreProfileService.archive(first, date: archivedAt, in: context)

        #expect(first.isArchived == true)
        #expect(first.updatedAt == archivedAt)
    }

    @Test func todoErroTemMensagemLocalizada() {
        let errors: [StoreProfileError] = [
            .emptyName,
            .duplicateName,
            .lastActiveStore,
            .archivedStore
        ]

        #expect(errors.allSatisfy { !$0.localizedMessage.isEmpty })
    }

    // MARK: - Seleção atual

    @Test func sessaoCriaLojaPadraoEPersisteASelecao() throws {
        let context = try TestDatabase.makeCleanContext()
        let defaults = makeDefaults()

        let session = try StoreSession.bootstrap(in: context, defaults: defaults)
        let stores = try context.fetch(FetchDescriptor<StoreProfile>())

        #expect(stores.count == 1)
        #expect(stores.first?.id == session.selectedStoreID)
        #expect(defaults.string(forKey: StoreSession.selectedStoreKey) == session.selectedStoreID.uuidString)
    }

    @Test func selecaoInvalidaVoltaParaLojaAtiva() throws {
        let context = try TestDatabase.makeCleanContext()
        let defaults = makeDefaults()
        defaults.set(UUID().uuidString, forKey: StoreSession.selectedStoreKey)
        let store = try StoreProfileService.create(name: "VHS Plus", in: context)

        let session = try StoreSession.bootstrap(in: context, defaults: defaults)

        #expect(session.selectedStoreID == store.id)
    }

    @Test func sessaoRecusaSelecionarLojaArquivada() throws {
        let context = try TestDatabase.makeCleanContext()
        let defaults = makeDefaults()
        let active = try StoreProfileService.create(name: "VHS Plus", in: context)
        let archived = StoreProfile(name: "Loja antiga", isArchived: true)
        context.insert(archived)
        let session = StoreSession(selectedStoreID: active.id, defaults: defaults)

        #expect(throws: StoreProfileError.archivedStore) {
            try session.select(archived)
        }
        #expect(session.selectedStoreID == active.id)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "TinyStockCoreTests.StoreSession"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
