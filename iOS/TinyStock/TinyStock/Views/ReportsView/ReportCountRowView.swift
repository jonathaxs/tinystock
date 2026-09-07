// Proposito: Mostrar a quantidade de eventos operacionais ocorridos no periodo.
// Created by Jonathas Motta (@jonathaxs) on 2026-09-06.

import SwiftUI

struct ReportCountRowView: View {
    let title: String
    let count: Int
    let symbolName: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbolName)
                .foregroundStyle(tint)
                .frame(width: 24)
                .accessibilityHidden(true)
            Text(title).font(.headline)
            Spacer(minLength: 12)
            Text(count, format: .number)
                .font(.headline)
                .monospacedDigit()
        }
        .padding(16)
        .accessibilityElement(children: .combine)
    }
}
