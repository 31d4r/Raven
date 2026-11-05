//
//  LeftSidebarView.swift
//  Raven
//
//  Created by Eldar Tutnjic on 24.07.25.
//

import PhotosUI
import QuickLook
import RDatabaseManager
import SwiftUI
import UniformTypeIdentifiers

/// The Sources list: a Mac inspector, or a sheet on iPhone and iPad.
struct ProjectFilesView: View {
    @Environment(ProjectFilesFeature.self) var feature
    let selectedProject: Project?

    @State private var selection: Set<FileRecord> = []
    @State private var previewURL: URL?
    @State private var isDropTargeted = false
    
    init(selectedProject: Project?) {
        self.selectedProject = selectedProject
    }
    
    var body: some View {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .fileDrop(isTargeted: $isDropTargeted) { urls, isTemporaryCopy in
                guard selectedProject != nil else { return false }
                feature.send(.addDroppedFiles(urls, isTemporaryCopy: isTemporaryCopy))
                return true
            }
            .confirmationDialog(
                DesignSystem.Sources.removeConfirmTitle(feature.value(\.fileToRemove)?.name ?? ""),
                isPresented: isConfirmingRemoval,
                titleVisibility: .visible,
                presenting: feature.value(\.fileToRemove)
            ) { file in
                Button(DesignSystem.Sources.remove, role: .destructive) {
                    selection.remove(file)
                    feature.send(.deleteFile(file))
                }
                Button(DesignSystem.Common.cancel, role: .cancel) {}
            } message: { _ in
                Text(DesignSystem.Sources.removeConfirmMessage)
            }
            #if os(iOS)
            .toolbar {
                if selectedProject != nil, !feature.value(\.files).isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        addMenu()
                    }
                }
            }
            .sourcePickers(feature: feature, isActive: feature.value(\.isSourcesSheetPresented))
            #endif
    }

    private var isConfirmingRemoval: Binding<Bool> {
        Binding(
            get: { feature.value(\.fileToRemove) != nil },
            set: { isPresented in
                if !isPresented { feature.set(\.fileToRemove, to: nil) }
            }
        )
    }
    
    @ViewBuilder
    func content() -> some View {
        if selectedProject == nil {
            ContentUnavailableView(
                DesignSystem.Sources.noChatTitle,
                systemImage: DesignSystem.Icons.sources,
                description: Text(DesignSystem.Sources.noChatMessage)
            )
        } else if feature.value(\.isLoading) {
            ProgressView(DesignSystem.Sources.loading)
                .accessibilityLabel(DesignSystem.Sources.loadingLabel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if feature.value(\.files).isEmpty {
            emptyFilesView()
        } else {
            filesList()
        }
    }

    // MARK: Empty state

    func emptyFilesView() -> some View {
        EmptyStateView(
            artwork: .symbol(DesignSystem.Icons.addFiles),
            title: isDropTargeted ? DesignSystem.Chat.releaseToAdd : DesignSystem.Sources.emptyTitle,
            message: DesignSystem.Sources.emptyMessage,
            isTargeted: isDropTargeted
        ) {
            #if os(macOS)
            Button(DesignSystem.Sources.addSources) {
                feature.presentFileImporter()
            }
            .buttonStyle(.borderedProminent)
            .help(DesignSystem.Help.tooltip(
                DesignSystem.Sources.addSources,
                shortcut: DesignSystem.Shortcuts.addSources,
                detail: DesignSystem.Sources.addSourcesDetail
            ))
            .accessibilityLabel(DesignSystem.Sources.addSourcesLabel)
            .accessibilityHint(DesignSystem.Sources.addSourcesDetail)
            .accessibilityInputLabels(DesignSystem.VoiceControl.addSources)
            .accessibilityIdentifier("addSourcesButton")
            #else
            Button(DesignSystem.Sources.addFiles) {
                feature.presentFileImporter()
            }
            .buttonStyle(.borderedProminent)
            .accessibilityHint(DesignSystem.Sources.addFilesDetail)
            .accessibilityInputLabels(DesignSystem.VoiceControl.addSources)
            .accessibilityIdentifier("addSourcesButton")

            Button(DesignSystem.Sources.addPhotos) {
                feature.set(\.isPhotoPickerPresented, to: true)
            }
            .buttonStyle(.bordered)
            .accessibilityHint(DesignSystem.Sources.addPhotosDetail)
            .accessibilityInputLabels(DesignSystem.VoiceControl.addPhotos)
            .accessibilityIdentifier("addPhotosButton")
            #endif
        }
        .background {
            RoundedRectangle(cornerRadius: DesignSystem.Radius.dropZone, style: .continuous)
                .fill(Color.accentColor.opacity(isDropTargeted ? DesignSystem.Colors.dropOnEmptyStateOpacity : 0))
                .padding(DesignSystem.Spacing.small)
                .accessibilityHidden(true)
        }
    }

    #if os(iOS)
    func addMenu() -> some View {
        Menu {
            Button {
                feature.presentFileImporter()
            } label: {
                Label {
                    Text(DesignSystem.Sources.addFiles)
                    Text(DesignSystem.Sources.addFilesDetail)
                } icon: {
                    Image(systemName: DesignSystem.Icons.addFiles)
                }
            }
            .accessibilityInputLabels(DesignSystem.VoiceControl.addSources)

            Button {
                feature.set(\.isPhotoPickerPresented, to: true)
            } label: {
                Label {
                    Text(DesignSystem.Sources.addPhotos)
                    Text(DesignSystem.Sources.addPhotosDetail)
                } icon: {
                    Image(systemName: DesignSystem.Icons.addPhotos)
                }
            }
            .accessibilityInputLabels(DesignSystem.VoiceControl.addPhotos)
        } label: {
            Label(DesignSystem.Sources.add, systemImage: DesignSystem.Icons.add)
        }
        .accessibilityHint(DesignSystem.Sources.addSourcesDetail)
        .accessibilityInputLabels(DesignSystem.VoiceControl.addSources)
        .accessibilityIdentifier("addSourcesButton")
    }
    #endif

    // MARK: List
    
    func filesList() -> some View {
        let files = feature.value(\.files)
        return List(selection: $selection) {
            Section {
                ForEach(files, id: \.self) { file in
                    FileRowView(file: file)
                        .rowAccessibilityActions(rowActions(for: file))
                        #if os(iOS)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(DesignSystem.Sources.remove, systemImage: DesignSystem.Icons.delete, role: .destructive) {
                                feature.set(\.fileToRemove, to: file)
                            }
                        }
                        #endif
                }
            } header: {
                Text(DesignSystem.Sources.count(files.count))
            } footer: {
                Text(DesignSystem.Sources.footer)
                    .foregroundStyle(DesignSystem.Colors.supporting)
            }
        }
        #if os(macOS)
        .listStyle(.inset)
        .onDeleteCommand {
            if let file = selection.first, selection.count == 1 {
                feature.set(\.fileToRemove, to: file)
            }
        }
        #else
        .listStyle(.insetGrouped)
        #endif
        .contextMenu(forSelectionType: FileRecord.self) { items in
            if let file = items.first, items.count == 1 {
                RowActionsMenu(actions: rowActions(for: file))
            }
        } primaryAction: { items in
            if let file = items.first {
                preview(file)
            }
        }
        .onKeyPress(.space) {
            guard let file = selection.first else { return .ignored }
            preview(file)
            return .handled
        }
        .overlay { DropHighlight(isTargeted: isDropTargeted) }
        .quickLookPreview($previewURL, in: files.map { URL(fileURLWithPath: $0.publicPath) })
        .accessibilityIdentifier("filesList")
    }

    func preview(_ file: FileRecord) {
        previewURL = URL(fileURLWithPath: file.publicPath)
    }

    func rowActions(for file: FileRecord) -> [RowAction] {
        var actions = [
            RowAction(
                id: "quickLook",
                title: DesignSystem.Sources.quickLook,
                systemImage: DesignSystem.Icons.quickLook
            ) {
                preview(file)
            }
        ]
        #if os(macOS)
        actions.append(
            RowAction(
                id: "showInFinder",
                title: DesignSystem.Sources.showInFinder,
                systemImage: DesignSystem.Icons.showInFinder
            ) {
                feature.revealInFinder(file)
            }
        )
        #endif
        actions.append(
            RowAction(
                id: "remove",
                title: DesignSystem.Sources.removeSource,
                spokenTitle: DesignSystem.Sources.removeSourceLabel,
                systemImage: DesignSystem.Icons.delete,
                role: .destructive,
                startsGroup: true
            ) {
                feature.set(\.fileToRemove, to: file)
            }
        )
        return actions
    }
}

