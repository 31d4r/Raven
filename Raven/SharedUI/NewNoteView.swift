//
//  NewNoteView.swift
//  Raven
//
//  Created by Eldar Tutnjic on 24.07.25.
//

import RDatabaseManager
import SwiftUI

struct NewNoteView: View {
    var feature: RightSidebarView.RightSidebarFeature
    let project: Project?
    
    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 20
        ) {
            Text("New Note")
                .font(.title2)
                .fontWeight(.medium)
            
            VStack(
                alignment: .leading,
                spacing: 8
            ) {
                Text("Title")
                    .font(.headline)
                
                TextField(
                    "Enter note title",
                    text: feature.binding(for: \.newNoteTitle)
                )
                .textFieldStyle(.roundedBorder)
            }
            
            VStack(
                alignment: .leading,
                spacing: 8
            ) {
                Text("Content")
                    .font(.headline)
                
                TextEditor(text: feature.binding(for: \.newNoteContent))
                    .frame(minHeight: 120)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(
                        8,
                        corners: .allCorners
                    )
            }
            
            Spacer()
            
            HStack {
                Button {
                    feature.send(.hideNewNoteSheet)
                } label: {
                    Text("Cancel")
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button {
                    if let project = project {
                        feature.send(.createNote(project))
                    }
                } label: {
                    Text("Save")
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    feature.value(\.newNoteTitle).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        feature.value(\.newNoteContent).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
            }
        }
        .padding()
        .frame(
            width: 400,
            height: 350
        )
    }
}
