//
//  MainContentFeature.swift
//  Raven
//
//  Created by Eldar Tutnjic on 25.07.25.
//

import RDatabaseManager
import RFoundationsManager
import SwiftUI

extension MainContentView {
    struct MainContentState {
        var questionText = ""
        var messages: [ChatMessage] = []
        var isProcessing = false
        var errorMessage: String?
        var activeProjectID: Int64?
    }
    
    enum Action {
        case updateQuestion(String)
        case loadChat(Project?)
        case processQuestion(String, Project)
        case clearHistory(Project)
        case copyResponse
    }
    
    @Observable
    class MainContentFeature {
        private(set) var state = MainContentState()
        private let databaseManager: RDatabaseManager
        private let foundationsManager: RFoundationsManager

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
        Task {
            await handle(action)
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
            set(\.errorMessage, to: error.localizedDescription)
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

            let assistantMessage = try databaseManager.createChatMessage(
                for: project,
                role: .assistant,
                content: response
            )
            if value(\.activeProjectID) == projectID {
                updatedMessages.append(assistantMessage)
                set(\.messages, to: updatedMessages)
            }
        } catch {
            set(\.errorMessage, to: error.localizedDescription)
        }

        set(\.isProcessing, to: false)
    }

    private func clearHistory(
        for project: Project
    ) async {
        do {
            try databaseManager.deleteChatMessages(for: project)
            set(\.messages, to: [])
            set(\.errorMessage, to: nil)
        } catch {
            set(\.errorMessage, to: error.localizedDescription)
        }
    }

    private func copyResponseToClipboard() {
        let responseText = value(\.messages)
            .last(where: { $0.role == .assistant })?
            .content ?? ""
        guard !responseText.isEmpty else { return }
        
        let formattedText = formatResponseForCopy(responseText)
        
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(formattedText, forType: .string)
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
