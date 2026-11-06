//
//  ActivityBar.swift
//  Raven
//
//  Non-blocking progress shown in a bottom safe-area inset.
//

import SwiftUI

struct ActivityBar: View {
    let message: String
    var onCancel: (() -> Void)?
    /// Plain text for VoiceOver when `message` ends in a progress ellipsis.
    var spokenMessage: String?

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            ProgressView()
                .controlSize(.small)
                .accessibilityHidden(true)

            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .accessibilityLabel(spokenMessage ?? message)
                .accessibilityAddTraits(.updatesFrequently)

            Spacer(minLength: DesignSystem.Spacing.small)

            if let onCancel {
                Button(DesignSystem.Common.cancel, action: onCancel)
                    .help(DesignSystem.Help.withShortcut(DesignSystem.Chat.cancelAnswer, DesignSystem.Shortcuts.cancelAnswer.display))
                    .accessibilityLabel(DesignSystem.Chat.cancelAnswer)
                    .accessibilityInputLabels(DesignSystem.VoiceControl.cancel)
                    .accessibilityIdentifier("cancelAnswerButton")
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, DesignSystem.Spacing.small)
        .frame(minHeight: DesignSystem.Layout.minTouchTarget)
        .background(reduceTransparency ? AnyShapeStyle(.background) : AnyShapeStyle(.bar))
        .overlay(alignment: .top) { Divider() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("raven.activity-bar")
    }
}
