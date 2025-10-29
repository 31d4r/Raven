//
//  Note.swift
//  Raven
//
//  Created by Eldar Tutnjic on 24.07.25.
//

import Foundation
import GRDB

public struct Note: Codable, FetchableRecord, MutablePersistableRecord, Equatable, Hashable {
    public var id: Int64?
    public var projectId: Int64
    public var title: String
    public var content: String
    public var createdAt: Date

    public static let databaseTableName = "notes"

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    // MARK: - Equatable

    public static func == (lhs: Note, rhs: Note) -> Bool {
        return lhs.id == rhs.id
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
