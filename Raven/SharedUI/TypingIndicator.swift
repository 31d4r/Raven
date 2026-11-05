//
//  TypingIndicator.swift
//  Raven
//
//  Three pulsing dots in the chat color with “Thinking…” under them.
//  Holds still when Reduce Motion is on.
//

import SwiftUI

struct TypingIndicator: View {
    let color: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var dotSize = DesignSystem.Conversation.dotSize

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            TimelineView(.animation(paused: reduceMotion)) { context in
                HStack(spacing: DesignSystem.Conversation.dotSpacing) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(color)
                            .frame(width: dotSize, height: dotSize)
                            .opacity(opacity(for: index, at: context.date))
                            .offset(y: reduceMotion ? 0 : lift(for: index, at: context.date))
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Conversation.bubbleHorizontalPadding)
            .padding(.vertical, DesignSystem.Conversation.bubbleVerticalPadding + DesignSystem.Spacing.xSmall)
            .background {
                RoundedRectangle(cornerRadius: DesignSystem.Conversation.bubbleRadius, style: .continuous)
                    .fill(DesignSystem.ConversationColors.assistantBubble)
            }

            Text(DesignSystem.Conversation.thinking)
                .font(.callout)
                .foregroundStyle(DesignSystem.Colors.supporting)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(DesignSystem.Conversation.thinkingAccessibility)
        .accessibilityAddTraits(.updatesFrequently)
        .accessibilityIdentifier("thinkingIndicator")
    }

    private func phase(for index: Int, at date: Date) -> Double {
        let cycle = DesignSystem.Conversation.dotCycle
        let time = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: cycle) / cycle
        return (sin((time - Double(index) * 0.18) * 2 * .pi) + 1) / 2
    }

    private func opacity(for index: Int, at date: Date) -> Double {
        if reduceMotion { return [0.45, 0.7, 1][index] }
        return 0.35 + 0.65 * phase(for: index, at: date)
    }

    private func lift(for index: Int, at date: Date) -> CGFloat {
        -2.5 * phase(for: index, at: date)
    }
}
