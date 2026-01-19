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
                    .supportsDynamicType()

                Text(
                    project.createdAt,
                    style: .date
                )
                    .font(.caption)
                    .supportsDynamicType()
            }

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
                    .accessibilityHidden(true)
            }
            .menuStyle(.borderlessButton)
            .accessibilityLabel("Chat Actions for \(project.name)")
            .accessibilityHint("Opens menu with rename and delete options")
            .accessibilityInputLabels(["Chat Actions", "Options", "More", "Menu"])
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Chat: \(project.name), created \(project.createdAt.formatted(date: .abbreviated, time: .omitted))")
        .accessibilityIdentifier("projectRow_\(String(describing: project.id))")
    }
}
