//
//  ProjectsFeature.swift
//  Raven
//
//  Created by Eldar Tutnjic on 24.07.25.
//

import RDatabaseManager
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
        var projectToDelete: Project?
        /// One-line preview of each chat’s last message, keyed by chat id.
        var previews: [Int64: String] = [:]
        /// When each chat’s last message was sent, keyed by chat id.
        var previewDates: [Int64: Date] = [:]
        /// Chat list search text (iOS).
        var searchText = ""
        /// The ⌘K chat switcher on Mac.
        var isSearchPresented = false
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
        /// Every chat’s messages as plain text, for chat list search.
        @ObservationIgnored var searchIndex: [Int64: String] = [:]
        private let databaseManager: RDatabaseManager
        
        init(
            databaseManager: RDatabaseManager
        ) {
            self.databaseManager = databaseManager
        }
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
            loadPreviews(for: projects)
        } catch {
            set(\.errorMessage, to: DesignSystem.Errors.loadChatsFailed)
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
            if let id = project.id {
                ChatAppearanceStore.shared.assignPendingAppearance(to: id)
            }
        } catch {
            set(\.errorMessage, to: DesignSystem.Errors.createChatFailed)
        }
    }
    
    private func deleteProject(_ project: Project) async {
        do {
            try databaseManager.deleteProject(project)
            let updatedProjects = value(\.projects).filter { $0.id != project.id }
            set(\.projects, to: updatedProjects)
            if let id = project.id {
                ChatAppearanceStore.shared.removeAppearance(for: id)
                MessageAttachmentStore.shared.removeAll(for: id)
                state.previews[id] = nil
                state.previewDates[id] = nil
                searchIndex[id] = nil
            }
            
            if value(\.selectedProject)?.id == project.id {
                set(\.selectedProject, to: nil)
            }
        } catch {
            set(\.errorMessage, to: DesignSystem.Errors.deleteChatFailed)
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
            set(\.errorMessage, to: DesignSystem.Errors.renameChatFailed)
        }
    }
}

// MARK: - Previews

extension ProjectsView.ProjectsFeature {
    /// Reads each chat’s last message once, for the sidebar preview line.
    private func loadPreviews(for projects: [Project]) {
        var previews: [Int64: String] = [:]
        var dates: [Int64: Date] = [:]
        var index: [Int64: String] = [:]
        for project in projects {
            guard let id = project.id,
                  let messages = try? databaseManager.fetchChatMessages(for: project),
                  let last = messages.last else { continue }
            previews[id] = Self.previewText(last.content)
            dates[id] = last.createdAt
            index[id] = messages.map { Self.plainText($0.content) }.joined(separator: "\n")
        }
        set(\.previews, to: previews)
        set(\.previewDates, to: dates)
        searchIndex = index
    }

    /// Keeps the sidebar preview in step with the open conversation.
    func updatePreview(for projectID: Int64, lastMessage: ChatMessage?) {
        let text = lastMessage.map { Self.previewText($0.content) }
        guard state.previews[projectID] != text else { return }
        state.previews[projectID] = text
        state.previewDates[projectID] = lastMessage?.createdAt
        if let lastMessage {
            let line = Self.plainText(lastMessage.content)
            searchIndex[projectID] = [searchIndex[projectID], line].compactMap { $0 }.joined(separator: "\n")
        } else {
            searchIndex[projectID] = nil
        }
    }

    /// Chats whose name or messages contain the search text, in list order.
    var searchResults: [Project] {
        let query = state.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return state.projects }
        return state.projects.filter { project in
            project.name.localizedStandardContains(query)
                || (project.id.flatMap { searchIndex[$0] }?.localizedStandardContains(query) ?? false)
        }
    }

    /// The first message line that matches, shown instead of the preview while searching.
    func searchSnippet(for project: Project) -> String? {
        let query = state.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, let id = project.id, let text = searchIndex[id] else { return nil }
        let lines = text.split(separator: "\n").reversed()
        guard let line = lines.first(where: { $0.localizedStandardContains(query) }),
              let range = line.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) else { return nil }
        let start = line.index(range.lowerBound, offsetBy: -Constants.snippetLead, limitedBy: line.startIndex) ?? line.startIndex
        let prefix = start == line.startIndex ? "" : "…"
        return prefix + String(line[start...])
    }

    /// Plain single-line text: Markdown markers and line breaks removed.
    static func previewText(_ content: String) -> String {
        String(plainText(content).prefix(Constants.previewLength))
    }

    static func plainText(_ content: String) -> String {
        var text = content
        for marker in ["```", "**", "__", "`", "#", ">", "*"] {
            text = text.replacingOccurrences(of: marker, with: "")
        }
        let words = text.split(whereSeparator: \.isWhitespace)
        return words.joined(separator: " ")
    }

    private enum Constants {
        static let previewLength = 160
        static let snippetLead = 24
    }
}
