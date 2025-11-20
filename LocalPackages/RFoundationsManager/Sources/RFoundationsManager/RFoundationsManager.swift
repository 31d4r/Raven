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
    private let session = LanguageModelSession()
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
        for project: Project
    ) async throws -> String {
        let files = try databaseManager.fetchFiles(for: project)
        
        let extractedText = await textExtractionService.extractTextFromFiles(files)
        
        let enhancedPrompt = createPrompt(question: question, context: extractedText)
        
        let response = try await session.respond(to: enhancedPrompt).content
        
        return response
    }
    
    // MARK: - Private Methods
    
    private func createPrompt(
        question: String,
        context: String
    ) -> String {
        if context.isEmpty {
            return question
        }
        
        return """
        Context from uploaded documents:
        \(context)
        
        Question: \(question)
        
        Please provide a response based on the context above.
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
