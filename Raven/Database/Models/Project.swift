//
//  Project.swift
//  Parrot
//
//  Created by Eldar Tutnjic on 24.07.25.
//

import Foundation
import GRDB

struct Project: Codable, FetchableRecord, MutablePersistableRecord, Equatable, Hashable {
    var id: Int64?
    var name: String
    var createdAt: Date
    var folderPath: String

    static let databaseTableName = "projects"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    // MARK: - Equatable

    static func == (lhs: Project, rhs: Project) -> Bool {
        return lhs.id == rhs.id
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
