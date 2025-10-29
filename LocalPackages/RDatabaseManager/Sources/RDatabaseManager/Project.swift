//
//  Project.swift
//  Raven
//
//  Created by Eldar Tutnjic on 24.07.25.
//

import Foundation
import GRDB

public struct Project: Codable, FetchableRecord, MutablePersistableRecord, Equatable, Hashable {
    public var id: Int64?
    public var name: String
    public var createdAt: Date
    public var folderPath: String

    public static let databaseTableName = "projects"

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    // MARK: - Equatable

    public static func == (lhs: Project, rhs: Project) -> Bool {
        return lhs.id == rhs.id
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
