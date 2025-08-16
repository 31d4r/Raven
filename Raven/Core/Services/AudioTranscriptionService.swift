//
//  AudioTranscriptionService.swift
//  Raven
//
//  Created by Eldar Tutnjic on 16.08.25.
//

import AVFoundation
import Speech

// MARK: - Speech Framework for Audio Files

@Observable
class AudioTranscriptionService {
    // MARK: - Audio Transcription
    
    func transcribeAudio(
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
    
    // MARK: - Private Methods
    
    private func requestSpeechPermission() async {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { _ in
                continuation.resume()
            }
        }
    }
}
