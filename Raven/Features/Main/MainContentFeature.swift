//
//  MainContentFeature.swift
//  Raven
//
//  Created by Eldar Tutnjic on 25.07.25.
//

import FoundationModels
import RDatabaseManager
import RFoundationsManager
import SwiftUI
#if os(iOS)
import UIKit
#endif

extension MainContentView {
    struct MainContentState {
        var questionText = ""
        var messages: [ChatMessage] = []
        var isProcessing = false
        var errorMessage: String?
        var activeProjectID: Int64?
        var isConfirmingClearHistory = false
    }

    enum ModelAvailability: Equatable {
        case available
        case unavailable(reason: String)
    }
    
    enum Action {
        case updateQuestion(String)
        case loadChat(Project?)
        case processQuestion(String, Project)
        case clearHistory(Project)
        case copyResponse
        case copyMessage(ChatMessage)
        case cancelProcessing
    }
    
    @Observable
    class MainContentFeature {
        private(set) var state = MainContentState()
        private let databaseManager: RDatabaseManager
        private let foundationsManager: RFoundationsManager
        @ObservationIgnored private var processingTask: Task<Void, Never>?

        init(
            databaseManager: RDatabaseManager,
            foundationsManager: RFoundationsManager
        ) {
            self.databaseManager = databaseManager
            self.foundationsManager = foundationsManager
        }
    }
}

// MARK: - Utils

extension MainContentView.MainContentFeature {
    func send(_ action: MainContentView.Action) {
        switch action {
        case .processQuestion:
            processingTask = Task {
                await handle(action)
            }
        default:
            Task {
                await handle(action)
            }
        }
    }
    
    func value<T>(_ keyPath: KeyPath<MainContentView.MainContentState, T>) -> T {
        state[keyPath: keyPath]
    }

    func set<T>(_ keyPath: WritableKeyPath<MainContentView.MainContentState, T>, to value: T) {
        state[keyPath: keyPath] = value
    }

    func binding<T>(for keyPath: WritableKeyPath<MainContentView.MainContentState, T>) -> Binding<T> {
        Binding<T>(
            get: { self.state[keyPath: keyPath] },
            set: { newValue in
                self.state[keyPath: keyPath] = newValue
            }
        )
    }
}

// MARK: - Actions

extension MainContentView.MainContentFeature {
    @MainActor
    private func handle(_ action: MainContentView.Action) async {
        switch action {
        case .updateQuestion(let text):
            set(\.questionText, to: text)

        case .loadChat(let project):
            await loadChat(for: project)

        case .processQuestion(let question, let project):
            await processQuestion(question, for: project)

        case .clearHistory(let project):
            await clearHistory(for: project)

        case .copyResponse:
            copyResponseToClipboard()

        case .copyMessage(let message):
            copyToClipboard(message.role == .assistant ? formatResponseForCopy(message.content) : message.content)

        case .cancelProcessing:
            cancelProcessing()
        }
    }

    private func loadChat(
        for project: Project?
    ) async {
        set(\.errorMessage, to: nil)
        set(\.questionText, to: "")

        guard let project else {
            set(\.messages, to: [])
            set(\.activeProjectID, to: nil)
            return
        }

        do {
            let messages = try databaseManager.fetchChatMessages(for: project)
            set(\.messages, to: messages)
            set(\.activeProjectID, to: project.id)
        } catch {
            set(\.messages, to: [])
            set(\.activeProjectID, to: project.id)
            set(\.errorMessage, to: DesignSystem.Errors.loadChatFailed)
        }
    }
    
    private func processQuestion(
        _ question: String,
        for project: Project
    ) async {
        let trimmedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuestion.isEmpty, let projectID = project.id else { return }

        set(\.isProcessing, to: true)
        set(\.errorMessage, to: nil)

        do {
            let userMessage = try databaseManager.createChatMessage(
                for: project,
                role: .user,
                content: trimmedQuestion
            )
            var updatedMessages = value(\.messages)
            if value(\.activeProjectID) == projectID {
                updatedMessages.append(userMessage)
                set(\.messages, to: updatedMessages)
            } else {
                updatedMessages = try databaseManager.fetchChatMessages(for: project)
            }
            set(\.questionText, to: "")

            let response = try await foundationsManager.processQuestion(
                trimmedQuestion,
                for: project,
                history: updatedMessages
            )

            guard !Task.isCancelled else { return }

            let assistantMessage = try databaseManager.createChatMessage(
                for: project,
                role: .assistant,
                content: response
            )
            if value(\.activeProjectID) == projectID {
                updatedMessages.append(assistantMessage)
                set(\.messages, to: updatedMessages)
            }
            AccessibilityHelper.announce(DesignSystem.Chat.answerReady)
        } catch {
            guard !Task.isCancelled else { return }
            set(\.errorMessage, to: Self.userFacingMessage(for: error))
        }

        set(\.isProcessing, to: false)
    }

