//
//  ProjectsFeature.swift
//  Raven
//
//  Created by Eldar Tutnjic on 24.07.25.
//

import SwiftUI

extension ProjectsView {
    struct ProjectsState {
        var projects: [Project] = []
        var isLoading = false
        var errorMessage: String?
        var showingNewProjectAlert = false
        var newProjectName = ""
        var selectedProject: Project?
        var showingRenameAlert = false
        var projectToRename: Project?
        var renameProjectName = ""
    }
    
    enum Action {
        case loadProjects
        case showNewProjectAlert
        case hideNewProjectAlert
        case createProject(String)
        case selectProject(Project)
        case deleteProject(Project)
        case showRenameAlert(Project)
        case hideRenameAlert
        case renameProject(String)
    }
    
    @Observable
    class ProjectsFeature {
        private(set) var state = ProjectsState()
        private let databaseManager = DatabaseManager()
    }
}

// MARK: - Utils

extension ProjectsView.ProjectsFeature {
    func send(_ action: ProjectsView.Action) {
        Task {
            await handle(action)
        }
    }
    
    func value<T>(_ keyPath: KeyPath<ProjectsView.ProjectsState, T>) -> T {
        state[keyPath: keyPath]
    }

    func set<T>(_ keyPath: WritableKeyPath<ProjectsView.ProjectsState, T>, to value: T) {
        state[keyPath: keyPath] = value
    }

    func binding<T>(for keyPath: WritableKeyPath<ProjectsView.ProjectsState, T>) -> Binding<T> {
        Binding<T>(
            get: { self.state[keyPath: keyPath] },
            set: { newValue in
                self.state[keyPath: keyPath] = newValue
            }
        )
    }
}

// MARK: - Actions

extension ProjectsView.ProjectsFeature {
    @MainActor
    private func handle(_ action: ProjectsView.Action) async {
        switch action {
        case .loadProjects:
            await loadProjects()
            
        case .showNewProjectAlert:
            set(\.showingNewProjectAlert, to: true)
            set(\.newProjectName, to: "")
            
        case .hideNewProjectAlert:
            set(\.showingNewProjectAlert, to: false)
            
        case .createProject(let name):
            await createProject(name: name)
            
        case .selectProject(let project):
            set(\.selectedProject, to: project)
            
        case .deleteProject(let project):
            await deleteProject(project)

        case .showRenameAlert(let project):
            set(\.projectToRename, to: project)
            set(\.renameProjectName, to: project.name)
            set(\.showingRenameAlert, to: true)

        case .hideRenameAlert:
            set(\.showingRenameAlert, to: false)
            set(\.projectToRename, to: nil)

        case .renameProject(let newName):
            await renameProject(newName: newName)
        }
    }
    
    private func loadProjects() async {
        set(\.isLoading, to: true)
        set(\.errorMessage, to: nil)
        
        do {
            let projects = try databaseManager.fetchProjects()
            set(\.projects, to: projects)
        } catch {
            set(\.errorMessage, to: error.localizedDescription)
        }
        
        set(\.isLoading, to: false)
    }
    
    private func createProject(name: String) async {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        do {
            let project = try databaseManager.createProject(name: name.trimmingCharacters(in: .whitespacesAndNewlines))
            var updatedProjects = value(\.projects)
            updatedProjects.insert(project, at: 0)
            set(\.projects, to: updatedProjects)
            set(\.selectedProject, to: project)
            set(\.showingNewProjectAlert, to: false)
        } catch {
            set(\.errorMessage, to: error.localizedDescription)
        }
    }
    
    private func deleteProject(_ project: Project) async {
        do {
            try databaseManager.deleteProject(project)
            let updatedProjects = value(\.projects).filter { $0.id != project.id }
            set(\.projects, to: updatedProjects)
            
            if value(\.selectedProject)?.id == project.id {
                set(\.selectedProject, to: nil)
            }
        } catch {
            set(\.errorMessage, to: error.localizedDescription)
        }
    }
    
    private func renameProject(newName: String) async {
        guard let project = value(\.projectToRename),
              !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        do {
            let updatedProject = try databaseManager.renameProject(project, newName: newName.trimmingCharacters(in: .whitespacesAndNewlines))
            
            var updatedProjects = value(\.projects)
            if let index = updatedProjects.firstIndex(where: { $0.id == project.id }) {
                updatedProjects[index] = updatedProject
                set(\.projects, to: updatedProjects)
            }
            
            if value(\.selectedProject)?.id == project.id {
                set(\.selectedProject, to: updatedProject)
            }
            
            set(\.showingRenameAlert, to: false)
            set(\.projectToRename, to: nil)
        } catch {
            set(\.errorMessage, to: error.localizedDescription)
        }
    }
}
