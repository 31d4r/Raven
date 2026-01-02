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
                    .accessibilityLabel("New Chat")
                    .accessibilityHint("Creates a new chat")
                    .accessibilityIdentifier("newChatButton")
                }
            }
            .sheet(
                isPresented: feature.binding(for: \.showingNewProjectAlert),
                content: {
                    createNewProjectView()
                        .presentationDetents([.fraction(0.25)])
                }
            )
            .alert("Rename Chat", isPresented: feature.binding(for: \.showingRenameAlert)) {
                TextField("Chat name", text: feature.binding(for: \.renameProjectName))
                    .accessibilityLabel("Chat Name")
                    .accessibilityHint("Enter a new name for the chat")
                    .accessibilityIdentifier("renameChatTextField")
                
                Button {
                    feature.send(.hideRenameAlert)
                } label: {
                    Text("Cancel")
                }
                .accessibilityLabel("Cancel")

                Button {
                    feature.send(.renameProject(feature.value(\.renameProjectName)))
                } label: {
                    Text("Rename")
                }
                .disabled(
                    feature.value(\.renameProjectName).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
                .accessibilityLabel("Rename")
                .accessibilityHint("Renames the chat to the entered name")
   
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
                    .accessibilityLabel("Loading chats")
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
                .accessibilityHidden(true)
            
            Text("No Chats Yet")
                .font(.title2)
                .fontWeight(.medium)
                .accessibilityAddTraits(.isHeader)
                .supportsDynamicType()
            
            Text("Create your first chat to get started")
                .foregroundColor(.secondary)
                .accessibilityLabel("Create your first chat to get started")
            
            Button {
                feature.send(.showNewProjectAlert)
            } label: {
                Text("Create Chat")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Create Chat")
            .accessibilityHint("Opens a dialog to create a new chat")
            .accessibilityIdentifier("createChatButton")
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .accessibilityElement(children: .combine)
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
                .accessibilityLabel("Chat: \(project.name)")
                .accessibilityHint("Double tap to select this chat")
        }
        .listStyle(.sidebar)
        .accessibilityLabel("Chats List")
        .accessibilityIdentifier("chatsList")
    }
    
    func createNewProjectView() -> some View {
        VStack {
            HStack {
                Text("New Chat")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                    .supportsDynamicType()
                
                Spacer()
            }
            
            Divider()
                .accessibilityHidden(true)
            
            HStack {
                Text("Name")
                    .accessibilityLabel("Chat Name Label")
                
                TextField(
                    "Chat name",
                    text: feature.binding(
                        for: \.newProjectName
                    )
                )
                .accessibilityLabel("Chat Name")
                .accessibilityHint("Enter a name for the new chat")
                .accessibilityValue(feature.value(\.newProjectName))
                .accessibilityIdentifier("newChatNameTextField")
            }
            
            .padding(.vertical)
            
            HStack {
                Spacer()
                
                Button {
                    feature.send(.hideNewProjectAlert)
                } label: {
                    Text("Cancel")
                }
                .accessibilityLabel("Cancel")
                .accessibilityHint("Cancels creating a new chat")
                .accessibilityIdentifier("cancelNewChatButton")
                
                Button {
                    feature.send(.createProject(feature.value(\.newProjectName)))
                } label: {
                    Text("Create")
                }
                .disabled(
                    feature.value(\.newProjectName).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
                .accessibilityLabel("Create Chat")
                .accessibilityHint("Creates a new chat with the entered name")
                .accessibilityIdentifier("createNewChatButton")
            }
        }
        .padding()
        .accessibilityElement(children: .contain)
    }
}