    private func cancelProcessing() {
        processingTask?.cancel()
        processingTask = nil
        set(\.isProcessing, to: false)
    }

    private static func userFacingMessage(for error: Error) -> String {
        if let generationError = error as? LanguageModelSession.GenerationError {
            switch generationError {
            case .exceededContextWindowSize:
                return DesignSystem.Errors.contextTooLong
            case .guardrailViolation:
                return DesignSystem.Errors.guardrail
            default:
                break
            }
        }
        return DesignSystem.Errors.answerFailed
    }

    private func clearHistory(
        for project: Project
    ) async {
        do {
            try databaseManager.deleteChatMessages(for: project)
            set(\.messages, to: [])
            set(\.errorMessage, to: nil)
        } catch {
            set(\.errorMessage, to: DesignSystem.Errors.clearFailed)
        }
    }

    private func copyResponseToClipboard() {
        let responseText = value(\.messages)
            .last(where: { $0.role == .assistant })?
            .content ?? ""
        guard !responseText.isEmpty else { return }
        
        copyToClipboard(formatResponseForCopy(responseText))
        AccessibilityHelper.announce(DesignSystem.Chat.copied)
    }

    private func copyToClipboard(_ text: String) {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        #else
        UIPasteboard.general.string = text
        #endif
    }

    private func formatResponseForCopy(
        _ text: String
    ) -> String {
        let timestamp = Date().formatted(
            date: .abbreviated,
            time: .shortened
        )
        
        return """
        AI Response - \(timestamp)
        ═══════════════════════════════════════
        
        \(text)
        
        ═══════════════════════════════════════
        Generated by Raven AI Assistant
        """
    }
    
    func checkModelAvailability() -> (Bool, String) {
        foundationsManager.isAFModelAvailable()
    }
}

// MARK: - Availability

extension MainContentView.MainContentFeature {
    /// Apple Intelligence status with copy that tells people how to fix it.
    var modelAvailability: MainContentView.ModelAvailability {
        switch SystemLanguageModel.default.availability {
        case .available:
            .available
        case .unavailable(.appleIntelligenceNotEnabled):
            .unavailable(reason: DesignSystem.Chat.unavailableNotEnabled)
        case .unavailable(.deviceNotEligible):
            .unavailable(reason: DesignSystem.Chat.unavailableNotEligible)
        case .unavailable(.modelNotReady):
            .unavailable(reason: DesignSystem.Chat.unavailableNotReady)
        case .unavailable:
            .unavailable(reason: DesignSystem.Chat.unavailableOther)
        }
    }

    var lastResponse: ChatMessage? {
        value(\.messages).last(where: { $0.role == .assistant })
    }

    func sendUnavailableReason(for project: Project?) -> String? {
        guard project != nil else { return DesignSystem.Chats.noChatReason }
        if case .unavailable(let reason) = modelAvailability { return reason }
        if value(\.isProcessing) { return DesignSystem.Chat.busyReason }
        if value(\.questionText).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return DesignSystem.Chat.emptyQuestionReason
        }
        return nil
    }

    func copyResponseUnavailableReason(for project: Project?) -> String? {
        guard project != nil else { return DesignSystem.Chats.noChatReason }
        return lastResponse == nil ? DesignSystem.Chat.noResponseReason : nil
    }

    func clearHistoryUnavailableReason(for project: Project?) -> String? {
        guard project != nil else { return DesignSystem.Chats.noChatReason }
        if value(\.isProcessing) { return DesignSystem.Chat.busyReason }
        return value(\.messages).isEmpty ? DesignSystem.Chat.noMessagesReason : nil
    }

    var cancelUnavailableReason: String? {
        value(\.isProcessing) ? nil : DesignSystem.Chat.notAnsweringReason
    }

    func submitQuestion(for project: Project?) {
        guard let project, sendUnavailableReason(for: project) == nil else { return }
        send(.processQuestion(value(\.questionText), project))
    }
}
