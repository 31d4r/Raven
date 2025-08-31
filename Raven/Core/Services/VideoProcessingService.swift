//
//  VideoProcessingService.swift
//  Raven
//
//  Created by Eldar Tutnjic on 31.08.25.
//

import AVFoundation
import Foundation

// MARK: - Video Processing Service

@Observable
class VideoProcessingService {
    // MARK: - Video to Audio Extraction

    func extractAudioFromVideo(
        _ videoURL: URL
    ) async -> URL? {
        let asset = AVURLAsset(url: videoURL)

        do {
            let duration = try await asset.load(.duration)
            let outputURL = createTempAudioURL()

            guard let exportSession = AVAssetExportSession(
                asset: asset,
                presetName: AVAssetExportPresetAppleM4A
            ) else {
                print("Failed to create export session")
                return nil
            }

            exportSession.shouldOptimizeForNetworkUse = true
            exportSession.timeRange = CMTimeRange(
                start: .zero,
                duration: duration
            )

            try await exportSession.export(
                to: outputURL,
                as: .m4a
            )
            print("Audio extraction completed: \(outputURL)")
            return outputURL
        } catch {
            print("Audio extraction failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Private Methods

    private func createTempAudioURL() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "extracted_audio_\(UUID().uuidString).m4a"
        return tempDir.appendingPathComponent(fileName)
    }
}
