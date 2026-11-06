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
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @FocusState private var isSearchFocused: Bool
    #endif

    init(selectedProject: Binding<Project?>) {
        self._selectedProject = selectedProject
    }
    
    var body: some View {
        content()
            .navigationTitle(DesignSystem.Chats.sidebarTitle)
            #if os(iOS)
            .toolbar(isCompact ? .hidden : .automatic, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                if isCompact {
                    listHeader()
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !feature.value(\.projects).isEmpty {
                    searchBar()
                }
            }
            #endif
            .toolbar {
                #if os(macOS)
                ToolbarItemGroup(placement: .primaryAction) {
                    searchButton()
                    newChatButton(showsTitle: false)
                }
                #else
                if !isCompact && !feature.value(\.projects).isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        newChatButton(showsTitle: false)
                    }
                }
                #endif
            }
            .task {
                feature.send(.loadProjects)
            }
            .onChange(of: feature.value(\.selectedProject)) { _, newProject in
                selectedProject = newProject
            }
    }
    
    @ViewBuilder
    func content() -> some View {
        if feature.value(\.isLoading) {
            ProgressView(DesignSystem.Chats.loading)
                .accessibilityLabel(DesignSystem.Chats.loadingLabel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if feature.value(\.projects).isEmpty {
            emptyStateView()
        } else {
            projectsList()
        }
    }

    #if os(macOS)
    func searchButton() -> some View {
        Button {
            feature.set(\.isSearchPresented, to: true)
        } label: {
            Label(DesignSystem.Conversation.searchChats, systemImage: DesignSystem.Icons.search)
                .labelStyle(.iconOnly)
        }
        .disabled(feature.value(\.projects).isEmpty)
        .help(DesignSystem.Help.tooltip(
            DesignSystem.Conversation.searchChats,
            shortcut: DesignSystem.Shortcuts.searchChats
        ))
        .accessibilityHint(DesignSystem.Conversation.searchHint)
        .accessibilityIdentifier("searchChatsButton")
    }
    #endif

    func newChatButton(showsTitle: Bool) -> some View {
        Button {
            feature.send(.showNewProjectAlert)
        } label: {
            if showsTitle {
                Label(DesignSystem.Chats.newChat, systemImage: DesignSystem.Icons.newChat)
                    .labelStyle(.titleAndIcon)
            } else {
                Label(DesignSystem.Chats.newChat, systemImage: DesignSystem.Icons.newChat)
                    .labelStyle(.iconOnly)
            }
        }
        .help(DesignSystem.Help.tooltip(
            DesignSystem.Chats.newChat,
            shortcut: DesignSystem.Shortcuts.newChat,
            detail: DesignSystem.Chats.newChatHelp
        ))
        .accessibilityHint(DesignSystem.Chats.newChatHelp)
        .accessibilityInputLabels(DesignSystem.VoiceControl.newChat)
        .accessibilityIdentifier("newChatButton")
    }
    
    @ViewBuilder
    func emptyStateView() -> some View {
        #if os(macOS)
        // The detail column carries the New Chat button on Mac.
        ContentUnavailableView(
            DesignSystem.Chats.emptyTitle,
            systemImage: DesignSystem.Icons.chats,
            description: Text(DesignSystem.Chats.emptyMessage)
        )
        #else
        EmptyStateView(
            artwork: .brand,
            title: DesignSystem.Chat.firstChatTitle,
            message: DesignSystem.Chat.firstChatMessage
        ) {
            Button(DesignSystem.Chats.newChatEllipsis) {
                feature.send(.showNewProjectAlert)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel(DesignSystem.Chats.newChat)
            .accessibilityHint(DesignSystem.Chats.newChatHelp)
            .accessibilityInputLabels(DesignSystem.VoiceControl.newChat)
            .accessibilityIdentifier("createChatButton")
        }
        #endif
    }
    
    #if os(macOS)
    /// Chat-app sidebar: avatar, bold name and last-message preview, with a
    /// soft rounded highlight on the open chat.
    func projectsList() -> some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Conversation.sidebarRowSpacing) {
                ForEach(feature.value(\.projects), id: \.self) { project in
                    sidebarRow(project)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.small + DesignSystem.Spacing.xSmall)
            .padding(.vertical, DesignSystem.Spacing.xSmall)
        }
        .focusable()
        .focusEffectDisabled()
        .onKeyPress(.upArrow) { moveSelection(by: -1) }
        .onKeyPress(.downArrow) { moveSelection(by: 1) }
        .onDeleteCommand {
            if let selected = feature.value(\.selectedProject) {
                feature.set(\.projectToDelete, to: selected)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(DesignSystem.Chats.sidebarTitle)
        .accessibilityIdentifier("chatsList")
    }

    func sidebarRow(_ project: Project) -> some View {
        ChatSidebarRow(
            project: project,
            preview: project.id.flatMap { feature.value(\.previews)[$0] },
            isSelected: feature.value(\.selectedProject)?.id == project.id
        ) {
            feature.send(.selectProject(project))
        }
        .contextMenu {
            RowActionsMenu(actions: rowActions(for: project))
        }
        .rowAccessibilityActions(rowActions(for: project))
    }

    func moveSelection(by offset: Int) -> KeyPress.Result {
        let projects = feature.value(\.projects)
        guard !projects.isEmpty else { return .ignored }
        let current = projects.firstIndex { $0.id == feature.value(\.selectedProject)?.id }
        let next = current.map { min(max($0 + offset, 0), projects.count - 1) } ?? 0
        feature.send(.selectProject(projects[next]))
        return .handled
    }
    #else
    var isCompact: Bool {
        #if os(iOS)
        horizontalSizeClass == .compact
        #else
        false
        #endif
    }

    var isSearching: Bool {
        #if os(iOS)
        isSearchFocused || !feature.value(\.searchText).isEmpty
        #else
        !feature.value(\.searchText).isEmpty
        #endif
    }

    /// Plain list of chat rows; swipe for Rename and Delete, or long-press.
    func projectsList() -> some View {
        let projects = feature.searchResults
        let query = feature.value(\.searchText)
        return List(selection: feature.binding(for: \.selectedProject)) {
            ForEach(projects, id: \.self) { project in
                ChatListRow(
                    project: project,
                    preview: feature.searchSnippet(for: project) ?? project.id.flatMap { feature.value(\.previews)[$0] },
                    lastMessageDate: project.id.flatMap { feature.value(\.previewDates)[$0] }
                )
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(
                    top: 0,
                    leading: DesignSystem.Conversation.floatingBarPadding,
                    bottom: 0,
                    trailing: DesignSystem.Conversation.floatingBarPadding
                ))
                .rowAccessibilityActions(rowActions(for: project))
                #if os(iOS)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(DesignSystem.Chats.delete, systemImage: DesignSystem.Icons.delete, role: .destructive) {
                        feature.set(\.projectToDelete, to: project)
                    }
                    Button(DesignSystem.Chats.rename, systemImage: DesignSystem.Icons.rename) {
                        feature.send(.showRenameAlert(project))
                    }
                }
                #endif
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .contextMenu(forSelectionType: Project.self) { projects in
            if let project = projects.first, projects.count == 1 {
                RowActionsMenu(actions: rowActions(for: project))
            }
        }
        .overlay {
            if projects.isEmpty {
                ContentUnavailableView.search(text: query)
            }
        }
        .accessibilityIdentifier("chatsList")
    }

    /// Large title with a round New Chat button; content scrolls under a fade.
    func listHeader() -> some View {
        HStack(alignment: .center) {
            Text(DesignSystem.Chats.sidebarTitle)
                .font(.largeTitle.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Button {
                feature.send(.showNewProjectAlert)
            } label: {
                FloatingIcon(systemImage: DesignSystem.Icons.add)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(DesignSystem.Chats.newChat)
            .accessibilityHint(DesignSystem.Chats.newChatHelp)
            .accessibilityInputLabels(DesignSystem.VoiceControl.newChat)
            .accessibilityIdentifier("newChatButton")
        }
        .padding(.horizontal, DesignSystem.Conversation.floatingBarPadding)
        .padding(.top, DesignSystem.Spacing.small)
        .padding(.bottom, DesignSystem.Spacing.small)
        .background(alignment: .top) {
            EdgeFade(edge: .top)
        }
    }

    /// Floating glass search capsule at the bottom, with a round clear button.
    func searchBar() -> some View {
        HStack(spacing: DesignSystem.Spacing.small + DesignSystem.Spacing.xSmall) {
            if isSearching {
                Button {
                    feature.set(\.searchText, to: "")
                    #if os(iOS)
                    isSearchFocused = false
                    #endif
                } label: {
                    FloatingIcon(systemImage: DesignSystem.Icons.close)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(DesignSystem.Conversation.clearSearch)
                .accessibilityInputLabels(DesignSystem.VoiceControl.cancel)
                .accessibilityIdentifier("clearChatSearchButton")
                .transition(.scale.combined(with: .opacity))
            }

            HStack(spacing: DesignSystem.Spacing.small) {
                Image(systemName: DesignSystem.Icons.search)
                    .foregroundStyle(DesignSystem.Colors.supporting)
                    .accessibilityHidden(true)
                TextField(
                    DesignSystem.Conversation.searchField,
                    text: feature.binding(for: \.searchText),
                    prompt: Text(DesignSystem.Conversation.searchField)
                )
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                #if os(iOS)
                .focused($isSearchFocused)
                .submitLabel(.search)
                #endif
                .accessibilityHint(DesignSystem.Conversation.searchFieldHint)
                .accessibilityIdentifier("chatSearchField")
            }
            .padding(.horizontal, DesignSystem.Conversation.floatingBarPadding)
            .frame(minHeight: DesignSystem.Conversation.floatingButtonSize)
            .floatingSurface(in: Capsule())
        }
        .padding(.horizontal, DesignSystem.Conversation.floatingBarPadding)
        .padding(.top, DesignSystem.Spacing.small)
        .padding(.bottom, DesignSystem.Spacing.small)
        .background(alignment: .bottom) {
            EdgeFade(edge: .bottom)
        }
        .animation(.snappy(duration: 0.2), value: isSearching)
    }
    #endif

    func rowActions(for project: Project) -> [RowAction] {
        [
            RowAction(
                id: "rename",
                title: DesignSystem.Chats.renameChat,
                spokenTitle: DesignSystem.Chats.renameChatLabel,
                systemImage: DesignSystem.Icons.rename
            ) {
                feature.send(.showRenameAlert(project))
            },
            RowAction(
                id: "delete",
                title: DesignSystem.Chats.deleteChat,
                spokenTitle: DesignSystem.Chats.deleteChatLabel,
                systemImage: DesignSystem.Icons.delete,
                role: .destructive,
                startsGroup: true
            ) {
                feature.set(\.projectToDelete, to: project)
            }
        ]
    }
}
