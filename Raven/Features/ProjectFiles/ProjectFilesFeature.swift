//
//  ProjectFilesView.swift
//  Raven
//
//  Created by Eldar Tutnjic on 24.07.25.
//

import RDatabaseManager
import SwiftUI
import UniformTypeIdentifiers

extension ProjectFilesView {
    struct LeftSidebarState {
        var files: [FileRecord] = []
        var isLoading = false
        var errorMessage: String?
        var currentProject: Project?
    }
    
    enum Action {
        case loadFiles(Project)
        case selectFiles([URL])
        case deleteFile(FileRecord)
    }
    
    @Observable
    class ProjectFilesFeature {
        private(set) var state = LeftSidebarState()
        private let databaseManager: RDatabaseManager
        
        init(databaseManager: RDatabaseManager) {
            self.databaseManager = databaseManager
        }
    }
}

// MARK: - Utils

extension ProjectFilesView.ProjectFilesFeature {
    func send(_ action: ProjectFilesView.Action) {
        Task {
            await handle(action)
        }
    }
    
    func value<T>(_ keyPath: KeyPath<ProjectFilesView.LeftSidebarState, T>) -> T {
        state[keyPath: keyPath]
    }

    func set<T>(_ keyPath: WritableKeyPath<ProjectFilesView.LeftSidebarState, T>, to value: T) {
        state[keyPath: keyPath] = value
    }

    func binding<T>(for keyPath: WritableKeyPath<ProjectFilesView.LeftSidebarState, T>) -> Binding<T> {
        Binding<T>(
            get: { self.state[keyPath: keyPath] },
            set: { newValue in
                self.state[keyPath: keyPath] = newValue
            }
        )
    }
}

// MARK: - Actions

extension ProjectFilesView.ProjectFilesFeature {
    @MainActor
    private func handle(_ action: ProjectFilesView.Action) async {
        switch action {
        case .loadFiles(let project):
            await loadFiles(for: project)
            
        case .selectFiles(let urls):
            await addFiles(urls)
            
        case .deleteFile(let fileRecord):
            await deleteFile(fileRecord)
        }
    }
    
    private func loadFiles(for project: Project) async {
        set(\.currentProject, to: project)
        set(\.isLoading, to: true)
        set(\.errorMessage, to: nil)
        
        do {
            let files = try databaseManager.fetchFiles(for: project)
            set(\.files, to: files)
        } catch {
            set(\.errorMessage, to: error.localizedDescription)
        }
        
        set(\.isLoading, to: false)
    }
    
    private func addFiles(_ urls: [URL]) async {
        guard let currentProject = value(\.currentProject) else { return }
        
        do {
            let newFiles = try databaseManager.addFiles(urls, to: currentProject)
            var updatedFiles = value(\.files)
            updatedFiles.insert(contentsOf: newFiles, at: 0)
            set(\.files, to: updatedFiles)
        } catch {
            set(\.errorMessage, to: error.localizedDescription)
        }
    }
    
    private func deleteFile(_ fileRecord: FileRecord) async {
        do {
            try databaseManager.deleteFile(fileRecord)
            let updatedFiles = value(\.files).filter { $0.id != fileRecord.id }
            set(\.files, to: updatedFiles)
        } catch {
            set(\.errorMessage, to: error.localizedDescription)
        }
    }
}

// MARK: - Functions

extension ProjectFilesView.ProjectFilesFeature {
    #if os(macOS)
    func openFilePicker() {
        let panel = NSOpenPanel()
        
        panel.title = "Choose files to add"
        panel.showsHiddenFiles = false
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [
            .audio,
            .mp3,
            .mpeg4Audio,
            .aiff,
            .wav,
            .image,
            .jpeg,
            .png,
            .tiff,
            .heic,
            .pdf,
            .movie,
            .video,
            .mpeg4Movie,
            .appleProtectedMPEG4Video,
            .quickTimeMovie
        ]
        
        panel.begin { [weak self] result in
            if result == .OK {
                let selectedURLs = panel.urls
                self?.send(.selectFiles(selectedURLs))
            }
        }
    }
    #endif
}
