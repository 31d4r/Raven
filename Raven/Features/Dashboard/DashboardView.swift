//
//  DashboardView.swift
//  Raven
//
//  Created by Eldar Tutnjic on 18.07.25.
//

import RDatabaseManager
import SwiftUI

struct DashboardView: View {
    @Environment(ProjectsView.ProjectsFeature.self) private var projectsFeature
    @Environment(ProjectFilesView.ProjectFilesFeature.self) private var filesFeature
    @Environment(MainContentView.MainContentFeature.self) private var chatFeature
    @AppStorage(DesignSystem.Storage.showsSourcesInspector) private var showsSources = true
    @State private var selectedProject: Project?

    var body: some View {
        NavigationSplitView {
            ProjectsView(selectedProject: $selectedProject)
            #if os(macOS)
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 340)
            #endif
        } detail: {
            MainContentView(
                selectedProject: selectedProject
            )
        }
        #if os(macOS)
        .inspector(isPresented: $showsSources) {
            ProjectFilesView(selectedProject: selectedProject)
                .inspectorColumnWidth(
                    min: DesignSystem.Layout.inspectorMinWidth,
                    ideal: DesignSystem.Layout.inspectorIdealWidth,
                    max: DesignSystem.Layout.inspectorMaxWidth
                )
        }
        .frame(
            minWidth: DesignSystem.Layout.windowMinimumSize.width,
            minHeight: DesignSystem.Layout.windowMinimumSize.height
        )
        #endif
        .navigationSplitViewStyle(.balanced)
        #if os(macOS)
        .overlay {
            if projectsFeature.value(\.isSearchPresented) {
                CommandPalette()
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.15), value: projectsFeature.value(\.isSearchPresented))
        .sheet(isPresented: projectsFeature.binding(for: \.showingNewProjectAlert)) {
            NewChatCard()
        }
        #else
        .sheet(isPresented: projectsFeature.binding(for: \.showingNewProjectAlert)) {
            NewChatSheet()
        }
        #endif
        .alert(DesignSystem.Chats.renameTitle, isPresented: projectsFeature.binding(for: \.showingRenameAlert)) {
            renameAlertActions()
        } message: {
            Text(DesignSystem.Chats.renameMessage(projectsFeature.value(\.projectToRename)?.name ?? ""))
        }
        .confirmationDialog(
            DesignSystem.Chats.deleteConfirmTitle(projectsFeature.value(\.projectToDelete)?.name ?? ""),
            isPresented: isConfirmingDelete,
            titleVisibility: .visible,
            presenting: projectsFeature.value(\.projectToDelete)
        ) { project in
            Button(DesignSystem.Chats.delete, role: .destructive) {
                projectsFeature.send(.deleteProject(project))
            }
            Button(DesignSystem.Common.cancel, role: .cancel) {}
        } message: { _ in
            Text(DesignSystem.Chats.deleteConfirmMessage)
        }
        .confirmationDialog(
            DesignSystem.Chat.clearConfirmTitle(selectedProject?.name ?? ""),
            isPresented: chatFeature.binding(for: \.isConfirmingClearHistory),
            titleVisibility: .visible,
            presenting: selectedProject
        ) { project in
            Button(DesignSystem.Chat.clearConfirmButton, role: .destructive) {
                chatFeature.send(.clearHistory(project))
                if let projectID = project.id {
                    MessageAttachmentStore.shared.removeAll(for: projectID)
                }
            }
            Button(DesignSystem.Common.cancel, role: .cancel) {}
        } message: { _ in
            Text(DesignSystem.Chat.clearConfirmMessage(chatFeature.value(\.messages).count))
        }
        .alert(DesignSystem.Errors.title, isPresented: isShowingError, presenting: currentError) { _ in
            Button(DesignSystem.Common.ok, role: .cancel) {}
        } message: { message in
            Text(message)
        }
        .onChange(of: currentError) { _, error in
            if let error {
                AccessibilityHelper.announce(error)
            }
        }
        .sensoryFeedback(.selection, trigger: selectedProject?.id)
        .sensoryFeedback(trigger: filesFeature.value(\.recentlyAddedCount)) { _, count in
            count == nil ? nil : .success
        }
        .sensoryFeedback(trigger: currentError) { _, error in
            error == nil ? nil : .error
        }
    }

    // MARK: Rename

    @ViewBuilder
    private func renameAlertActions() -> some View {
        let name = projectsFeature.value(\.renameProjectName).trimmingCharacters(in: .whitespacesAndNewlines)

        TextField(DesignSystem.Chats.nameField, text: projectsFeature.binding(for: \.renameProjectName))
            .accessibilityHint(DesignSystem.Chats.nameFieldHint)
            .accessibilityIdentifier("renameChatTextField")

        Button(DesignSystem.Common.cancel, role: .cancel) {
            projectsFeature.send(.hideRenameAlert)
        }
        .accessibilityInputLabels(DesignSystem.VoiceControl.cancel)

        Button(DesignSystem.Chats.rename) {
            projectsFeature.send(.renameProject(name))
        }
        .disabled(name.isEmpty)
        .accessibilityHint(name.isEmpty ? DesignSystem.Chats.nameRequiredReason : "")
        .accessibilityInputLabels(DesignSystem.VoiceControl.rename)
    }

    // MARK: Confirmations and errors

    private var isConfirmingDelete: Binding<Bool> {
        Binding(
            get: { projectsFeature.value(\.projectToDelete) != nil },
            set: { isPresented in
                if !isPresented { projectsFeature.set(\.projectToDelete, to: nil) }
            }
        )
    }

    /// The first pending error from any feature; one alert shows them all.
    private var currentError: String? {
        projectsFeature.value(\.errorMessage)
            ?? filesFeature.value(\.errorMessage)
            ?? chatFeature.value(\.errorMessage)
    }

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { currentError != nil },
            set: { isPresented in
                guard !isPresented else { return }
                if projectsFeature.value(\.errorMessage) != nil {
                    projectsFeature.set(\.errorMessage, to: nil)
                } else if filesFeature.value(\.errorMessage) != nil {
                    filesFeature.set(\.errorMessage, to: nil)
                } else {
                    chatFeature.set(\.errorMessage, to: nil)
                }
            }
        )
    }
}
