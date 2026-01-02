//
//  ButtonView.swift
//  Raven
//
//  Created by Eldar Tutnjic on 24.07.25.
//

import SwiftUI

struct ButtonView: View {
    var systemImageName: String
    var buttonText: String
    var action: (() -> Void)? = nil
    var accessibilityLabel: String? = nil
    var accessibilityHint: String? = nil
    var accessibilityIdentifier: String? = nil

    var body: some View {
        VStack(spacing: 10) {
            Button {
                action?()
            } label: {
                HStack {
                    Image(systemName: systemImageName)
                        .accessibilityHidden(true)
                    Text(buttonText)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                #if os(iOS)
                .frame(minHeight: 44)
                #endif
                .background(.gray.opacity(0.1))
                .cornerRadius(
                    8,
                    corners: .allCorners
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibilityLabel ?? buttonText)
            .if(accessibilityHint != nil) { view in
                view.accessibilityHint(accessibilityHint ?? "")
            }
            .if(accessibilityIdentifier != nil) { view in
                view.accessibilityIdentifier(accessibilityIdentifier ?? "")
            }
        }
        .padding(.horizontal)
    }
}
