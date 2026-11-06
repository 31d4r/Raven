//
//  MessageAttachmentStore.swift
//  Raven
//
//  Remembers which images were sent together, so the chat can show them
//  as a pile above the message. Chat messages and sources have no link in
//  the database, so this lives beside it as a small JSON file in
//  Application Support. It only stores source ids and a send time.
//

import Foundation
import Observation

/// Images sent together at one moment in one chat.
struct ImageGroup: Codable, Identifiable, Hashable {
    let id: UUID
    let date: Date
    let fileIDs: [Int64]
}

@Observable
final class MessageAttachmentStore {
    static let shared = MessageAttachmentStore()

    private(set) var groups: [String: [ImageGroup]]
    @ObservationIgnored private let fileURL: URL?

    init(fileURL: URL? = MessageAttachmentStore.defaultURL) {
        self.fileURL = fileURL
        if let fileURL,
           let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([String: [ImageGroup]].self, from: data) {
            groups = decoded
        } else {
            groups = [:]
        }
    }

    func groups(for projectID: Int64?) -> [ImageGroup] {
        guard let projectID else { return [] }
        return groups[String(projectID)] ?? []
    }

    func record(_ fileIDs: [Int64], in projectID: Int64, at date: Date) {
        guard !fileIDs.isEmpty else { return }
        groups[String(projectID), default: []].append(ImageGroup(id: UUID(), date: date, fileIDs: fileIDs))
        save()
    }

    func removeAll(for projectID: Int64) {
        guard groups.removeValue(forKey: String(projectID)) != nil else { return }
        save()
    }

    private func save() {
        guard let fileURL else { return }
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(groups).write(to: fileURL, options: .atomic)
        } catch {
            // Losing the pile only hides thumbnails; the sources stay saved.
        }
    }

    nonisolated static var defaultURL: URL? {
        URL.applicationSupportDirectory
            .appending(path: "Raven", directoryHint: .isDirectory)
            .appending(path: "message-attachments.json")
    }
}
