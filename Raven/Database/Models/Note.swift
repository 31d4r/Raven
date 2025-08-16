//
//  Note.swift
//  Raven
//
//  Created by Eldar Tutnjic on 24.07.25.
//

import Foundation
import GRDB

struct Note: Codable, FetchableRecord, MutablePersistableRecord, Equatable, Hashable {
    var id: Int64?
    var projectId: Int64
    var title: String
    var content: String
    var createdAt: Date
    
    static let databaseTableName = "notes"
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
    
    // MARK: - Equatable

    static func == (lhs: Note, rhs: Note) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
