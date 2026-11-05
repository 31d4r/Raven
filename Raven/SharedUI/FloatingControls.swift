//
//  FloatingControls.swift
//  Raven
//
//  Round glass buttons and capsules that float over scrolling content.
//  With Reduce Transparency they become solid, outlined surfaces.
//

import SwiftUI

private struct FloatingSurface<S: Shape>: ViewModifier {
    let shape: S
    var tint: Color?
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        if reduceTransparency {
            content
                .background(shape.fill(tint ?? DesignSystem.ConversationColors.solidSurface))
                .overlay(shape.stroke(contrast == .increased ? Color.primary : DesignSystem.ConversationColors.composerBorder, lineWidth: 1))
        } else {
            content
                .glassEffect(tint.map { Glass.regular.tint($0).interactive() } ?? Glass.regular.interactive(), in: shape)
                .overlay {
                    if contrast == .increased {
                        shape.stroke(Color.primary, lineWidth: 1)
                    }
                }
        }
    }
}

extension View {
    /// Liquid Glass in the given shape, or a solid fill under Reduce Transparency.
    func floatingSurface<S: Shape>(in shape: S, tint: Color? = nil) -> some View {
        modifier(FloatingSurface(shape: shape, tint: tint))
    }
}

/// Symbol in a round floating button, sized for touch.
struct FloatingIcon: View {
    let systemImage: String
    @ScaledMetric(relativeTo: .body) private var size = DesignSystem.Conversation.floatingButtonSize

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.4, weight: .semibold))
            .foregroundStyle(.primary)
            .frame(width: size, height: size)
            .contentShape(Circle())
            .floatingSurface(in: Circle())
    }
}

/// Soft fade behind floating top/bottom bars so content scrolling under them
/// stays legible. Solid when Reduce Transparency is on.
struct EdgeFade: View {
    let edge: VerticalEdge

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private var start: UnitPoint { edge == .top ? .top : .bottom }
    private var end: UnitPoint { edge == .top ? .bottom : .top }

    var body: some View {
        let background = DesignSystem.ConversationColors.listBackground
        Group {
            if reduceTransparency {
                background
            } else {
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .mask(LinearGradient(colors: [.black, .black, .clear], startPoint: start, endPoint: end))
                    LinearGradient(
                        stops: [
                            .init(color: background.opacity(0.9), location: 0),
                            .init(color: background.opacity(0.6), location: 0.6),
                            .init(color: background.opacity(0), location: 1)
                        ],
                        startPoint: start,
                        endPoint: end
                    )
                }
                .padding(edge == .top ? .bottom : .top, -DesignSystem.Conversation.headerFadeHeight)
            }
        }
        .ignoresSafeArea(edges: edge == .top ? .top : .bottom)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
