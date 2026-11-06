//
//  KeyboardShortcutsView.swift
//  Raven
//
//  Reference window opened from Help ▸ Keyboard Shortcuts (⌘/).
//

import SwiftUI

struct KeyboardShortcutsView: View {
    private typealias S = DesignSystem.Shortcuts

    var body: some View {
        Form {
            Section(DesignSystem.Menu.sectionChats) {
                row(DesignSystem.Chats.newChatEllipsis, S.newChat.display, spoken: DesignSystem.Chats.newChat)
                row(DesignSystem.Conversation.searchChatsEllipsis, S.searchChats.display, spoken: DesignSystem.Conversation.searchChats)
                row(DesignSystem.Conversation.goToChat, S.chatRange)
                row(DesignSystem.Chats.renameChat, S.renameChat.display, spoken: DesignSystem.Chats.renameChatLabel)
                row(DesignSystem.Chats.deleteChat, S.deleteChat.display, spoken: DesignSystem.Chats.deleteChatLabel)
            }
            Section(DesignSystem.Menu.sectionConversation) {
                row(DesignSystem.Menu.sendFromField, S.returnKey)
                row(DesignSystem.Chat.send, S.sendQuestion.display)
                row(DesignSystem.Chat.cancelAnswer, S.cancelAnswer.display)
                row(DesignSystem.Chat.copyResponse, S.copyResponse.display)
                row(DesignSystem.Chat.clearHistory, S.clearHistory.display, spoken: DesignSystem.Chat.clearHistoryLabel)
            }
            Section(DesignSystem.Menu.sectionSources) {
                row(DesignSystem.Sources.addSources, S.addSources.display, spoken: DesignSystem.Sources.addSourcesLabel)
                row(DesignSystem.Menu.quickLookSelected, S.spaceKey)
                row(DesignSystem.Menu.removeSelected, S.deleteKey, spoken: DesignSystem.Menu.removeSelectedLabel)
            }
            Section(DesignSystem.Menu.sectionView) {
                row(DesignSystem.Menu.toggleSidebar, S.toggleSidebar)
                row(DesignSystem.Menu.toggleSources, S.toggleSources.display)
                row(DesignSystem.Menu.showMessageTimes, S.showMessageTimes.display)
                row(DesignSystem.Menu.keyboardShortcuts, S.keyboardShortcuts.display)
            }
            Section(DesignSystem.Menu.sectionDialogs) {
                row(DesignSystem.Menu.confirmDialog, S.returnKey)
                row(DesignSystem.Menu.cancelDialog, S.escapeKey)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: Constants.width, idealWidth: Constants.width, minHeight: Constants.minHeight)
        .accessibilityIdentifier("raven.keyboard-shortcuts")
    }

    /// `spoken` is the plain command name VoiceOver reads when `title` ends in an ellipsis.
    private func row(_ title: String, _ keys: String, spoken: String? = nil) -> some View {
        LabeledContent(title) {
            Text(keys)
                .font(.body.monospaced())
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken ?? title)
        .accessibilityValue(keys)
    }

    private enum Constants {
        static let width: CGFloat = 440
        static let minHeight: CGFloat = 520
    }
}
