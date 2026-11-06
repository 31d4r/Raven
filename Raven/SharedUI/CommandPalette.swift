//
//  CommandPalette.swift
//  Raven
//
//  ⌘K chat switcher: a floating search panel over the dimmed window.
//  Arrow keys choose, Return opens, Escape closes.
//

#if os(macOS)
import RDatabaseManager
import SwiftUI

struct CommandPalette: View {
    @Environment(ProjectsView.ProjectsFeature.self) private var feature
    @Environment(\.colorSchemeContrast) private var contrast
    @FocusState private var isSearchFocused: Bool
    @State private var query = ""
    @State private var highlightedID: Int64?

    private var results: [Project] {
        let projects = feature.value(\.projects)
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return projects }
        return projects.filter { project in
            project.name.localizedStandardContains(term)
                || (project.id.flatMap { feature.value(\.previews)[$0] }?.localizedStandardContains(term) ?? false)
        }
    }

    private var highlightedProject: Project? {
        results.first { $0.id == highlightedID } ?? results.first
    }

    var body: some View {
        ZStack(alignment: .top) {
            DesignSystem.ConversationColors.paletteDim
                .ignoresSafeArea()
                .onTapGesture(perform: dismiss)
                .accessibilityHidden(true)

            panel
                .padding(.top, DesignSystem.Conversation.paletteTopInset)
        }
    }

    private var panel: some View {
        VStack(spacing: 0) {
            searchField
            Divider()
            resultsList
        }
        .frame(width: DesignSystem.Conversation.paletteWidth)
        .background {
            RoundedRectangle(cornerRadius: DesignSystem.Conversation.paletteRadius, style: .continuous)
                .fill(.background)
                .shadow(color: DesignSystem.ConversationColors.shadow, radius: 24, y: 10)
        }
        .overlay {
            RoundedRectangle(cornerRadius: DesignSystem.Conversation.paletteRadius, style: .continuous)
                .strokeBorder(contrast == .increased ? Color.primary : DesignSystem.ConversationColors.composerBorder)
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Conversation.paletteRadius, style: .continuous))
        .onAppear { isSearchFocused = true }
        .onExitCommand(perform: dismiss)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(DesignSystem.Conversation.searchChats)
        .accessibilityAddTraits(.isModal)
        .accessibilityIdentifier("chatSwitcher")
    }

    private var searchField: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            Image(systemName: DesignSystem.Icons.search)
                .font(.title3)
                .foregroundStyle(DesignSystem.Colors.supporting)
                .accessibilityHidden(true)
            TextField(DesignSystem.Conversation.searchChats, text: $query, prompt: Text(DesignSystem.Conversation.searchPrompt))
                .textFieldStyle(.plain)
                .font(.title3)
                .focused($isSearchFocused)
                .onSubmit(openHighlighted)
                .onKeyPress(.upArrow) { moveHighlight(by: -1); return .handled }
                .onKeyPress(.downArrow) { moveHighlight(by: 1); return .handled }
                .onKeyPress(.escape) { dismiss(); return .handled }
                .onChange(of: query) { _, _ in highlightedID = results.first?.id }
                .accessibilityHint(DesignSystem.Conversation.searchHint)
                .accessibilityIdentifier("chatSwitcherSearchField")
            Text(DesignSystem.Shortcuts.escapeKey)
                .font(.caption.monospaced())
                .foregroundStyle(DesignSystem.Colors.supporting)
                .keyCap()
                .accessibilityHidden(true)
        }
        .padding(DesignSystem.Spacing.medium)
    }

    @ViewBuilder
    private var resultsList: some View {
        if results.isEmpty {
            Text(DesignSystem.Conversation.noResults)
                .font(.callout)
                .foregroundStyle(DesignSystem.Colors.supporting)
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.large)
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: DesignSystem.Conversation.sidebarRowSpacing) {
                        ForEach(results, id: \.self) { project in
                            row(project)
                                .id(project.id)
                        }
                    }
                    .padding(DesignSystem.Spacing.small)
                }
                .frame(maxHeight: DesignSystem.Conversation.paletteListMaxHeight)
                .fixedSize(horizontal: false, vertical: true)
                .onChange(of: highlightedID) { _, id in
                    proxy.scrollTo(id)
                }
            }
        }
    }

    private func row(_ project: Project) -> some View {
        let isHighlighted = highlightedProject?.id == project.id
        let preview = project.id.flatMap { feature.value(\.previews)[$0] } ?? DesignSystem.Conversation.noPreview
        let shortcut = feature.value(\.projects).firstIndex(of: project).flatMap { DesignSystem.Shortcuts.chat(at: $0) }

        return Button {
            open(project)
        } label: {
            HStack(spacing: DesignSystem.Conversation.sidebarAvatarToText) {
                ChatAvatar(appearance: ChatAppearanceStore.shared.appearance(for: project), size: DesignSystem.Conversation.paletteAvatarSize)
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.labelToMeta) {
                    Text(project.name)
                        .font(.body.weight(.semibold))
                        .lineLimit(1)
                    Text(preview)
                        .font(.subheadline)
                        .foregroundStyle(DesignSystem.Colors.supporting)
                        .lineLimit(1)
                }
                Spacer(minLength: DesignSystem.Spacing.small)
                if let shortcut {
                    Text(shortcut.display)
                        .font(.caption.monospaced())
                        .foregroundStyle(DesignSystem.Colors.supporting)
                        .keyCap()
                }
            }
            .padding(.horizontal, DesignSystem.Conversation.sidebarRowHorizontalPadding)
            .padding(.vertical, DesignSystem.Spacing.small - DesignSystem.Spacing.labelToMeta)
            .background {
                RoundedRectangle(cornerRadius: DesignSystem.Conversation.paletteRowRadius, style: .continuous)
                    .fill(isHighlighted ? DesignSystem.ConversationColors.selectedRow : .clear)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering { highlightedID = project.id }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(project.name)
        .accessibilityValue(preview)
        .accessibilityAddTraits(isHighlighted ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("chatSwitcherRow_\(String(describing: project.id))")
    }

    private func moveHighlight(by offset: Int) {
        guard !results.isEmpty else { return }
        let current = results.firstIndex { $0.id == highlightedProject?.id } ?? 0
        let next = min(max(current + offset, 0), results.count - 1)
        highlightedID = results[next].id
    }

    private func openHighlighted() {
        if let highlightedProject { open(highlightedProject) }
    }

    private func open(_ project: Project) {
        feature.send(.selectProject(project))
        dismiss()
    }

    private func dismiss() {
        feature.set(\.isSearchPresented, to: false)
    }
}

private extension View {
    func keyCap() -> some View {
        padding(.horizontal, DesignSystem.Spacing.xSmall + 1)
            .padding(.vertical, 1)
            .background {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.keyCap, style: .continuous)
                    .fill(DesignSystem.ConversationColors.inlineCode)
            }
    }
}
#endif
