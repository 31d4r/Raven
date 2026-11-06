//
//  MainContentView.swift
//  Raven
//
//  Created by Eldar Tutnjic on 24.07.25.
//

import MarkdownUI
import PhotosUI
import RDatabaseManager
import SwiftUI
import UniformTypeIdentifiers

struct MainContentView: View {
    let selectedProject: Project?
    
    @Environment(MainContentFeature.self) var feature
    @Environment(ProjectFilesView.ProjectFilesFeature.self) var filesFeature
    @Environment(ProjectsView.ProjectsFeature.self) var projectsFeature
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    @AppStorage(DesignSystem.Storage.showsSourcesInspector) private var showsSources = true
    @FocusState private var isQuestionFieldFocused: Bool
    @State private var isDropTargeted = false
    @State private var pendingAttachments: [PendingAttachment] = []
    @State private var isPreparingPhotos = false
    @State private var hoveredMessageID: Int64?
    @State private var isPhotoPickerPresented = false
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var viewerContent: ImageViewerContent?
    @State private var isFinding = false
    @State private var findText = ""
    @State private var findIndex = 0
    @FocusState private var isFindFieldFocused: Bool
    @AppStorage(DesignSystem.Storage.showsMessageTimes) private var showsMessageTimes = false
    @State private var timeReveal = MessageTimeReveal()
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isFileImporterPresented = false
    @State private var isCameraPresented = false
    @State private var attachDestination: AttachDestination = .sources
    #endif
    @ScaledMetric(relativeTo: .body) private var composerButtonSize = DesignSystem.Conversation.composerButtonSize
    
    var body: some View {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(selectedProject?.name ?? DesignSystem.App.name)
            #if os(macOS)
            .navigationSubtitle(windowSubtitle)
            .toolbar(removing: .title)
            .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
            .photosPicker(
                isPresented: $isPhotoPickerPresented,
                selection: $photoItems,
                selectionBehavior: .ordered,
                matching: .images
            )
            .onChange(of: photoItems) { _, items in
                Task { await loadPhotoAttachments(items) }
            }
            .sheet(item: $viewerContent) { content in
                ImageViewer(content: content)
            }
            #else
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(usesFloatingHeader ? .hidden : .automatic, for: .navigationBar)
            #endif
            .toolbar { toolbarContent() }
            .task(id: selectedProject?.id) {
                feature.send(.loadChat(selectedProject))
                if let selectedProject {
                    filesFeature.send(.loadFiles(selectedProject))
                }
            }
            .onChange(of: feature.value(\.messages).last?.id) { _, _ in
                guard let projectID = selectedProject?.id,
                      feature.value(\.activeProjectID) == projectID else { return }
                projectsFeature.updatePreview(for: projectID, lastMessage: feature.value(\.messages).last)
            }
            .onChange(of: selectedProject?.id) { _, _ in
                clearAttachments()
                hoveredMessageID = nil
                closeFind()
                if let projectName = selectedProject?.name {
                    AccessibilityHelper.announce(DesignSystem.Chat.switchedAnnouncement(projectName))
                }
            }
            #if os(iOS)
            .background { presentationAnchors() }
            .onChange(of: filesFeature.value(\.isFileImporterPresented)) { _, isPresented in
                if isPresented { attachDestination = .sources }
            }
            .onChange(of: filesFeature.value(\.isPhotoPickerPresented)) { _, isPresented in
                if isPresented { attachDestination = .sources }
            }
            .onChange(of: photoItems) { _, items in
                Task { await loadPhotoAttachments(items) }
            }
            .onChange(of: filesFeature.value(\.selectedPhotoItems)) { _, items in
                guard !filesFeature.value(\.isSourcesSheetPresented), !items.isEmpty else { return }
                filesFeature.send(.loadImagesFromGallery(items))
            }
            #endif
    }

    // MARK: - Screens

    @ViewBuilder
    func content() -> some View {
        if let project = selectedProject {
            chatScreen(project)
        } else if projectsFeature.value(\.projects).isEmpty && !projectsFeature.value(\.isLoading) {
            firstChatView()
        } else {
            EmptyStateView(
                artwork: .symbol(DesignSystem.Icons.noChatSelected),
                title: DesignSystem.Chat.noChatTitle,
                message: DesignSystem.Chat.noChatMessage
            )
        }
    }

    func firstChatView() -> some View {
        EmptyStateView(
            artwork: .brand,
            title: DesignSystem.Chat.firstChatTitle,
            message: DesignSystem.Chat.firstChatMessage
        ) {
            #if os(macOS)
            Button(DesignSystem.Chats.newChatEllipsis) {
                projectsFeature.send(.showNewProjectAlert)
            }
            .buttonStyle(.borderedProminent)
            .help(DesignSystem.Help.tooltip(
                DesignSystem.Chats.newChat,
                shortcut: DesignSystem.Shortcuts.newChat,
                detail: DesignSystem.Chats.newChatHelp
            ))
            .accessibilityLabel(DesignSystem.Chats.newChat)
            .accessibilityHint(DesignSystem.Chats.newChatHelp)
            .accessibilityInputLabels(DesignSystem.VoiceControl.newChat)
            .accessibilityIdentifier("createChatButton")
            #endif
        }
    }

