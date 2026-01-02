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
                    .accessibilityLabel("Created \(project.createdAt.formatted(date: .abbreviated, time: .omitted))")
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

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Text("Delete")
                }
                .accessibilityLabel("Delete \(project.name)")
                .accessibilityHint("Deletes this chat")

            } label: {
                Image(systemName: "ellipsis")
            }
            .menuStyle(.borderlessButton)
            .accessibilityLabel("Chat Actions")
            .accessibilityHint("Opens menu with actions for \(project.name)")
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Chat: \(project.name), created \(project.createdAt.formatted(date: .abbreviated, time: .omitted))")
        .accessibilityIdentifier("projectRow_\(String(describing: project.id))")
    }
}
