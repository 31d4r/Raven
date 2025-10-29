//
//  RightSidebarView.swift
//  Raven
//
//  Created by Eldar Tutnjic on 24.07.25.
//

import RDatabaseManager
import SwiftUI

struct RightSidebarView: View {
    let selectedProject: Project?
    @Environment(RightSidebarFeature.self) var feature
    
    var body: some View {
        content()
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .topLeading
            )
            .background(Color(NSColor.controlBackgroundColor))
            .sheet(isPresented: feature.binding(for: \.showingNewNoteSheet)) {
                NewNoteView(feature: feature, project: selectedProject)
            }
            .onChange(of: selectedProject?.id) { _, _ in
                if let project = selectedProject {
                    feature.send(.loadNotes(project))
                }
            }
            .task {
                if let project = selectedProject {
                    feature.send(.loadNotes(project))
                }
            }
    }
    
    func content() -> some View {
        VStack(
            alignment: .leading,
            spacing: 20
        ) {
            notesView()
        }
    }
    
    func notesView() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "note.text")
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text("Notes")
                        .font(.headline)
                    
                    if selectedProject == nil {
                        Text("Select a project to view notes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(feature.value(\.notes).count) notes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if selectedProject != nil {
                    Button {
                        feature.send(.showNewNoteSheet)
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            if feature.value(\.isLoadingNotes) {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading notes...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if feature.value(\.notes).isEmpty && selectedProject != nil {
                Text("No notes yet. Create your first note!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                notesListView()
            }
        }
        .padding()
    }
    
    func notesListView() -> some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(feature.value(\.notes), id: \.id) { note in
                    NoteRowView(note: note) {
                        feature.send(.deleteNote(note))
                    }
                }
            }
        }
        .frame(maxHeight: 200)
    }
}
