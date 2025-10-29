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
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.headline)

                Text(project.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Menu {
                Button {
                    onRename()
                } label: {
                    Text("Rename")
                }

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Text("Delete")
                }

            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
            .menuStyle(.borderlessButton)
        }
        .padding(.vertical, 4)
    }
}
