//
//  RightSidebarView.swift
//  Parrot
//
//  Created by Eldar Tutnjic on 24.07.25.
//

import SwiftUI

struct RightSidebarView: View {
    let selectedProject: Project?
    @State var feature = RightSidebarFeature()
    
    var body: some View {
        content()
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .topLeading
            )
            .background(Color(NSColor.controlBackgroundColor))
            .sheet(isPresented: feature.binding(for: \.showingCustomization)) {
                PodcastCustomizationView(feature: feature)
            }
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
            audioSummaryView()
            podcastGeneratorView()
            
            Spacer()
            
            notesView()
        }
    }
    
    func audioSummaryView() -> some View {
        VStack(
            alignment: .leading,
            spacing: 15
        ) {
            HStack {
                Image(systemName: "speaker.wave.2")
                    .foregroundColor(.blue)
                
                Text("Audio Summary")
                    .font(.headline)
                
                Spacer()
                
                Button {} label: {
                    Image(systemName: "info.circle")
                }
                .buttonStyle(.plain)
            }
            
            Text("Generate audio summaries in multiple languages and formats.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button {} label: {
                Text("Learn More")
            }
            .foregroundColor(.blue)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(
            12,
            corners: .allCorners
        )
        .padding(.horizontal)
        .padding(.vertical)
    }
    
    func podcastGeneratorView() -> some View {
        VStack(
            alignment: .leading,
            spacing: 15
        ) {
            HStack {
                Image(systemName: "person.2")
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading) {
                    Text("Podcast Generator")
                        .font(.headline)
                    
                    Text("Two Hosts Discussion")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            if feature.value(\.isGenerating) {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    
                    Text("Generating podcast...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !feature.value(\.generatedPodcast).isEmpty {
                podcastPreview()
            }
            
            HStack {
                Button {
                    feature.send(.showCustomization)
                } label: {
                    Text("Customize")
                }
                .buttonStyle(.bordered)
                .disabled(selectedProject == nil)
                
                Spacer()
                
                Button {
                    if let project = selectedProject {
                        feature.send(.generatePodcast(project))
                    }
                } label: {
                    Text("Generate")
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    selectedProject == nil || feature.value(\.isGenerating)
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8, corners: .allCorners)
        .padding(.horizontal)
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
        .background(Color.gray.opacity(0.05))
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
    
    func podcastPreview() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Generated Podcast")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button {
                    feature.send(.playPodcast)
                } label: {
                    Image(
                        systemName: feature.value(\.isPlaying) ? "pause.circle.fill" : "play.circle.fill"
                    )
                    .font(.title2)
                    .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
            
            ScrollView {
                Text(feature.value(\.generatedPodcast))
                    .font(.caption)
                    .padding(8)
                    .background(Color.white.opacity(0.5))
                    .cornerRadius(6)
            }
            .frame(maxHeight: 120)
        }
    }
}
