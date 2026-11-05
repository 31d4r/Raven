//
//  ButtonView.swift
//  Raven
//
//  Created by Eldar Tutnjic on 24.07.25.
//

import SwiftUI

/// Native bordered button with an SF Symbol. Prefer a plain `Button` with a
/// system style; this wrapper stays for call sites that want the shorthand.
struct ButtonView: View {
    var systemImageName: String
    var buttonText: String
    var action: (() -> Void)? = nil
    var accessibilityLabel: String? = nil
    var accessibilityHint: String? = nil
    var accessibilityIdentifier: String? = nil

    var body: some View {
        Button {
            action?()
        } label: {
            Label(buttonText, systemImage: systemImageName)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .accessibilityLabel(accessibilityLabel ?? buttonText)
        .if(accessibilityHint != nil) { view in
            view.accessibilityHint(accessibilityHint ?? "")
        }
        .if(accessibilityIdentifier != nil) { view in
            view.accessibilityIdentifier(accessibilityIdentifier ?? "")
        }
    }
}
