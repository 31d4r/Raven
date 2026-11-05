//
//  StatusBanner.swift
//  Raven
//
//  Success banner with next steps. Stays on Mac until dismissed; on iOS it
//  dismisses after 8 seconds unless VoiceOver runs or the person touched it.
//

import SwiftUI

enum StatusBannerPolicy {
    static func autoDismissDelay(isVoiceOverRunning: Bool, hasInteracted: Bool, offersChoice: Bool) -> Duration? {
        #if os(macOS)
        return nil
        #else
        guard !isVoiceOverRunning, !hasInteracted, !offersChoice else { return nil }
        return DesignSystem.Motion.bannerAutoDismissDelay
        #endif
    }
}

struct StatusBanner<Actions: View>: View {
    let message: String
    let onDismiss: () -> Void
    @ViewBuilder var actions: () -> Actions

    @Environment(\.accessibilityVoiceOverEnabled) private var isVoiceOverRunning
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var hasInteracted = false

    var body: some View {
        content
            .padding(.horizontal, DesignSystem.Spacing.medium)
            .padding(.vertical, DesignSystem.Spacing.small)
            .background(reduceTransparency ? AnyShapeStyle(.background) : AnyShapeStyle(.bar))
            .overlay(alignment: .top) { Divider() }
            .simultaneousGesture(TapGesture().onEnded { hasInteracted = true })
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("raven.status-banner")
            .onAppear {
                AccessibilityHelper.announce(message)
            }
            .task(id: hasInteracted) {
                guard let delay = StatusBannerPolicy.autoDismissDelay(
                    isVoiceOverRunning: isVoiceOverRunning,
                    hasInteracted: hasInteracted,
                    offersChoice: false
                ) else { return }
                try? await Task.sleep(for: delay)
                guard !Task.isCancelled else { return }
                onDismiss()
            }
    }

    @ViewBuilder
    private var content: some View {
        #if os(macOS)
        HStack(spacing: DesignSystem.Spacing.small) {
            icon
            messageText
            Spacer(minLength: DesignSystem.Spacing.small)
            actions()
            dismissButton
        }
        #else
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            HStack(alignment: .top, spacing: DesignSystem.Spacing.small) {
                icon
                messageText
                Spacer(minLength: DesignSystem.Spacing.small)
                dismissButton
            }
            ViewThatFits {
                HStack { actions() }
                VStack { actions().frame(maxWidth: .infinity) }
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        #endif
    }

    private var icon: some View {
        Image(systemName: DesignSystem.Icons.success)
            .foregroundStyle(.green)
            .imageScale(.large)
            .accessibilityHidden(true)
    }

    private var messageText: some View {
        Text(message)
            .font(.callout)
            .lineLimit(3)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var dismissButton: some View {
        Button(action: onDismiss) {
            Label(DesignSystem.Common.dismiss, systemImage: DesignSystem.Icons.dismiss)
                .labelStyle(.iconOnly)
                .frame(minWidth: Constants.dismissSize, minHeight: Constants.dismissSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .help(DesignSystem.Common.dismiss)
        .accessibilityInputLabels(DesignSystem.VoiceControl.dismiss)
    }

    private enum Constants {
        #if os(macOS)
        static var dismissSize: CGFloat { 28 }
        #else
        static var dismissSize: CGFloat { DesignSystem.Layout.minTouchTarget }
        #endif
    }
}

extension StatusBanner where Actions == EmptyView {
    init(message: String, onDismiss: @escaping () -> Void) {
        self.init(message: message, onDismiss: onDismiss) { EmptyView() }
    }
}
