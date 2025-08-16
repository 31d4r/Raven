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

    var body: some View {
        VStack(spacing: 10) {
            Button {
                action?()
            } label: {
                HStack {
                    Image(systemName: systemImageName)
                    Text(buttonText)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.gray.opacity(0.1))
                .cornerRadius(
                    8,
                    corners: .allCorners
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
    }
}
