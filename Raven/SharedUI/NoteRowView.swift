//
//  NoteRowView.swift
//  Raven
//
//  Created by Eldar Tutnjic on 24.07.25.
//

import RDatabaseManager
import SwiftUI

struct NoteRowView: View {
    let note: Note
    let onDelete: () -> Void
    
    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 4
        ) {
            HStack {
                Text(note.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Spacer()
                
                Menu {
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
            
            Text(note.content)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            Text(
                note.createdAt,
                style: .relative
            )
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color.white.opacity(0.5))
        .cornerRadius(
            6,
            corners: .allCorners
        )
    }
}
