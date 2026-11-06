//
//  RavenCommands.swift
//  Raven
//
//  Menu bar commands (and iPad hardware-keyboard shortcuts). Each command
//  reads the same features as the toolbar, so both stay in sync.
//

import RDatabaseManager
import SwiftUI

struct RavenCommands: Commands {
    let projectsFeature: ProjectsView.ProjectsFeature
    let filesFeature: ProjectFilesView.ProjectFilesFeature
    let chatFeature: MainContentView.MainContentFeature

    @AppStorage(DesignSystem.Storage.showsSourcesInspector) private var showsSources = true
    #if os(macOS)
    @AppStorage(DesignSystem.Storage.showsMessageTimes) private var showsMessageTimes = false
    @Environment(\.openWindow) private var openWindow
    #endif

    private var selectedProject: Project? {
        projectsFeature.value(\.selectedProject)
    }

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button(DesignSystem.Chats.newChatEllipsis) {
                projectsFeature.send(.showNewProjectAlert)
            }
            .keyboardShortcut(DesignSystem.Shortcuts.newChat)

            #if os(macOS)
            Button(DesignSystem.Conversation.searchChatsEllipsis) {
                projectsFeature.set(\.isSearchPresented, to: !projectsFeature.value(\.isSearchPresented))
            }
            .keyboardShortcut(DesignSystem.Shortcuts.searchChats)
            .disabled(projectsFeature.value(\.projects).isEmpty)
            #endif

            Button(DesignSystem.Sources.addSources) {
                filesFeature.presentFileImporter()
            }
            .keyboardShortcut(DesignSystem.Shortcuts.addSources)
            .disabled(selectedProject == nil)
        }

        CommandMenu(DesignSystem.Menu.chat) {
            Button(DesignSystem.Chat.send) {
                chatFeature.submitQuestion(for: selectedProject)
            }
            .keyboardShortcut(DesignSystem.Shortcuts.sendQuestion)
            .disabled(chatFeature.sendUnavailableReason(for: selectedProject) != nil)

            Button(DesignSystem.Chat.cancelAnswer) {
                chatFeature.send(.cancelProcessing)
            }
            .keyboardShortcut(DesignSystem.Shortcuts.cancelAnswer)
            .disabled(chatFeature.cancelUnavailableReason != nil)

            Divider()

            Button(DesignSystem.Chat.copyResponse) {
                chatFeature.send(.copyResponse)
            }
            .keyboardShortcut(DesignSystem.Shortcuts.copyResponse)
            .disabled(chatFeature.copyResponseUnavailableReason(for: selectedProject) != nil)

            Divider()

            Button(DesignSystem.Chats.renameChat) {
                if let selectedProject {
                    projectsFeature.send(.showRenameAlert(selectedProject))
                }
            }
            .keyboardShortcut(DesignSystem.Shortcuts.renameChat)
            .disabled(selectedProject == nil)

            Button(DesignSystem.Chat.clearHistory) {
                chatFeature.set(\.isConfirmingClearHistory, to: true)
            }
            .keyboardShortcut(DesignSystem.Shortcuts.clearHistory)
            .disabled(chatFeature.clearHistoryUnavailableReason(for: selectedProject) != nil)

            Button(DesignSystem.Chats.deleteChat) {
                projectsFeature.set(\.projectToDelete, to: selectedProject)
            }
            .keyboardShortcut(DesignSystem.Shortcuts.deleteChat)
            .disabled(selectedProject == nil)
        }

        #if os(macOS)
        CommandGroup(after: .windowArrangement) {
            Section(DesignSystem.Conversation.goToChat) {
                ForEach(Array(projectsFeature.value(\.projects).prefix(9).enumerated()), id: \.element) { index, project in
                    if let shortcut = DesignSystem.Shortcuts.chat(at: index) {
                        Button(project.name) {
                            projectsFeature.set(\.isSearchPresented, to: false)
                            projectsFeature.send(.selectProject(project))
                        }
                        .keyboardShortcut(shortcut)
                    }
                }
            }
        }

        SidebarCommands()

        CommandGroup(after: .sidebar) {
            Button(showsSources ? DesignSystem.Sources.hide : DesignSystem.Sources.show) {
                showsSources.toggle()
            }
            .keyboardShortcut(DesignSystem.Shortcuts.toggleSources)

            Toggle(DesignSystem.Menu.showMessageTimes, isOn: $showsMessageTimes)
                .keyboardShortcut(DesignSystem.Shortcuts.showMessageTimes)
        }

        CommandGroup(replacing: .help) {
            Button(DesignSystem.Menu.keyboardShortcuts) {
                openWindow(id: DesignSystem.Shortcuts.windowID)
            }
            .keyboardShortcut(DesignSystem.Shortcuts.keyboardShortcuts)
        }
        #else
        CommandGroup(after: .sidebar) {
            Button(DesignSystem.Sources.show) {
                filesFeature.set(\.isSourcesSheetPresented, to: true)
            }
            .keyboardShortcut(DesignSystem.Shortcuts.toggleSources)
            .disabled(selectedProject == nil)
        }
        #endif
    }
}
