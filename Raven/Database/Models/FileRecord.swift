//
//  FileRecord.swift
//  Raven
//
//  Created by Eldar Tutnjic on 24.07.25.
//

import Foundation
import GRDB

struct FileRecord: Codable, FetchableRecord, MutablePersistableRecord, Equatable, Hashable {
    var id: Int64?
    var projectId: Int64
    var name: String
    var originalPath: String
    var publicPath: String
    var fileType: String
    var createdAt: Date

    static let databaseTableName = "files"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    // MARK: - Equatable

    static func == (lhs: FileRecord, rhs: FileRecord) -> Bool {
        return lhs.id == rhs.id
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