// MARK: - Pickers (iOS)

#if os(iOS)
extension View {
    /// Files and Photos pickers. Only the visible screen presents them, so the
    /// chat and the Sources sheet each pass whether they are on top.
    func sourcePickers(feature: ProjectFilesView.ProjectFilesFeature, isActive: Bool) -> some View {
        self
            .fileImporter(
                isPresented: Binding(
                    get: { isActive && feature.value(\.isFileImporterPresented) },
                    set: { feature.set(\.isFileImporterPresented, to: $0) }
                ),
                allowedContentTypes: ProjectFilesView.supportedContentTypes,
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    feature.send(.selectFiles(urls))
                case .failure:
                    feature.set(\.errorMessage, to: DesignSystem.Errors.addSourcesFailed)
                }
            }
            .fileDialogConfirmationLabel(Text(DesignSystem.Sources.panelConfirm))
            .photosPicker(
                isPresented: Binding(
                    get: { isActive && feature.value(\.isPhotoPickerPresented) },
                    set: { feature.set(\.isPhotoPickerPresented, to: $0) }
                ),
                selection: feature.binding(for: \.selectedPhotoItems),
                selectionBehavior: .ordered,
                matching: .images
            )
            .onChange(of: feature.value(\.selectedPhotoItems)) { _, items in
                guard isActive, !items.isEmpty else { return }
                feature.send(.loadImagesFromGallery(items))
            }
    }
}
#endif
