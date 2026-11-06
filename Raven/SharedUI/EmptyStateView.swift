//
//  EmptyStateView.swift
//  Raven
//
//  Brand or symbol image, title, one-sentence message and a stack of
//  large buttons with exactly one prominent start.
//

import SwiftUI

struct EmptyStateView<Actions: View>: View {
    enum Artwork {
        case brand
        case symbol(String)
    }

    let artwork: Artwork
    let title: String
    let message: String
    var footnote: String?
    var isTargeted = false
    @ViewBuilder var actions: () -> Actions

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var imageSize = DesignSystem.Layout.emptyStateImageSize

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.medium) {
                artworkView
                    .scaleEffect(isTargeted && !reduceMotion ? Constants.targetedScale : 1)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text(message)
                    .font(.body)
                    .foregroundStyle(DesignSystem.Colors.supporting)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: DesignSystem.Layout.emptyStateMessageWidth)

                VStack(spacing: DesignSystem.Spacing.small) {
                    actions()
                        .frame(maxWidth: .infinity)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                .controlSize(.large)
                .frame(maxWidth: DesignSystem.Layout.emptyStateButtonWidth)
                .padding(.top, DesignSystem.Spacing.small)

                if let footnote {
                    Text(footnote)
                        .font(.footnote)
                        .foregroundStyle(DesignSystem.Colors.supporting)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: DesignSystem.Layout.emptyStateMessageWidth)
                }
            }
            .padding(Constants.padding)
            .frame(maxWidth: .infinity)
            .containerRelativeFrame(.vertical, alignment: .center)
            .animation(reduceMotion ? nil : .snappy(duration: 0.2), value: isTargeted)
        }
        .scrollBounceBehavior(.basedOnSize)
        .accessibilityIdentifier("raven.empty-state")
    }

    @ViewBuilder
    private var artworkView: some View {
        switch artwork {
        case .brand:
            Image(.ravenIcon)
                .resizable()
                .scaledToFit()
                .frame(width: imageSize, height: imageSize)
        case .symbol(let name):
            Image(systemName: name)
                .font(.largeTitle)
                .imageScale(.large)
                .foregroundStyle(isTargeted ? AnyShapeStyle(.tint) : AnyShapeStyle(.tertiary))
        }
    }

    private enum Constants {
        static var targetedScale: CGFloat { 1.08 }
        #if os(macOS)
        static var padding: CGFloat { 40 }
        #else
        static var padding: CGFloat { DesignSystem.Spacing.medium }
        #endif
    }
}

extension EmptyStateView where Actions == EmptyView {
    init(artwork: Artwork, title: String, message: String, footnote: String? = nil, isTargeted: Bool = false) {
        self.init(artwork: artwork, title: title, message: message, footnote: footnote, isTargeted: isTargeted) { EmptyView() }
    }
}
