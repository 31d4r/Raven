//
//  TextExtractionService.swift
//  Raven
//
//  Created by Eldar Tutnjic on 16.08.25.
//

import Foundation

// MARK: - Text Extraction Service

@Observable
class TextExtractionService {
    private let audioTranscriptionService: AudioTranscriptionService
    private let pdfProcessingService: PDFProcessingService
    private let imageTextService: ImageTextService
    
    // MARK: - Initialization
    
    init(
        audioTranscriptionService: AudioTranscriptionService = AudioTranscriptionService(),
        pdfProcessingService: PDFProcessingService = PDFProcessingService(),
        imageTextService: ImageTextService = ImageTextService()
    ) {
        self.audioTranscriptionService = audioTranscriptionService
        self.pdfProcessingService = pdfProcessingService
        self.imageTextService = imageTextService
    }
    
    // MARK: - Main Text Extraction
    
    func extractTextFromFiles(
        _ files: [FileRecord]
    ) async -> String {
        var allText: [String] = []
        
        for file in files {
            let fileURL = URL(fileURLWithPath: file.publicPath)
            
            switch file.fileType.lowercased() {
            case "jpg", "jpeg", "png", "tiff", "heic":
                if let imageText = await imageTextService.extractTextFromImage(fileURL) {
                    allText.append("=== \(file.name) ===\n\(imageText)")
                }
                
            case "pdf":
                if let pdfText = pdfProcessingService.extractTextFromPDF(fileURL) {
                    allText.append("=== \(file.name) ===\n\(pdfText)")
                }
                
            case "mp3", "wav", "aiff", "m4a":
                if let audioText = await audioTranscriptionService.transcribeAudio(fileURL) {
                    allText.append("=== \(file.name) (Audio Transcript) ===\n\(audioText)")
                }
                
            default:
                continue
            }
        }
        
        return allText.joined(separator: "\n\n")
    }
}
