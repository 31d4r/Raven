//
//  ProjectFilesView.swift
//  Raven
//
//  Created by Eldar Tutnjic on 24.07.25.
//

import PhotosUI
import RDatabaseManager
import SwiftUI
import UniformTypeIdentifiers

extension ProjectFilesView {
    struct LeftSidebarState {
        var files: [FileRecord] = []
        var selectedPhotoItems: [PhotosPickerItem] = []
        var isLoading = false
        var errorMessage: String?
        var currentProject: Project?
        var isFileImporterPresented = false
        var isPhotoPickerPresented = false
        var isSourcesSheetPresented = false
        var isImportingPhotos = false
        var fileToRemove: FileRecord?
        /// Number of sources from the latest add; drives the success banner.
        var recentlyAddedCount: Int?
    }
    
    enum Action {
        case loadFiles(Project)
        case selectFiles([URL])
        case deleteFile(FileRecord)
        case loadImagesFromGallery([PhotosPickerItem])
        case addDroppedFiles([URL], isTemporaryCopy: Bool)
        case dismissAddedBanner
    }

    /// File types Raven can read, shared by the file panel, Files picker and drops.
    static let supportedContentTypes: [UTType] = [
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
        .quickTimeMovie,
        .plainText,
        .text
    ]

    static func isSupported(_ url: URL) -> Bool {
        guard let type = UTType(filenameExtension: url.pathExtension) else { return false }
        return supportedContentTypes.contains { type.conforms(to: $0) }
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

        case .loadImagesFromGallery(let photos):
            await loadImagesFromGallery(photos: photos)

        case .addDroppedFiles(let urls, let isTemporaryCopy):
            await addDroppedFiles(urls, isTemporaryCopy: isTemporaryCopy)

        case .dismissAddedBanner:
            set(\.recentlyAddedCount, to: nil)
        }
    }
    
    private func loadFiles(for project: Project) async {
        if value(\.currentProject)?.id != project.id {
            set(\.recentlyAddedCount, to: nil)
            set(\.fileToRemove, to: nil)
        }
        set(\.currentProject, to: project)
        set(\.isLoading, to: true)
        set(\.errorMessage, to: nil)
        
        do {
            let files = try databaseManager.fetchFiles(for: project)
            set(\.files, to: files)
        } catch {
            set(\.errorMessage, to: DesignSystem.Errors.loadSourcesFailed)
        }
        
        set(\.isLoading, to: false)
    }
    
    @discardableResult
    private func addFiles(_ urls: [URL]) async -> [FileRecord] {
        guard let currentProject = value(\.currentProject) else { return [] }
        
        do {
            let newFiles = try databaseManager.addFiles(urls, to: currentProject)
            var updatedFiles = value(\.files)
            updatedFiles.insert(contentsOf: newFiles, at: 0)
            set(\.files, to: updatedFiles)
            set(\.recentlyAddedCount, to: newFiles.isEmpty ? nil : newFiles.count)
            return newFiles
        } catch {
            set(\.errorMessage, to: DesignSystem.Errors.addSourcesFailed)
            return []
        }
    }

    @discardableResult
    private func addDroppedFiles(_ urls: [URL], isTemporaryCopy: Bool) async -> [FileRecord] {
        let supported = urls.filter(ProjectFilesView.isSupported)
        if supported.count < urls.count {
            set(\.errorMessage, to: DesignSystem.Errors.unsupportedDrop)
        }
        var added: [FileRecord] = []
        if !supported.isEmpty {
            added = await addFiles(supported)
        }
        if isTemporaryCopy {
            for url in urls {
                try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
            }
        }
        return added
    }
    
    /// Adds composer attachments as sources and waits until they are saved,
    /// so a question sent with them can already use them.
    /// Returns the new source records, so the chat can show sent images.
    @discardableResult
    func attach(_ urls: [URL], isTemporaryCopy: Bool) async -> [FileRecord] {
        guard !urls.isEmpty else { return [] }
        return await addDroppedFiles(urls, isTemporaryCopy: isTemporaryCopy)
    }

    private func deleteFile(_ fileRecord: FileRecord) async {
        do {
            try databaseManager.deleteFile(fileRecord)
            let updatedFiles = value(\.files).filter { $0.id != fileRecord.id }
            set(\.files, to: updatedFiles)
            if value(\.fileToRemove)?.id == fileRecord.id {
                set(\.fileToRemove, to: nil)
            }
        } catch {
            set(\.errorMessage, to: DesignSystem.Errors.removeSourceFailed)
        }
    }
    
    private func loadImagesFromGallery(photos: [PhotosPickerItem]) async {
        guard let currentProject = value(\.currentProject) else { return }
        set(\.isImportingPhotos, to: true)
        defer {
            set(\.isImportingPhotos, to: false)
            set(\.selectedPhotoItems, to: [])
        }
        var failedCount = 0
        
        var temporaryURLs: [URL] = []
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory
        
        for photo in photos {
            guard let data = try? await photo.loadTransferable(type: Data.self) else {
                failedCount += 1
                continue
            }
            
            let fileName = "\(UUID().uuidString).jpg"
            let tempURL = tempDirectory.appendingPathComponent(fileName)
            
            do {
                try data.write(to: tempURL)
                temporaryURLs.append(tempURL)
            } catch {
                failedCount += 1
                continue
            }
        }
        
        if !temporaryURLs.isEmpty {
            do {
                let newFiles = try databaseManager.addFiles(temporaryURLs, to: currentProject)
                var updatedFiles = value(\.files)
                updatedFiles.insert(contentsOf: newFiles, at: 0)
                set(\.files, to: updatedFiles)
                set(\.recentlyAddedCount, to: newFiles.isEmpty ? nil : newFiles.count)
                
                for tempURL in temporaryURLs {
                    try? fileManager.removeItem(at: tempURL)
                }
            } catch {
                set(\.errorMessage, to: DesignSystem.Errors.addSourcesFailed)
                
                for tempURL in temporaryURLs {
                    try? fileManager.removeItem(at: tempURL)
                }
            }
        }

        if failedCount > 0 {
            set(\.errorMessage, to: DesignSystem.Errors.addPhotosFailed)
        }
    }
}

// MARK: - Functions

extension ProjectFilesView.ProjectFilesFeature {
    var hasProject: Bool {
        value(\.currentProject) != nil
    }

    /// Opens the platform picker: the file panel on Mac, the Files picker on iOS.
    func presentFileImporter() {
        #if os(macOS)
        openFilePicker()
        #else
        set(\.isFileImporterPresented, to: true)
        #endif
    }

    #if os(macOS)
    func revealInFinder(_ file: FileRecord) {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: file.publicPath)])
    }

    func openFilePicker() {
        let panel = makeOpenPanel()
        panel.begin { [weak self] result in
            if result == .OK {
                let selectedURLs = panel.urls
                self?.send(.selectFiles(selectedURLs))
            }
        }
    }

    /// Shows the file panel and returns the chosen files without adding them,
    /// so the composer can hold them as attachments until the user sends.
    func chooseFiles() async -> [URL] {
        let panel = makeOpenPanel()
        panel.prompt = DesignSystem.Conversation.attachConfirm
        let response = await panel.begin()
        return response == .OK ? panel.urls : []
    }

    private func makeOpenPanel() -> NSOpenPanel {
        let panel = NSOpenPanel()
        panel.title = DesignSystem.Sources.addSources
        panel.message = DesignSystem.Sources.panelMessage
        panel.prompt = DesignSystem.Sources.panelConfirm
        panel.showsHiddenFiles = false
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = ProjectFilesView.supportedContentTypes
        return panel
    }
    #endif
}
