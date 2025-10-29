//
//  FileRecord.swift
//  Raven
//
//  Created by Eldar Tutnjic on 24.07.25.
//

import Foundation
import GRDB

public struct FileRecord: Codable, FetchableRecord, MutablePersistableRecord, Equatable, Hashable {
    public var id: Int64?
    public var projectId: Int64
    public var name: String
    public var originalPath: String
    public var publicPath: String
    public var fileType: String
    public var createdAt: Date

    public static let databaseTableName = "files"

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    // MARK: - Equatable

    public static func == (lhs: FileRecord, rhs: FileRecord) -> Bool {
        return lhs.id == rhs.id
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
