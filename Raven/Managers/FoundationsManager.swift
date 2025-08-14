//
//  FoundationsManager.swift
//  Parrot
//
//  Created by Eldar Tutnjic on 24.07.25.
//

import AVFoundation
import FoundationModels
import PDFKit
import Speech
import SwiftUI
import UniformTypeIdentifiers
import Vision

// MARK: - FoundationsManager

@Observable
class FoundationsManager {
    static let shared = FoundationsManager()
    
    private let session = LanguageModelSession()
    private let databaseManager: DatabaseManaging
    
    private init() {
        self.databaseManager = DatabaseManager()
    }
    
    init(databaseManager: DatabaseManaging) {
        self.databaseManager = databaseManager
    }
    
    // MARK: - Main Processing Function
    
    func processQuestion(
        _ question: String,
        for project: Project
    ) async throws -> String {
        let files = try databaseManager.fetchFiles(for: project)
        
        let extractedText = await extractTextFromFiles(files)
        
        let enhancedPrompt = createPrompt(question: question, context: extractedText)
        
        let response = try await session.respond(to: enhancedPrompt).content
        
        return response
    }
}

// MARK: - Text Extraction

extension FoundationsManager {
    private func extractTextFromFiles(
        _ files: [FileRecord]
    ) async -> String {
        var allText: [String] = []
        
        for file in files {
            let fileURL = URL(fileURLWithPath: file.publicPath)
            
            switch file.fileType.lowercased() {
            case "jpg", "jpeg", "png", "tiff", "heic":
                if let imageText = await extractTextFromImage(fileURL) {
                    allText.append("=== \(file.name) ===\n\(imageText)")
                }
                
            case "pdf":
                if let pdfText = extractTextFromPDF(fileURL) {
                    allText.append("=== \(file.name) ===\n\(pdfText)")
                }
                
            case "mp3", "wav", "aiff", "m4a":
                if let audioText = await transcribeAudio(fileURL) {
                    allText.append("=== \(file.name) (Audio Transcript) ===\n\(audioText)")
                }
                
            default:
                continue
            }
        }
        
        return allText.joined(separator: "\n\n")
    }
    
    // MARK: - Vision Framework for Images
    
    private func extractTextFromImage(
        _ imageURL: URL
    ) async -> String? {
        guard let image = NSImage(contentsOf: imageURL),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else {
            return nil
        }
        
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    print("Vision error: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                let result = recognizedStrings.joined(separator: "\n")
                continuation.resume(returning: result.isEmpty ? nil : result)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                print("Vision handler error: \(error)")
                continuation.resume(returning: nil)
            }
        }
    }
    
    // MARK: - PDFKit for PDF Files
    
    private func extractTextFromPDF(
        _ pdfURL: URL
    ) -> String? {
        guard let pdfDocument = PDFDocument(url: pdfURL) else {
            return nil
        }
        
        var extractedText = ""
        
        for pageIndex in 0 ..< pdfDocument.pageCount {
            if let page = pdfDocument.page(at: pageIndex),
               let pageText = page.string
            {
                extractedText += pageText + "\n"
            }
        }
        
        return extractedText.isEmpty ? nil : extractedText
    }
    
    // MARK: - Speech Framework for Audio Files
    
    private func transcribeAudio(
        _ audioURL: URL
    ) async -> String? {
        let authStatus = SFSpeechRecognizer.authorizationStatus()
        if authStatus != .authorized {
            await requestSpeechPermission()
        }
        
        guard let recognizer = SFSpeechRecognizer() else {
            print("Speech recognizer not available")
            return nil
        }
        
        guard recognizer.isAvailable else {
            print("Speech recognizer not available")
            return nil
        }
        
        return await withCheckedContinuation { continuation in
            let request = SFSpeechURLRecognitionRequest(url: audioURL)
            request.shouldReportPartialResults = false
            request.taskHint = .dictation
            
            recognizer.recognitionTask(with: request) {
                result,
                    error in
                if let error = error {
                    print("Speech recognition error: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                
                if let result = result,
                   result.isFinal
                {
                    let transcript = result.bestTranscription.formattedString
                    continuation.resume(
                        returning: transcript.isEmpty ? nil : transcript
                    )
                }
            }
        }
    }
    
    private func requestSpeechPermission() async {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { _ in
                continuation.resume()
            }
        }
    }
    
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

// MARK: - FoundationsManager Extension for Podcast

extension FoundationsManager {
    func generatePodcastScript(
        for project: Project,
        hostStyle: String,
        length: String
    ) async throws -> String {
        let files = try databaseManager.fetchFiles(for: project)
        let extractedContent = await extractTextFromFiles(files)
        
        let podcastPrompt = createPodcastPrompt(
            content: extractedContent,
            hostStyle: hostStyle,
            length: length,
            projectName: project.name
        )
        
        let response = try await session.respond(to: podcastPrompt).content
        
        return response
    }
    
    private func createPodcastPrompt(
        content: String,
        hostStyle: String,
        length: String,
        projectName: String
    ) -> String {
        let lengthDescription = switch length {
        case "short": "5-7 minutes"
        case "medium": "10-15 minutes"
        case "long": "20-25 minutes"
        default: "10-15 minutes"
        }
        
        let styleDescription = switch hostStyle {
        case "casual": "casual and friendly conversation"
        case "professional": "professional and informative discussion"
        case "entertaining": "entertaining and engaging banter"
        default: "casual and friendly conversation"
        }
        
        return """
        Create a podcast script for a \(lengthDescription) episode with two hosts having a \(styleDescription) about the content from the project "\(projectName)".
        
        Content to discuss:
        \(content)
        
        Format the script like this:
        
        HOST 1: [Opening introduction and welcome]
        
        HOST 2: [Response and setting the topic]
        
        HOST 1: [Discussing first key point]
        
        HOST 2: [Adding insights and asking questions]
        
        Continue the conversation naturally, making sure to:
        - Cover all important points from the content
        - Make it engaging and conversational
        - Include natural transitions between topics
        - End with a summary and closing remarks
        - Keep the tone \(styleDescription)
        
        Make it feel like a real podcast conversation between two knowledgeable hosts discussing the material.
        """
    }
}
