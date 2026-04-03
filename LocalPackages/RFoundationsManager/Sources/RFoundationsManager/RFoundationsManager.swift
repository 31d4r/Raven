//
//  RFoundationsManager.swift
//  Raven
//
//  Created by Eldar Tutnjic on 16.08.25.
//

import FoundationModels
import RDatabaseManager
import RTextExtractionService
import SwiftUI

// MARK: - FoundationsManager

@Observable
public class RFoundationsManager {
    private let databaseManager: RDatabaseManager
    private let textExtractionService: RTextExtractionService
    private let afModel = SystemLanguageModel.default
    
    // MARK: - Initialization
    
    public init(
        databaseManager: RDatabaseManager = RDatabaseManager(),
        textExtractionService: RTextExtractionService = RTextExtractionService()
    ) {
        self.databaseManager = databaseManager
        self.textExtractionService = textExtractionService
    }
    
    // MARK: - Main Processing Function
    
    public func processQuestion(
        _ question: String,
        for project: Project,
        history: [ChatMessage] = []
    ) async throws -> String {
        let files = try databaseManager.fetchFiles(for: project)
        let extractedText = await textExtractionService.extractTextFromFiles(files)
        let enhancedPrompt = createPrompt(
            question: question,
            context: extractedText,
            history: history
        )
        let session = LanguageModelSession()
        let response = try await session.respond(to: enhancedPrompt).content

        return response
    }
    
    // MARK: - Private Methods
    
    private func createPrompt(
        question: String,
        context: String,
        history: [ChatMessage]
    ) -> String {
        let conversationHistory = history
            .map { message in
                "\(message.role.rawValue.capitalized): \(message.content)"
            }
            .joined(separator: "\n\n")

        return """
        You are Raven, a document-focused assistant.

        Conversation so far:
        \(conversationHistory.isEmpty ? "No previous messages." : conversationHistory)

        Context from uploaded documents:
        \(context.isEmpty ? "No uploaded document context is available yet." : context)

        Latest user question:
        \(question)

        Respond to the latest user question. Use the uploaded document context when it is relevant, and keep the answer consistent with the prior conversation for this chat only.
        """
    }
    
    public func isAFModelAvailable() -> (
        Bool,
        String
    ) {
        switch afModel.availability {
        case .available:
            return (true, "Present model")
        case .unavailable(.appleIntelligenceNotEnabled):
            return (false, "You do not have access to Apple Intelligence")
        case .unavailable(.deviceNotEligible):
            return (false, "The device does not meet the requirements for Apple Intelligence")
        case .unavailable(.modelNotReady):
            return (false, "Apple Intelligence is not available. Please ensure Apple Intelligence is enabled in System Settings.")
        case .unavailable:
            return (false, "Something went wrong")
        }
    }
}
