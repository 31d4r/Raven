//
//  ProjectsView.swift
//  Raven
//
//  Created by Eldar Tutnjic on 24.07.25.
//

import RDatabaseManager
import SwiftUI

struct ProjectsView: View {
    @Environment(ProjectsFeature.self) var feature
    @Binding var selectedProject: Project?

    init(selectedProject: Binding<Project?>) {
        self._selectedProject = selectedProject
    }
    
    var body: some View {
        content()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        feature.send(.showNewProjectAlert)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(
                isPresented: feature.binding(for: \.showingNewProjectAlert),
                content: {
                    createNewProjectView()
                }
            )
            .alert("Rename Chat", isPresented: feature.binding(for: \.showingRenameAlert)) {
                TextField("Chat name", text: feature.binding(for: \.renameProjectName))
                
                Button {
                    feature.send(.hideRenameAlert)
                } label: {
                    Text("Cancel")
                }

                Button {
                    feature.send(.renameProject(feature.value(\.renameProjectName)))
                } label: {
                    Text("Rename")
                }
                .disabled(
                    feature.value(\.renameProjectName).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
   
            } message: {
                Text("Enter a new name for the chat")
            }
            .task {
                feature.send(.loadProjects)
            }
            .onChange(of: feature.value(\.selectedProject)) { _, newProject in
                selectedProject = newProject
            }
    }
    
    func content() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if feature.value(\.isLoading) {
                ProgressView("Loading chats...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if feature.value(\.projects).isEmpty {
                emptyStateView()
            } else {
                projectsList()
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
    }
    
    func emptyStateView() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "message")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Chats Yet")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Create your first chat to get started")
                .foregroundColor(.secondary)
            
            Button {
                feature.send(.showNewProjectAlert)
            } label: {
                Text("Create Chat")
            }
            .buttonStyle(.borderless)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }
    
    func projectsList() -> some View {
        List(
            feature.value(\.projects),
            id: \.id,
            selection: feature.binding(for: \.selectedProject)
        ) { project in
            ProjectRowView(project: project,
                           onDelete: { feature.send(.deleteProject(project)) },
                           onRename: { feature.send(.showRenameAlert(project)) })
                .tag(project)
        }
        .listStyle(.sidebar)
    }
    
    func createNewProjectView() -> some View {
        VStack {
            HStack {
                Text("New Chat")
                
                Spacer()
            }
            
            Divider()
            
            HStack {
                Text("Name")
                
                TextField(
                    "Chat name",
                    text: feature.binding(
                        for: \.newProjectName
                    )
                )
            }
            
            .padding(.vertical)
            
            HStack {
                Spacer()
                
                Button {
                    feature.send(.hideNewProjectAlert)
                } label: {
                    Text("Cancel")
                }
                
                Button {
                    feature.send(.createProject(feature.value(\.newProjectName)))
                } label: {
                    Text("Create")
                }
                .disabled(
                    feature.value(\.newProjectName).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
            }
        }
        .padding()
    }
}
