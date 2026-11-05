//
//  RowAction.swift
//  Raven
//
//  One list of row commands drawn as a context menu and as VoiceOver actions.
//

import SwiftUI

struct RowAction: Identifiable {
    let id: String
    let title: String
    /// Plain name for VoiceOver when `title` ends in an ellipsis on macOS.
    var spokenTitle: String?
    let systemImage: String
    var role: ButtonRole?
    var help: String?
    var startsGroup = false
    let perform: () -> Void
}

struct RowActionsMenu: View {
    let actions: [RowAction]

    var body: some View {
        ForEach(actions) { action in
            if action.startsGroup {
                Divider()
            }
            Button(role: action.role, action: action.perform) {
                Label(action.title, systemImage: action.systemImage)
            }
            .help(action.help ?? action.title)
        }
    }
}

private struct RowAccessibilityActions: ViewModifier {
    let actions: [RowAction]

    func body(content: Content) -> some View {
        content.accessibilityActions {
            ForEach(actions) { action in
                Button(action.spokenTitle ?? action.title, action: action.perform)
            }
        }
    }
}

extension View {
    func rowAccessibilityActions(_ actions: [RowAction]) -> some View {
        modifier(RowAccessibilityActions(actions: actions))
    }
}