    func chatScreen(_ project: Project) -> some View {
        Group {
            if feature.value(\.messages).isEmpty && !feature.value(\.isProcessing) && imageGroups.isEmpty {
                chatEmptyState(project)
            } else {
                conversationView()
                    .overlay { DropHighlight(isTargeted: isDropTargeted) }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #if os(iOS)
        .safeAreaInset(edge: .top, spacing: 0) {
            topBar(project)
        }
        #endif
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomBar(project)
        }
        .fileDrop(isTargeted: $isDropTargeted) { urls, isTemporaryCopy in
            #if os(macOS)
            if feature.value(\.messages).isEmpty && filesFeature.value(\.files).isEmpty {
                filesFeature.send(.addDroppedFiles(urls, isTemporaryCopy: isTemporaryCopy))
            } else {
                addAttachments(urls, isTemporaryCopy: isTemporaryCopy)
            }
            #else
            filesFeature.send(.addDroppedFiles(urls, isTemporaryCopy: isTemporaryCopy))
            #endif
            return true
        }
        #if os(macOS)
        .background(.background)
        #endif
    }

    @ViewBuilder
    func chatEmptyState(_ project: Project) -> some View {
        let fileCount = filesFeature.value(\.files).count
        if case .unavailable(let reason) = feature.modelAvailability {
            EmptyStateView(
                artwork: .symbol(DesignSystem.Icons.unavailable),
                title: DesignSystem.Chat.unavailableTitle,
                message: reason
            )
        } else if fileCount == 0 && !filesFeature.value(\.isLoading) {
            EmptyStateView(
                artwork: .brand,
                title: isDropTargeted ? DesignSystem.Chat.releaseToAdd : DesignSystem.Chat.addSourcesTitle,
                message: DesignSystem.Chat.addSourcesMessage,
                isTargeted: isDropTargeted
            ) {
                #if os(macOS)
                if !showsSources {
                    Button(DesignSystem.Sources.addSources) {
                        filesFeature.presentFileImporter()
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
                }
                #else
                Button(DesignSystem.Sources.addFiles) {
                    filesFeature.presentFileImporter()
                }
                .buttonStyle(.borderedProminent)
                .accessibilityHint(DesignSystem.Sources.addFilesDetail)
                .accessibilityInputLabels(DesignSystem.VoiceControl.addSources)
                .accessibilityIdentifier("addFilesButton")

                Button(DesignSystem.Sources.addPhotos) {
                    filesFeature.set(\.isPhotoPickerPresented, to: true)
                }
                .buttonStyle(.bordered)
                .accessibilityHint(DesignSystem.Sources.addPhotosDetail)
                .accessibilityInputLabels(DesignSystem.VoiceControl.addPhotos)
                .accessibilityIdentifier("addPhotosButton")
                #endif
            }
        } else {
            EmptyStateView(
                artwork: .brand,
                title: isDropTargeted ? DesignSystem.Chat.releaseToAdd : DesignSystem.Chat.askTitle,
                message: DesignSystem.Chat.askMessage(fileCount),
                isTargeted: isDropTargeted
            )
        }
    }

    // MARK: - Conversation

    var appearance: ChatAppearance {
        ChatAppearanceStore.shared.appearance(for: selectedProject)
    }
    
    func conversationView() -> some View {
        let items = conversationItems
        return ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: DesignSystem.Conversation.messageSpacing) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        if showsTimestamp(at: index, in: items) {
                            timestampSeparator(item.date)
                                .padding(.top, index == 0 ? 0 : DesignSystem.Spacing.small)
                        }
                        switch item {
                        case .message(let message):
                            messageRow(message)
                                .messageTimeGutter(item.date, reveal: timeRevealState)
                                .id(message.id)
                        case .images(let group, let urls):
                            ImageStack(urls: urls) { index in
                                viewerContent = ImageViewerContent(urls: urls, startIndex: index)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            #if os(macOS)
                            .accessibilityValue(DesignSystem.Conversation.sentImagesTime(
                                DesignSystem.Conversation.spokenMessageTime(group.date)
                            ))
                            #endif
                            .messageTimeGutter(item.date, reveal: timeRevealState)
                            .id(group.id)
                        }
                    }

                    if feature.value(\.isProcessing) {
                        thinkingRow()
                            .id(Constants.thinkingID)
                            .transition(.opacity)
                    }
                }
                .padding(DesignSystem.Spacing.contentPadding)
                .frame(maxWidth: DesignSystem.Layout.readableContentWidth)
                .frame(maxWidth: .infinity)
            }
            .defaultScrollAnchor(.bottom)
            .scrollDismissesKeyboard(.interactively)
            #if os(iOS)
            .scrollEdgeEffectStyle(.soft, for: .top)
            .gesture(MessageTimePan(
                isEnabled: !showsMessageTimes,
                onDrag: { delta in timeReveal.drag(by: delta, reduceMotion: reduceMotion) },
                onRelease: { timeReveal.release(reduceMotion: reduceMotion) }
            ))
            .sensoryFeedback(.selection, trigger: timeReveal.isFullyOpen(reduceMotion: reduceMotion)) { _, isOpen in isOpen }
            #else
            .background {
                HorizontalSwipeMonitor(
                    isEnabled: !showsMessageTimes,
                    onTouch: { timeReveal.touchDown() },
                    onDrag: { delta in timeReveal.drag(by: delta, reduceMotion: reduceMotion) },
                    onRelease: { timeReveal.release(reduceMotion: reduceMotion) }
                )
            }
            #endif
            .onChange(of: items.count) { _, _ in
                scrollToEnd(proxy)
            }
            .onChange(of: feature.value(\.isProcessing)) { _, _ in
                scrollToEnd(proxy)
            }
            .onChange(of: currentFindMatchID) { _, id in
                guard let id else { return }
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) {
                    proxy.scrollTo(id, anchor: .center)
                }
            }
        }
    }

    /// Swipe state and the View menu pin for the message time gutter (Mac only).
    var timeRevealState: MessageTimeGutterState {
        MessageTimeGutterState(reveal: timeReveal, isPinned: showsMessageTimes)
    }

    /// Bot typing: on iPhone and iPad the chat avatar leads the dots.
    @ViewBuilder
    func thinkingRow() -> some View {
        #if os(iOS)
        HStack(alignment: .center, spacing: DesignSystem.Spacing.small) {
            ChatAvatar(appearance: appearance, size: DesignSystem.Conversation.titleAvatarSize)
                .accessibilityHidden(true)
            TypingIndicator(color: appearance.color.accent)
        }
        #else
        TypingIndicator(color: appearance.color.accent)
        #endif
    }

    // MARK: - Sent images

    /// Image groups sent in this chat (side storage; see MessageAttachmentStore).
    var imageGroups: [ImageGroup] {
        MessageAttachmentStore.shared.groups(for: selectedProject?.id)
    }

    /// Messages with sent image groups slotted in before the first message
    /// written at or after each group's send time. Groups whose files were
    /// all removed from the chat's sources are skipped.
    var conversationItems: [ConversationItem] {
        let messages = feature.value(\.messages)
        let groups = imageGroups
        guard !groups.isEmpty else { return messages.map { ConversationItem.message($0) } }

        var urlsByID: [Int64: URL] = [:]
        for file in filesFeature.value(\.files) {
            if let id = file.id {
                urlsByID[id] = URL(fileURLWithPath: file.publicPath)
            }
        }
        var pending: [ConversationItem] = groups
            .sorted { $0.date < $1.date }
            .compactMap { group in
                let urls = group.fileIDs.compactMap { urlsByID[$0] }
                return urls.isEmpty ? nil : .images(group, urls)
            }
        var items: [ConversationItem] = []
        items.reserveCapacity(messages.count + pending.count)
        for message in messages {
            while let next = pending.first, next.date <= message.createdAt {
                items.append(next)
                pending.removeFirst()
            }
            items.append(.message(message))
        }
        items += pending
        return items
    }

    // MARK: - Find in chat

    var trimmedFindText: String {
        findText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var findMatches: [ChatMessage] {
        let query = trimmedFindText
        guard isFinding, !query.isEmpty else { return [] }
        return feature.value(\.messages).filter { $0.content.localizedStandardContains(query) }
    }

    var currentFindMatchID: ChatMessage.ID? {
        let matches = findMatches
        guard matches.indices.contains(findIndex) else { return nil }
        return matches[findIndex].id
    }

    func startFind() {
        findText = ""
        findIndex = 0
        isFinding = true
        isFindFieldFocused = true
    }

    func closeFind() {
        isFinding = false
        findText = ""
        findIndex = 0
        isFindFieldFocused = false
    }

    func stepFind(_ delta: Int) {
        let count = findMatches.count
        guard count > 0 else { return }
        findIndex = (findIndex + delta + count) % count
        AccessibilityHelper.announce(DesignSystem.Conversation.findAnnouncement(findIndex + 1, count))
    }

    /// Newest match first, like the find bar in Messages.
    func findTextChanged() {
        let count = findMatches.count
        findIndex = max(count - 1, 0)
        guard !trimmedFindText.isEmpty else { return }
        AccessibilityHelper.announce(count == 0
            ? DesignSystem.Conversation.findNoMatches
            : DesignSystem.Conversation.findAnnouncement(findIndex + 1, count))
    }

    func highlighted(_ text: String) -> AttributedString {
        var attributed = AttributedString(text)
        let query = trimmedFindText
        guard isFinding, !query.isEmpty else { return attributed }
        var searchStart = attributed.startIndex
        while searchStart < attributed.endIndex,
              let range = attributed[searchStart...].range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) {
            attributed[range].backgroundColor = DesignSystem.ConversationColors.findMatch
            searchStart = range.upperBound
        }
        return attributed
    }

    @ViewBuilder
    func findRing(for message: ChatMessage) -> some View {
        if isFinding, findMatches.contains(where: { $0.id == message.id }) {
            let isCurrent = message.id == currentFindMatchID
            RoundedRectangle(cornerRadius: DesignSystem.Conversation.bubbleRadius, style: .continuous)
                .strokeBorder(
                    isCurrent ? DesignSystem.ConversationColors.findCurrentMatch : DesignSystem.ConversationColors.findMatch,
                    lineWidth: DesignSystem.Conversation.findMatchRing * (isCurrent ? 1.5 : 1)
                )
                .accessibilityHidden(true)
        }
    }

    func scrollToEnd(_ proxy: ScrollViewProxy) {
        let target: AnyHashable? = feature.value(\.isProcessing)
            ? AnyHashable(Constants.thinkingID)
            : feature.value(\.messages).last.map { AnyHashable($0.id) }
        guard let target else { return }
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) {
            proxy.scrollTo(target, anchor: .bottom)
        }
    }

    /// A separator starts each day and follows any long pause.
    func showsTimestamp(at index: Int, in items: [ConversationItem]) -> Bool {
        guard index > 0 else { return true }
        let previous = items[index - 1].date
        let current = items[index].date
        return !Calendar.current.isDate(previous, inSameDayAs: current)
            || current.timeIntervalSince(previous) > DesignSystem.Conversation.timestampGap
    }

    func timestampSeparator(_ date: Date) -> some View {
        let time = date.formatted(date: .omitted, time: .shortened)
        let calendar = Calendar.current
        let label = if calendar.isDateInToday(date) {
            DesignSystem.Conversation.today(time)
        } else if calendar.isDateInYesterday(date) {
            DesignSystem.Conversation.yesterday(time)
        } else {
            DesignSystem.Conversation.otherDay(date.formatted(date: .abbreviated, time: .omitted), time)
        }
        return Text(label)
            .font(.caption.weight(.medium))
            .foregroundStyle(DesignSystem.Colors.supporting)
            .frame(maxWidth: .infinity)
            .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    func messageRow(_ message: ChatMessage) -> some View {
        Group {
            if message.role == .user {
                userBubble(message)
            } else {
                assistantReply(message)
            }
        }
        .contextMenu {
            Button(DesignSystem.Common.copy, systemImage: DesignSystem.Icons.copy) {
                feature.send(.copyMessage(message))
            }
            if message.role == .assistant {
                ShareLink(item: message.content) {
                    Label(DesignSystem.Conversation.share, systemImage: DesignSystem.Icons.share)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(messageAccessibilityLabel(message))
        .accessibilityValue(message.content)
        .accessibilityAction(named: Text(DesignSystem.Common.copy)) {
            feature.send(.copyMessage(message))
        }
    }

    /// Who wrote the message; on Mac also when, so VoiceOver gets the time without the swipe.
    func messageAccessibilityLabel(_ message: ChatMessage) -> String {
        let speaker = message.role == .user ? DesignSystem.Chat.userMessageLabel : DesignSystem.Chat.assistantMessageLabel
        #if os(macOS)
        return DesignSystem.Conversation.messageLabel(speaker, DesignSystem.Conversation.spokenMessageTime(message.createdAt))
        #else
        return speaker
        #endif
    }

    func userBubble(_ message: ChatMessage) -> some View {
        HStack {
            Spacer(minLength: DesignSystem.Conversation.userBubbleLeadingInset)
            Text(highlighted(message.content))
                .textSelection(.enabled)
                .foregroundStyle(.white)
                .padding(.horizontal, DesignSystem.Conversation.bubbleHorizontalPadding)
                .padding(.vertical, DesignSystem.Conversation.bubbleVerticalPadding)
                .background {
                    RoundedRectangle(cornerRadius: DesignSystem.Conversation.bubbleRadius, style: .continuous)
                        .fill(appearance.color.bubbleFill(increasedContrast: contrast == .increased))
                }
                .overlay { findRing(for: message) }
                .frame(maxWidth: DesignSystem.Conversation.bubbleMaxWidth, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    func assistantReply(_ message: ChatMessage) -> some View {
        HStack(alignment: .bottom, spacing: DesignSystem.Spacing.small) {
            Markdown(message.content)
                .markdownTheme(.raven)
                .markdownCodeSyntaxHighlighter(RavenCodeHighlighter())
                .textSelection(.enabled)
                .padding(.horizontal, DesignSystem.Conversation.bubbleHorizontalPadding)
                .padding(.vertical, DesignSystem.Conversation.bubbleVerticalPadding + DesignSystem.Spacing.labelToMeta)
                .background {
                    RoundedRectangle(cornerRadius: DesignSystem.Conversation.bubbleRadius, style: .continuous)
                        .fill(DesignSystem.ConversationColors.assistantBubble)
                }
                .overlay {
                    if contrast == .increased {
                        RoundedRectangle(cornerRadius: DesignSystem.Conversation.bubbleRadius, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.4), lineWidth: 1)
                    }
                }
                .overlay { findRing(for: message) }
                .frame(maxWidth: DesignSystem.Conversation.bubbleMaxWidth, alignment: .leading)

            #if os(macOS)
            hoverActions(message)
                .opacity(hoveredMessageID == message.id ? 1 : 0)
                .allowsHitTesting(hoveredMessageID == message.id)
            #endif

            Spacer(minLength: DesignSystem.Conversation.assistantTrailingInset)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        #if os(macOS)
        .onHover { hovering in
            if hovering {
                hoveredMessageID = message.id
            } else if hoveredMessageID == message.id {
                hoveredMessageID = nil
            }
        }
        #endif
    }

    #if os(macOS)
    /// Copy and More appear beside an answer on hover. VoiceOver and Voice
    /// Control reach the same commands through the message’s actions.
    func hoverActions(_ message: ChatMessage) -> some View {
        HStack(spacing: DesignSystem.Conversation.hoverBarSpacing) {
            Button {
                feature.send(.copyMessage(message))
            } label: {
                hoverIcon(DesignSystem.Icons.copy)
            }
            .buttonStyle(.plain)
            .help(DesignSystem.Common.copy)

            Menu {
                Button(DesignSystem.Common.copy, systemImage: DesignSystem.Icons.copy) {
                    feature.send(.copyMessage(message))
                }
                ShareLink(item: message.content) {
                    Label(DesignSystem.Conversation.share, systemImage: DesignSystem.Icons.share)
                }
            } label: {
                hoverIcon("ellipsis")
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .fixedSize()
            .help(DesignSystem.Conversation.messageActions)
        }
        .accessibilityHidden(true)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: hoveredMessageID)
    }

    func hoverIcon(_ systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.callout)
            .foregroundStyle(DesignSystem.Colors.supporting)
            .frame(width: DesignSystem.Conversation.hoverButtonSize, height: DesignSystem.Conversation.hoverButtonSize)
            .contentShape(Rectangle())
    }
    #endif

    // MARK: - Bottom bar

    func bottomBar(_ project: Project) -> some View {
        VStack(spacing: 0) {
            if let count = filesFeature.value(\.recentlyAddedCount) {
                StatusBanner(message: DesignSystem.Sources.added(count)) {
                    filesFeature.send(.dismissAddedBanner)
                }
                .transition(reduceMotion ? .opacity : DesignSystem.Motion.bannerTransition)
            }

            if filesFeature.value(\.isImportingPhotos) {
                ActivityBar(message: DesignSystem.Sources.addingPhotos, spokenMessage: DesignSystem.Sources.addingPhotosLabel)
            }

            composer(project)
        }
        .animation(reduceMotion ? nil : .snappy(duration: 0.25), value: filesFeature.value(\.recentlyAddedCount))
        .animation(reduceMotion ? nil : .snappy(duration: 0.25), value: feature.value(\.isProcessing))
    }

    var unavailableReason: String? {
        if case .unavailable(let reason) = feature.modelAvailability { reason } else { nil }
    }

    /// Text sends a question; attachments alone are just added as sources.
    func composerSendReason(for project: Project) -> String? {
        let reason = feature.sendUnavailableReason(for: project)
        if reason == DesignSystem.Chat.emptyQuestionReason && !pendingAttachments.isEmpty {
            return nil
        }
        return reason
    }

    func composer(_ project: Project) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            if let unavailableReason, !feature.value(\.messages).isEmpty {
                Label(unavailableReason, systemImage: DesignSystem.Icons.warning)
                    .font(.footnote)
                    .foregroundStyle(DesignSystem.Colors.supporting)
                    .padding(.horizontal, DesignSystem.Spacing.small)
            }

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                if !pendingAttachments.isEmpty || isPreparingPhotos {
                    attachmentsRow()
                }

                HStack(alignment: .bottom, spacing: DesignSystem.Spacing.small) {
                    addMenu()

                    TextField(
                        DesignSystem.Chat.questionLabel,
                        text: feature.binding(for: \.questionText),
                        prompt: Text(questionPrompt(for: project)),
                        axis: .vertical
                    )
                    .lineLimit(1...6)
                    .textFieldStyle(.plain)
                    .padding(.vertical, DesignSystem.Spacing.xSmall + 1)
                    .submitLabel(.send)
                    .focused($isQuestionFieldFocused)
                    .disabled(feature.value(\.isProcessing) || unavailableReason != nil)
                    .accessibilityHint(unavailableReason ?? DesignSystem.Chat.questionHint)
                    .accessibilityIdentifier("questionTextField")
                    .onSubmit {
                        send(project)
                    }

                    if feature.value(\.isProcessing) {
                        stopButton()
                    } else {
                        sendButton(project)
                    }
                }
            }
            .padding(DesignSystem.Conversation.composerInnerPadding)
            .background {
                RoundedRectangle(cornerRadius: DesignSystem.Conversation.composerRadius, style: .continuous)
                    .fill(.background)
                    .shadow(color: DesignSystem.ConversationColors.shadow, radius: 8, y: 2)
            }
            .overlay {
                RoundedRectangle(cornerRadius: DesignSystem.Conversation.composerRadius, style: .continuous)
                    .strokeBorder(contrast == .increased ? Color.primary : DesignSystem.ConversationColors.composerBorder)
            }
        }
        .padding(.horizontal, DesignSystem.Conversation.composerOuterPadding)
        .padding(.top, DesignSystem.Spacing.small)
        .padding(.bottom, DesignSystem.Conversation.composerOuterPadding - DesignSystem.Spacing.xSmall)
        .frame(maxWidth: DesignSystem.Layout.readableContentWidth)
        .frame(maxWidth: .infinity)
        .background(.background)
        .onChange(of: feature.value(\.isProcessing)) { wasProcessing, isProcessing in
            if wasProcessing && !isProcessing {
                isQuestionFieldFocused = true
            }
        }
    }

    func questionPrompt(for project: Project) -> String {
        #if os(iOS)
        DesignSystem.Conversation.ask(project.name)
        #else
        DesignSystem.Chat.questionPrompt
        #endif
    }

    func attachmentsRow() -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: DesignSystem.Spacing.small) {
                ForEach(pendingAttachments) { attachment in
                    AttachmentChip(attachment: attachment) {
                        removeAttachment(attachment)
                    }
                }
                if isPreparingPhotos {
                    ProgressView()
                        .controlSize(.small)
                        .frame(width: DesignSystem.Conversation.attachmentSize, height: DesignSystem.Conversation.attachmentSize)
                        .help(DesignSystem.Conversation.preparingPhotos)
                        .accessibilityLabel(DesignSystem.Conversation.preparingPhotosLabel)
                }
            }
            .padding(DesignSystem.Spacing.xSmall)
        }
        .scrollIndicators(.never)
        .accessibilityElement(children: .contain)
    }

    func addMenu() -> some View {
        Menu {
            #if os(iOS)
            Button {
                attachDestination = .composer
                isPhotoPickerPresented = true
            } label: {
                Label(DesignSystem.Conversation.photoOrVideo, systemImage: DesignSystem.Icons.photoLibrary)
            }
            .accessibilityInputLabels(DesignSystem.VoiceControl.addPhotos)
            .accessibilityIdentifier("addPhotosMenuItem")

            if CameraPicker.isAvailable {
                Button {
                    attachDestination = .composer
                    isCameraPresented = true
                } label: {
                    Label(DesignSystem.Conversation.takePhoto, systemImage: DesignSystem.Icons.camera)
                }
                .accessibilityIdentifier("takePhotoMenuItem")
            }

            Button {
                attachDestination = .composer
                isFileImporterPresented = true
            } label: {
                Label(DesignSystem.Conversation.chooseFile, systemImage: DesignSystem.Icons.chooseFile)
            }
            .accessibilityInputLabels(DesignSystem.VoiceControl.addSources)
            .accessibilityIdentifier("attachFilesMenuItem")
            #else
            Button {
                Task { addAttachments(await filesFeature.chooseFiles(), isTemporaryCopy: false) }
            } label: {
                Label(DesignSystem.Conversation.attachFiles, systemImage: DesignSystem.Icons.attach)
            }
            .accessibilityInputLabels(DesignSystem.VoiceControl.addSources)
            .accessibilityIdentifier("attachFilesMenuItem")

            Button {
                isPhotoPickerPresented = true
            } label: {
                Label(DesignSystem.Sources.addPhotos, systemImage: DesignSystem.Icons.addPhotos)
            }
            .accessibilityInputLabels(DesignSystem.VoiceControl.addPhotos)
            .accessibilityIdentifier("addPhotosMenuItem")
            #endif
        } label: {
            Image(systemName: DesignSystem.Icons.add)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: composerButtonSize, height: composerButtonSize)
                .background(Circle().fill(DesignSystem.ConversationColors.assistantBubble))
                .contentShape(Circle())
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
        .help(DesignSystem.Help.tooltip(DesignSystem.Conversation.addMenu, detail: DesignSystem.Conversation.addMenuDetail))
        .accessibilityLabel(DesignSystem.Conversation.addMenu)
        .accessibilityHint(DesignSystem.Conversation.addMenuDetail)
        .accessibilityInputLabels(DesignSystem.VoiceControl.addSources)
        .accessibilityIdentifier("attachMenuButton")
    }

    func sendButton(_ project: Project) -> some View {
        let reason = composerSendReason(for: project)
        let detail = feature.value(\.questionText).isEmpty && !pendingAttachments.isEmpty
            ? DesignSystem.Conversation.attachmentsReady
            : DesignSystem.Chat.sendDetail
        return Button {
            send(project)
        } label: {
            composerCircle(
                systemImage: DesignSystem.Icons.send,
                fill: reason == nil ? AnyShapeStyle(appearance.color.bubbleFill(increasedContrast: contrast == .increased)) : AnyShapeStyle(DesignSystem.ConversationColors.inlineCode),
                foreground: reason == nil ? AnyShapeStyle(.white) : AnyShapeStyle(DesignSystem.Colors.supporting)
            )
        }
        .buttonStyle(.plain)
        .disabled(reason != nil)
        .help(DesignSystem.Help.tooltip(
            DesignSystem.Chat.send,
            shortcut: DesignSystem.Shortcuts.sendQuestion,
            detail: reason ?? detail
        ))
        .accessibilityLabel(DesignSystem.Chat.send)
        .accessibilityHint(reason ?? detail)
        .accessibilityInputLabels(DesignSystem.VoiceControl.send)
        .accessibilityIdentifier("sendQuestionButton")
    }

    func stopButton() -> some View {
        Button {
            feature.send(.cancelProcessing)
        } label: {
            composerCircle(
                systemImage: DesignSystem.Icons.stop,
                fill: AnyShapeStyle(Color.primary),
                foreground: AnyShapeStyle(.background)
            )
        }
        .buttonStyle(.plain)
        .help(DesignSystem.Help.tooltip(DesignSystem.Conversation.stop, shortcut: DesignSystem.Shortcuts.cancelAnswer))
        .accessibilityLabel(DesignSystem.Conversation.stop)
        .accessibilityInputLabels(DesignSystem.VoiceControl.cancel)
        .accessibilityIdentifier("cancelAnswerButton")
    }

    func composerCircle(systemImage: String, fill: AnyShapeStyle, foreground: AnyShapeStyle) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: composerButtonSize * 0.45, weight: .bold))
            .foregroundStyle(foreground)
            .frame(width: composerButtonSize, height: composerButtonSize)
            .background(Circle().fill(fill))
            .contentShape(Circle())
    }

    // MARK: - Attachments

    func send(_ project: Project) {
        guard composerSendReason(for: project) == nil else { return }
        let attachments = pendingAttachments
        pendingAttachments = []
        let hasQuestion = feature.sendUnavailableReason(for: project) == nil
        let sentAt = Date()
        Task {
            let permanent = await filesFeature.attach(attachments.filter { !$0.isTemporaryCopy }.map(\.url), isTemporaryCopy: false)
            let temporary = await filesFeature.attach(attachments.filter(\.isTemporaryCopy).map(\.url), isTemporaryCopy: true)
            let imageIDs = (permanent + temporary)
                .filter { Self.isImage($0) }
                .compactMap(\.id)
            if let projectID = project.id, !imageIDs.isEmpty {
                MessageAttachmentStore.shared.record(imageIDs, in: projectID, at: sentAt)
            }
            if hasQuestion {
                feature.submitQuestion(for: project)
            }
        }
    }

    static func isImage(_ record: FileRecord) -> Bool {
        UTType(filenameExtension: URL(fileURLWithPath: record.publicPath).pathExtension)?.conforms(to: .image) ?? false
    }

    func addAttachments(_ urls: [URL], isTemporaryCopy: Bool) {
        let supported = urls.filter { ProjectFilesView.isSupported($0) }
        if supported.count < urls.count {
            filesFeature.set(\.errorMessage, to: DesignSystem.Errors.unsupportedDrop)
            if isTemporaryCopy {
                for url in urls where !supported.contains(url) {
                    PendingAttachment(url: url, isTemporaryCopy: true).discard()
                }
            }
        }
        let known = Set(pendingAttachments.map(\.url))
        pendingAttachments += supported
            .filter { !known.contains($0) }
            .map { PendingAttachment(url: $0, isTemporaryCopy: isTemporaryCopy) }
        if !supported.isEmpty {
            isQuestionFieldFocused = true
        }
    }

    func removeAttachment(_ attachment: PendingAttachment) {
        attachment.discard()
        pendingAttachments.removeAll { $0.id == attachment.id }
    }

    func clearAttachments() {
        pendingAttachments.forEach { $0.discard() }
        pendingAttachments = []
    }

    func loadPhotoAttachments(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        isPreparingPhotos = true
        var failed = false
        for item in items {
            #if os(iOS)
            if item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) }) {
                if let movie = try? await item.loadTransferable(type: PickedMovie.self) {
                    pendingAttachments.append(PendingAttachment(url: movie.url, isTemporaryCopy: true))
                } else {
                    failed = true
                }
                continue
            }
            #endif
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let attachment = try? PendingAttachment.temporaryCopy(of: Self.jpegData(data), fileExtension: "jpg") else {
                failed = true
                continue
            }
            pendingAttachments.append(attachment)
        }
        isPreparingPhotos = false
        photoItems = []
        if failed {
            filesFeature.set(\.errorMessage, to: DesignSystem.Errors.addPhotosFailed)
        }
        #if os(iOS)
        if !pendingAttachments.isEmpty {
            isQuestionFieldFocused = true
        }
        #endif
    }

    /// Library photos usually arrive as HEIC; store real JPEG data behind the
    /// .jpg name so the file and its extension agree.
    static func jpegData(_ data: Data) -> Data {
        #if os(iOS)
        UIImage(data: data)?.jpegData(compressionQuality: 0.9) ?? data
        #else
        data
        #endif
    }

    #if os(iOS)
    /// Files from the Files app are copied while their security scope is
    /// open, so the chips and the later import never depend on it.
    func importChosenFiles(_ result: Result<[URL], any Error>) {
        let urls: [URL]
        switch result {
        case .success(let chosen):
            urls = chosen
        case .failure:
            filesFeature.set(\.errorMessage, to: DesignSystem.Errors.addSourcesFailed)
            return
        }
        guard !urls.isEmpty else { return }
        var copies: [URL] = []
        var failed = false
        for url in urls {
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasAccess { url.stopAccessingSecurityScopedResource() }
            }
            let folder = URL.temporaryDirectory
                .appending(path: "Raven-Attachments", directoryHint: .isDirectory)
                .appending(path: UUID().uuidString, directoryHint: .isDirectory)
            let copy = folder.appending(path: url.lastPathComponent)
            do {
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                try FileManager.default.copyItem(at: url, to: copy)
                copies.append(copy)
            } catch {
                try? FileManager.default.removeItem(at: folder)
                failed = true
            }
        }
        addAttachments(copies, isTemporaryCopy: true)
        if failed {
            filesFeature.set(\.errorMessage, to: DesignSystem.Errors.addSourcesFailed)
        }
    }

    func addCapturedPhoto(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.9),
              let attachment = try? PendingAttachment.temporaryCopy(of: data, fileExtension: "jpg") else {
            filesFeature.set(\.errorMessage, to: DesignSystem.Errors.addPhotosFailed)
            return
        }
        pendingAttachments.append(attachment)
        isQuestionFieldFocused = true
    }
    #endif

    // MARK: - Toolbar

    @ToolbarContentBuilder
    func toolbarContent() -> some ToolbarContent {
        if let project = selectedProject {
            #if os(macOS)
            ToolbarItem(placement: .principal) {
                titlePill(project)
            }
            ToolbarItem(placement: .primaryAction) {
                moreMenu(project)
            }
            ToolbarItem(placement: .primaryAction) {
                sourcesToggle()
            }
            #else
            ToolbarItem(placement: .principal) {
                titlePill(project)
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    filesFeature.set(\.isSourcesSheetPresented, to: true)
                } label: {
                    Label(DesignSystem.Sources.title, systemImage: DesignSystem.Icons.sources)
                }
                .accessibilityHint(DesignSystem.Sources.toggleDetail)
                .accessibilityInputLabels(DesignSystem.VoiceControl.sources)
                .accessibilityIdentifier("toggleInspectorButton")
            }
            ToolbarItem(placement: .primaryAction) {
                moreMenu(project)
            }
            #endif
        }
    }

    /// Centered chat identity: avatar and name in a soft capsule.
    func titlePill(_ project: Project) -> some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            ChatAvatar(appearance: appearance, size: DesignSystem.Conversation.titleAvatarSize)
            Text(project.name)
                .font(.headline)
                .lineLimit(1)
        }
        .padding(.leading, DesignSystem.Spacing.xSmall)
        .padding(.trailing, DesignSystem.Spacing.small + DesignSystem.Spacing.xSmall)
        .padding(.vertical, DesignSystem.Spacing.xSmall)
        #if os(macOS)
        .help(windowSubtitle)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityValue(spokenWindowSubtitle)
        #else
        .frame(minHeight: DesignSystem.Conversation.floatingButtonSize)
        .floatingSurface(in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        #endif
        .accessibilityIdentifier("chatTitlePill")
    }

    #if os(macOS)

    func sourcesToggle() -> some View {
        let title = showsSources ? DesignSystem.Sources.hide : DesignSystem.Sources.show
        return Button {
            showsSources.toggle()
        } label: {
            Label(title, systemImage: DesignSystem.Icons.inspector)
                .labelStyle(.titleAndIcon)
        }
        .help(DesignSystem.Help.tooltip(
            title,
            shortcut: DesignSystem.Shortcuts.toggleSources,
            detail: DesignSystem.Sources.toggleDetail
        ))
        .accessibilityHint(DesignSystem.Sources.toggleDetail)
        .accessibilityInputLabels(DesignSystem.VoiceControl.sources)
        .accessibilityIdentifier("toggleInspectorButton")
    }
    #endif

    func moreMenu(_ project: Project, isFloating: Bool = false) -> some View {
        let copyReason = feature.copyResponseUnavailableReason(for: project)
        let clearReason = feature.clearHistoryUnavailableReason(for: project)
        return Menu {
            #if os(iOS)
            Button {
                filesFeature.set(\.isSourcesSheetPresented, to: true)
            } label: {
                Label(DesignSystem.Conversation.chatSources, systemImage: DesignSystem.Icons.sources)
            }
            .accessibilityInputLabels(DesignSystem.VoiceControl.sources)
            .accessibilityIdentifier("chatSourcesMenuItem")

            Button {
                startFind()
            } label: {
                Label(DesignSystem.Conversation.findInChat, systemImage: DesignSystem.Icons.search)
            }
            .disabled(feature.value(\.messages).isEmpty)
            .accessibilityIdentifier("findInChatMenuItem")

            ShareLink(item: transcript(for: project)) {
                Label(DesignSystem.Conversation.shareChat, systemImage: DesignSystem.Icons.share)
            }
            .disabled(feature.value(\.messages).isEmpty)
            .accessibilityIdentifier("shareChatMenuItem")

            Toggle(isOn: $showsMessageTimes) {
                Label(DesignSystem.Menu.showMessageTimes, systemImage: DesignSystem.Icons.messageTimes)
            }
            .accessibilityIdentifier("showMessageTimesMenuItem")

            Divider()
            #endif

            Button {
                feature.send(.copyResponse)
            } label: {
                menuLabel(DesignSystem.Chat.copyResponse, systemImage: DesignSystem.Icons.copy, reason: copyReason)
            }
            .disabled(copyReason != nil)
            .accessibilityInputLabels(DesignSystem.VoiceControl.copyResponse)
            .accessibilityIdentifier("copyResponseButton")

            Divider()

            Button {
                projectsFeature.send(.showRenameAlert(project))
            } label: {
                menuLabel(DesignSystem.Chats.renameChat, systemImage: DesignSystem.Icons.rename, reason: nil)
            }

            Divider()

            Button(role: .destructive) {
                feature.set(\.isConfirmingClearHistory, to: true)
            } label: {
                menuLabel(DesignSystem.Chat.clearHistory, systemImage: DesignSystem.Icons.clearHistory, reason: clearReason)
            }
            .disabled(clearReason != nil)
            .help(DesignSystem.Help.tooltip(
                DesignSystem.Chat.clearHistory,
                shortcut: DesignSystem.Shortcuts.clearHistory,
                detail: clearReason ?? DesignSystem.Chat.clearHistoryDetail
            ))
            .accessibilityInputLabels(DesignSystem.VoiceControl.clearHistory)
            .accessibilityIdentifier("clearResponseButton")

            Button(role: .destructive) {
                projectsFeature.set(\.projectToDelete, to: project)
            } label: {
                menuLabel(DesignSystem.Chats.deleteChat, systemImage: DesignSystem.Icons.delete, reason: nil)
            }
        } label: {
            if isFloating {
                FloatingIcon(systemImage: DesignSystem.Icons.ellipsis)
                    .accessibilityLabel(DesignSystem.Common.more)
            } else {
                Label(DesignSystem.Common.more, systemImage: DesignSystem.Icons.more)
            }
        }
        .help(DesignSystem.Common.moreHelp)
        .accessibilityHint(DesignSystem.Common.moreHelp)
        .accessibilityInputLabels(DesignSystem.VoiceControl.more)
        .accessibilityIdentifier("chatMoreMenu")
    }

    @ViewBuilder
    func menuLabel(_ title: String, systemImage: String, reason: String?) -> some View {
        #if os(iOS)
        if let reason {
            Label {
                Text(title)
                Text(reason)
            } icon: {
                Image(systemName: systemImage)
            }
        } else {
            Label(title, systemImage: systemImage)
        }
        #else
        Label(title, systemImage: systemImage)
        #endif
    }

    // MARK: - iOS floating header and find bar

    #if os(iOS)
    /// iPhone hides the navigation bar for floating glass controls.
    var usesFloatingHeader: Bool {
        selectedProject != nil && horizontalSizeClass == .compact
    }

    func transcript(for project: Project) -> String {
        feature.value(\.messages)
            .map { message in
                DesignSystem.Conversation.transcriptLine(
                    message.role == .user ? DesignSystem.Conversation.transcriptYou : project.name,
                    message.content
                )
            }
            .joined(separator: "\n\n")
    }

    @ViewBuilder
    func topBar(_ project: Project) -> some View {
        if usesFloatingHeader || isFinding {
            VStack(spacing: DesignSystem.Spacing.small) {
                if usesFloatingHeader {
                    floatingHeader(project)
                }
                if isFinding {
                    findBar()
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.horizontal, DesignSystem.Conversation.floatingBarPadding)
            .padding(.top, DesignSystem.Spacing.xSmall)
            .padding(.bottom, DesignSystem.Spacing.small)
            .background(alignment: .top) {
                EdgeFade(edge: .top)
            }
            .animation(reduceMotion ? nil : .snappy(duration: 0.2), value: isFinding)
        }
    }

    func floatingHeader(_ project: Project) -> some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            Button {
                projectsFeature.set(\.selectedProject, to: nil)
            } label: {
                FloatingIcon(systemImage: DesignSystem.Icons.back)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(DesignSystem.Conversation.back)
            .accessibilityInputLabels([DesignSystem.Conversation.back, DesignSystem.Chats.sidebarTitle])
            .accessibilityIdentifier("backToChatsButton")

            Spacer(minLength: 0)
            titlePill(project)
                .layoutPriority(1)
            Spacer(minLength: 0)

            moreMenu(project, isFloating: true)
        }
    }

    func findBar() -> some View {
        let matches = findMatches
        let hasQuery = !trimmedFindText.isEmpty
        return HStack(spacing: DesignSystem.Spacing.small) {
            HStack(spacing: DesignSystem.Spacing.small) {
                Image(systemName: DesignSystem.Icons.search)
                    .foregroundStyle(DesignSystem.Colors.supporting)
                    .accessibilityHidden(true)
                TextField(
                    DesignSystem.Conversation.findInChat,
                    text: $findText,
                    prompt: Text(DesignSystem.Conversation.findPrompt)
                )
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($isFindFieldFocused)
                .onSubmit { stepFind(-1) }
                .onChange(of: findText) { _, _ in findTextChanged() }
                .accessibilityIdentifier("findInChatField")

                if hasQuery {
                    Text(matches.isEmpty
                         ? DesignSystem.Conversation.findNoMatches
                         : DesignSystem.Conversation.findPosition(findIndex + 1, matches.count))
                        .font(.footnote)
                        .monospacedDigit()
                        .foregroundStyle(DesignSystem.Colors.supporting)
                        .lineLimit(1)
                        .fixedSize()
                }
            }
            .padding(.horizontal, DesignSystem.Conversation.floatingBarPadding)
            .frame(minHeight: DesignSystem.Conversation.floatingButtonSize)
            .floatingSurface(in: Capsule())

            Button {
                stepFind(-1)
            } label: {
                FloatingIcon(systemImage: DesignSystem.Icons.findPrevious)
            }
            .buttonStyle(.plain)
            .disabled(matches.isEmpty)
            .accessibilityLabel(DesignSystem.Conversation.findPrevious)
            .accessibilityIdentifier("findPreviousButton")

            Button {
                stepFind(1)
            } label: {
                FloatingIcon(systemImage: DesignSystem.Icons.findNext)
            }
            .buttonStyle(.plain)
            .disabled(matches.isEmpty)
            .accessibilityLabel(DesignSystem.Conversation.findNext)
            .accessibilityIdentifier("findNextButton")

            Button {
                closeFind()
            } label: {
                FloatingIcon(systemImage: DesignSystem.Icons.close)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(DesignSystem.Common.done)
            .accessibilityInputLabels(DesignSystem.VoiceControl.dismiss)
            .accessibilityIdentifier("doneFindingButton")
        }
    }
    #endif

    // MARK: - iOS presentations

    #if os(iOS)
    /// Every iOS presentation of the chat screen sits on its own invisible
    /// anchor. SwiftUI shadows a nested `.fileImporter` or `.photosPicker`
    /// with the one higher up the tree, so the composer’s + menu and the
    /// Sources actions share one Files picker and one Photos picker, and
    /// `attachDestination` says where the picks go.
    @ViewBuilder
    func presentationAnchors() -> some View {
        Color.clear
            .sheet(isPresented: filesFeature.binding(for: \.isSourcesSheetPresented)) {
                sourcesSheet()
            }
        Color.clear
            .fullScreenCover(item: fullScreenBinding) { cover in
                switch cover {
                case .viewer(let content):
                    ImageViewer(content: content)
                case .camera:
                    CameraPicker { image in
                        addCapturedPhoto(image)
                    }
                    .ignoresSafeArea()
                }
            }
        Color.clear
            .fileImporter(
                isPresented: fileImporterBinding,
                allowedContentTypes: ProjectFilesView.supportedContentTypes,
                allowsMultipleSelection: true
            ) { result in
                switch pickerDestination {
                case .composer:
                    importChosenFiles(result)
                case .sources:
                    switch result {
                    case .success(let urls):
                        filesFeature.send(.selectFiles(urls))
                    case .failure:
                        filesFeature.set(\.errorMessage, to: DesignSystem.Errors.addSourcesFailed)
                    }
                }
            }
            .fileDialogConfirmationLabel(Text(
                pickerDestination == .composer ? DesignSystem.Conversation.attachConfirm : DesignSystem.Sources.panelConfirm
            ))
        Color.clear
            .photosPicker(
                isPresented: photoPickerBinding,
                selection: photoSelectionBinding,
                selectionBehavior: .ordered,
                matching: pickerDestination == .composer ? .any(of: [.images, .videos]) : .images
            )
    }

    /// Where picks go: an open picker's own flag decides, and once it has
    /// closed (file importer completions arrive after that) the choice made
    /// when it opened.
    private var pickerDestination: AttachDestination {
        if isFileImporterPresented || isPhotoPickerPresented || isCameraPresented { return .composer }
        if isScreenPickerActive && (filesFeature.value(\.isFileImporterPresented) || filesFeature.value(\.isPhotoPickerPresented)) {
            return .sources
        }
        return attachDestination
    }

    /// The Sources sheet has its own pickers, so the screen's only answer
    /// to the shared flags while that sheet is closed.
    private var isScreenPickerActive: Bool {
        !filesFeature.value(\.isSourcesSheetPresented)
    }

    private var fileImporterBinding: Binding<Bool> {
        Binding(
            get: { isFileImporterPresented || (isScreenPickerActive && filesFeature.value(\.isFileImporterPresented)) },
            set: { isPresented in
                guard !isPresented else { return }
                isFileImporterPresented = false
                if isScreenPickerActive { filesFeature.set(\.isFileImporterPresented, to: false) }
            }
        )
    }

    private var photoPickerBinding: Binding<Bool> {
        Binding(
            get: { isPhotoPickerPresented || (isScreenPickerActive && filesFeature.value(\.isPhotoPickerPresented)) },
            set: { isPresented in
                guard !isPresented else { return }
                isPhotoPickerPresented = false
                if isScreenPickerActive { filesFeature.set(\.isPhotoPickerPresented, to: false) }
            }
        )
    }

    private var photoSelectionBinding: Binding<[PhotosPickerItem]> {
        Binding(
            get: { pickerDestination == .composer ? photoItems : filesFeature.value(\.selectedPhotoItems) },
            set: { items in
                if pickerDestination == .composer {
                    photoItems = items
                } else {
                    filesFeature.set(\.selectedPhotoItems, to: items)
                }
            }
        )
    }

    /// The image viewer and the camera share one full-screen cover.
    private var fullScreenBinding: Binding<FullScreenCover?> {
        Binding(
            get: {
                if isCameraPresented { return .camera }
                return viewerContent.map(FullScreenCover.viewer)
            },
            set: { cover in
                guard cover == nil else { return }
                isCameraPresented = false
                viewerContent = nil
            }
        )
    }
    #endif

    // MARK: - iOS Sources sheet

    #if os(iOS)
    func sourcesSheet() -> some View {
        NavigationStack {
            ProjectFilesView(selectedProject: selectedProject)
                .navigationTitle(DesignSystem.Sources.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(DesignSystem.Common.done) {
                            filesFeature.set(\.isSourcesSheetPresented, to: false)
                        }
                        .accessibilityInputLabels(DesignSystem.VoiceControl.dismiss)
                    }
                }
        }
        .presentationDetents([.medium, .large])
    }
    #endif

    // MARK: - Subtitle

    #if os(macOS)
    var windowSubtitle: String {
        guard selectedProject != nil else { return DesignSystem.Window.noChatSelected }
        if feature.value(\.isProcessing) { return DesignSystem.Window.answering }
        return DesignSystem.Window.subtitle(
            DesignSystem.Window.sourceCount(filesFeature.value(\.files).count),
            DesignSystem.Window.messageCount(feature.value(\.messages).count)
        )
    }

    /// Window subtitle for VoiceOver, without the progress ellipsis.
    var spokenWindowSubtitle: String {
        guard selectedProject != nil, feature.value(\.isProcessing) else { return windowSubtitle }
        return DesignSystem.Window.answeringLabel
    }
    #endif

    private enum Constants {
        static let thinkingID = "thinking"
    }
}

/// One row of the conversation: a message, or a group of images sent
/// together (images render above the question they were sent with).
enum ConversationItem: Identifiable {
    case message(ChatMessage)
    case images(ImageGroup, [URL])

    var id: AnyHashable {
        switch self {
        case .message(let message): AnyHashable(message.id)
        case .images(let group, _): AnyHashable(group.id)
        }
    }

    var date: Date {
        switch self {
        case .message(let message): message.createdAt
        case .images(let group, _): group.date
        }
    }
}

#if os(iOS)
/// Where the chat screen's shared Files and Photos pickers deliver their picks.
enum AttachDestination {
    /// Composer chips, added as sources when the message is sent.
    case composer
    /// Straight into the chat's sources.
    case sources
}

/// What the chat screen shows full screen on iPhone and iPad.
enum FullScreenCover: Identifiable {
    case viewer(ImageViewerContent)
    case camera

    var id: String {
        switch self {
        case .viewer(let content): content.id.uuidString
        case .camera: "camera"
        }
    }
}
#endif
