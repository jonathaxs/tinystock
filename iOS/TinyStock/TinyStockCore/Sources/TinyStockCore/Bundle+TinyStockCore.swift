// ⌘
//  TinyStockCore/Bundle+TinyStockCore.swift
//
//  Propósito: Expõe o resource bundle do TinyStockCore pros app targets (iPhone, Watch),
//             pra que `String(localized: "x", bundle: .tinyStockCore)` funcione fora do package.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-08-07.
// ⌘

import Foundation

public extension Bundle {
    /// Resource bundle do package TinyStockCore.
    /// Usar em call sites de `String(localized:bundle:)` fora do código do package,
    /// pros recursos (Localizable.strings) serem encontrados.
    ///
    /// No watchOS, retorna o sub-bundle `.lproj` do idioma escolhido no iPhone
    /// (sincronizado via WatchConnectivity em `app.preferredLanguage`), porque o
    /// watchOS não tem idioma por app e não dá pra trocar o locale do processo em runtime.
    static var tinyStockCore: Bundle {
        #if os(watchOS)
        if let lang = UserDefaults.standard.string(forKey: "app.preferredLanguage"),
           let path = Bundle.module.path(forResource: lang, ofType: "lproj"),
           let langBundle = Bundle(path: path) {
            return langBundle
        }
        #endif
        return .module
    }
}
