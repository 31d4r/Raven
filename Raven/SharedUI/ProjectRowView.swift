//
//  ProjectRowView.swift
//  Raven
//
//  Created by Eldar Tutnjic on 24.07.25.
//

import RDatabaseManager
import SwiftUI

/// One chat in the sidebar. Rename and delete live in the list’s context
/// menu, swipe actions and VoiceOver actions.
struct ProjectRowView: View {
    let project: Project

    private var createdDate: String {
        project.createdAt.formatted(date: .abbreviated, time: .omitted)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.labelToMeta) {
            Text(project.name)
                .font(.body)
                .lineLimit(1)

            Text(createdDate)
                .font(.caption)
                .foregroundStyle(DesignSystem.Colors.supporting)
                .lineLimit(1)
        }
        .padding(.vertical, DesignSystem.Spacing.labelToMeta)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(DesignSystem.Chats.rowAccessibilityLabel(project.name, created: createdDate))
        .accessibilityIdentifier("projectRow_\(String(describing: project.id))")
    }
}

/// Mac sidebar row: chat avatar, bold name and a gray one-line preview of
/// the last message. The open chat gets a soft rounded highlight.
struct ChatSidebarRow: View {
    let project: Project
    let preview: String?
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false
    @Environment(\.colorSchemeContrast) private var contrast

    private var createdDate: String {
        project.createdAt.formatted(date: .abbreviated, time: .omitted)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Conversation.sidebarAvatarToText) {
                ChatAvatar(
                    appearance: ChatAppearanceStore.shared.appearance(for: project),
                    size: DesignSystem.Conversation.sidebarAvatarSize
                )
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.labelToMeta) {
                    Text(project.name)
                        .font(.body.weight(.semibold))
                        .lineLimit(1)
                    Text(preview ?? DesignSystem.Conversation.noPreview)
                        .font(.subheadline)
                        .foregroundStyle(DesignSystem.Colors.supporting)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, DesignSystem.Conversation.sidebarRowHorizontalPadding)
            .padding(.vertical, DesignSystem.Conversation.sidebarRowVerticalPadding)
            .background {
                RoundedRectangle(cornerRadius: DesignSystem.Conversation.sidebarRowRadius, style: .continuous)
                    .fill(rowFill)
            }
            .overlay {
                if isSelected && contrast == .increased {
                    RoundedRectangle(cornerRadius: DesignSystem.Conversation.sidebarRowRadius, style: .continuous)
                        .strokeBorder(Color.primary, lineWidth: 1)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: DesignSystem.Conversation.sidebarRowRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(DesignSystem.Chats.rowAccessibilityLabel(project.name, created: createdDate))
        .accessibilityValue(preview ?? DesignSystem.Conversation.noPreview)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("projectRow_\(String(describing: project.id))")
    }

    private var rowFill: Color {
        if isSelected { return DesignSystem.ConversationColors.selectedRow }
        if isHovered { return DesignSystem.ConversationColors.hoveredRow }
        return .clear
    }
}

/// iPhone chat list row: large avatar, bold name with the last message
/// time on the right, and a one-line gray preview.
struct ChatListRow: View {
    let project: Project
    let preview: String?
    let lastMessageDate: Date?

    private var createdDate: String {
        project.createdAt.formatted(date: .abbreviated, time: .omitted)
    }

    var body: some View {
        HStack(spacing: DesignSystem.Conversation.listAvatarToText) {
            ChatAvatar(
                appearance: ChatAppearanceStore.shared.appearance(for: project),
                size: DesignSystem.Conversation.listAvatarSize
            )
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.labelToMeta) {
                HStack(alignment: .firstTextBaseline, spacing: DesignSystem.Spacing.small) {
                    Text(project.name)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    if let lastMessageDate {
                        Text(Self.shortDate(lastMessageDate))
                            .font(.subheadline)
                            .monospacedDigit()
                            .foregroundStyle(DesignSystem.Colors.supporting)
                            .lineLimit(1)
                            .layoutPriority(1)
                    }
                }
                Text(preview ?? DesignSystem.Conversation.noPreview)
                    .font(.subheadline)
                    .foregroundStyle(DesignSystem.Colors.supporting)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, DesignSystem.Conversation.listRowVerticalPadding)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(DesignSystem.Chats.rowAccessibilityLabel(project.name, created: createdDate))
        .accessibilityValue(preview ?? DesignSystem.Conversation.noPreview)
        .accessibilityIdentifier("chatRow")
    }

    /// Time today, weekday this week, otherwise a short date.
    static func shortDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return date.formatted(date: .omitted, time: .shortened)
        }
        if let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: .now)).day, days < 7 {
            return date.formatted(.dateTime.weekday(.abbreviated))
        }
        return date.formatted(.dateTime.day().month(.abbreviated))
    }
}
