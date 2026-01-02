//
//  ProjectRowView.swift
//  Raven
//
//  Created by Eldar Tutnjic on 24.07.25.
//

import RDatabaseManager
import SwiftUI

struct ProjectRowView: View {
    let project: Project
    let onDelete: () -> Void
    let onRename: () -> Void

    var body: some View {
        HStack {
            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                Text(project.name)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)

                Text(
                    project.createdAt,
                    style: .date
                )
                    .font(.caption)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Chat: \(project.name), created \(project.createdAt.formatted(date: .abbreviated, time: .omitted))")
            .accessibilityHint("Double tap to select this chat")

            Spacer()

            Menu {
                Button {
                    onRename()
                } label: {
                    Text("Rename")
                }
                .accessibilityLabel("Rename \(project.name)")
                .accessibilityHint("Renames this chat")
                .accessibilityInputLabels(["Rename", "Edit Name", "Change Name"])

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Text("Delete")
                }
                .accessibilityLabel("Delete \(project.name)")
                .accessibilityHint("Deletes this chat")
                .accessibilityInputLabels(["Delete", "Remove", "Trash"])

            } label: {
                Image(systemName: "ellipsis")
            }
            .menuStyle(.borderlessButton)
            .accessibilityLabel("Chat Actions for \(project.name)")
            .accessibilityHint("Opens menu with rename and delete options")
            .accessibilityInputLabels(["Chat Actions", "Options", "More", "Menu"])
        }
        .padding(.vertical, 4)
        .accessibilityIdentifier("projectRow_\(String(describing: project.id))")
    }
}
