//
//  RImageTextService.swift
//  Raven
//
//  Created by Eldar Tutnjic on 16.08.25.
//

import SwiftUI
import Vision

// MARK: - Vision Framework for Images

@Observable
public class RImageTextService {
    public init() {}
    
    // MARK: - Image Text Extraction
    
    public func extractTextFromImage(
        _ imageURL: URL
    ) async -> String? {
        #if os(iOS)
        guard let image = UIImage(contentsOfFile: imageURL.path),
              let cgImage = image.cgImage
        else {
            return nil
        }
        #elseif os(macOS)
        guard let image = NSImage(contentsOf: imageURL),
              let cgImage = image.cgImage(
                  forProposedRect: nil,
                  context: nil,
                  hints: nil
              )
        else {
            return nil
        }
        #endif
        
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
            
            let handler = VNImageRequestHandler(
                cgImage: cgImage,
                options: [:]
            )
            
            do {
                try handler.perform([request])
            } catch {
                print("Vision handler error: \(error)")
                continuation.resume(returning: nil)
            }
        }
    }
}
