//
//  ProjectsView.swift
//  Parrot
//
//  Created by Eldar Tutnjic on 24.07.25.
//

import SwiftUI

struct ProjectsView: View {
    @State var feature = ProjectsFeature()
    @Binding var selectedProject: Project?

    init(selectedProject: Binding<Project?>) {
        self._selectedProject = selectedProject
    }
    
    var body: some View {
        content()
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        feature.send(.showNewProjectAlert)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert(
                "New Project",
                isPresented: feature.binding(
                    for: \.showingNewProjectAlert
                )
            ) {
                TextField("Project name", text: feature.binding(for: \.newProjectName))
                
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
   
            } message: {
                Text("Enter a name for your new project")
            }
            .alert("Rename Project", isPresented: feature.binding(for: \.showingRenameAlert)) {
                TextField("Project name", text: feature.binding(for: \.renameProjectName))
                
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
                Text("Enter a new name for the project")
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
                ProgressView("Loading projects...")
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
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Projects Yet")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Create your first project to get started")
                .foregroundColor(.secondary)
            
            Button {
                feature.send(.showNewProjectAlert)
            } label: {
                Text("Create Project")
            }
            .buttonStyle(.borderedProminent)
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
}
