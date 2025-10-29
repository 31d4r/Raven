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
}
