//
//  ChatMessage.swift
//  Raven
//
//  Created by Eldar Tutnjic on 03.04.26.
//

import Foundation
import GRDB

public struct ChatMessage: Codable, FetchableRecord, MutablePersistableRecord, Equatable, Hashable, Identifiable {
    public enum Role: String, Codable, CaseIterable, Sendable, DatabaseValueConvertible {
        case user
        case assistant
    }

    public var id: Int64?
    public var projectId: Int64
    public var role: Role
    public var content: String
    public var createdAt: Date

    public static let databaseTableName = "chatMessages"

    public enum Columns {
        static let projectId = Column("projectId")
        static let createdAt = Column("createdAt")
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    public static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
