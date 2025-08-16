//
//  FoundationsManager.swift
//  Parrot
//
//  Created by Eldar Tutnjic on 16.08.25.
//

import FoundationModels
import SwiftUI

// MARK: - FoundationsManager

@Observable
class FoundationsManager {
    private let session = LanguageModelSession()
    private let databaseManager: DatabaseManager
    private let textExtractionService: TextExtractionService
    
    // MARK: - Initialization
    
    init(
        databaseManager: DatabaseManager = DatabaseManager(),
        textExtractionService: TextExtractionService = TextExtractionService()
    ) {
        self.databaseManager = databaseManager
        self.textExtractionService = textExtractionService
    }
    
    // MARK: - Main Processing Function
    
    func processQuestion(
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
}
