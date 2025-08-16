//
//  DatabaseManager.swift
//  Parrot
//
//  Created by Eldar Tutnjic on 24.07.25.
//

import GRDB
import SwiftUI

@Observable
class DatabaseManager {
    private var dbQueue: DatabaseQueue!
    
    init() {
        setupDatabase()
    }
    
    private func setupDatabase() {
        do {
            let fileManager = FileManager.default
            let folderURL = try fileManager
                .url(
                    for: .applicationSupportDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                )
            let dbURL = folderURL.appendingPathComponent("parrot.sqlite")
            
            dbQueue = try DatabaseQueue(path: dbURL.path)
            
            print("DB: \(dbURL.path)")
            
            try migrator.migrate(dbQueue)
        } catch {
            fatalError("DB Setup Failed: \(error)")
        }
    }
    
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
#if DEBUG
        // Speed up development by nuking the database when migrations change
        migrator.eraseDatabaseOnSchemaChange = true
#endif
        
        migrator.registerMigration("0") { db in
            try db.create(table: "projects") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("folderPath", .text).notNull()
            }
            
            try db.create(table: "files") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("projectId", .integer).notNull().references("projects", onDelete: .cascade)
                t.column("name", .text).notNull()
                t.column("originalPath", .text).notNull()
                t.column("publicPath", .text).notNull()
                t.column("fileType", .text).notNull()
                t.column("createdAt", .datetime).notNull()
            }
            
            try db.create(table: "notes") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("projectId", .integer).notNull().references("projects", onDelete: .cascade)
                t.column("title", .text).notNull()
                t.column("content", .text).notNull()
                t.column("createdAt", .datetime).notNull()
            }
        }
        
        return migrator
    }
    
    // MARK: - Project Operations
    
    func createProject(
        name: String
    ) throws -> Project {
        let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        let projectFolderURL = documentsURL.appendingPathComponent("Parrot Projects").appendingPathComponent(name)
        let publicFolderURL = projectFolderURL.appendingPathComponent("public")
        
        try FileManager.default.createDirectory(
            at: publicFolderURL,
            withIntermediateDirectories: true
        )
        
        var project = Project(
            name: name,
            createdAt: Date(),
            folderPath: projectFolderURL.path
        )
        
        try dbQueue.write { db in
            try project.insert(db)
        }
        
        return project
    }
    
    func fetchProjects() throws -> [Project] {
        try dbQueue.read { db in
            try Project.order(Column("createdAt").desc).fetchAll(db)
        }
    }
    
    func deleteProject(
        _ project: Project
    ) throws {
        let projectURL = URL(fileURLWithPath: project.folderPath)
        try? FileManager.default.removeItem(at: projectURL)
        
        _ = try dbQueue.write { db in
            try project.delete(db)
        }
    }
    
    func renameProject(
        _ project: Project,
        newName: String
    ) throws -> Project {
        var updatedProject = project
        updatedProject.name = newName
        
        try dbQueue.write { db in
            try updatedProject.update(db)
        }
        
        return updatedProject
    }
    
    // MARK: - File Operations
    
    func addFiles(
        _ urls: [URL],
        to project: Project
    ) throws -> [FileRecord] {
        guard let projectId = project.id else {
            throw DatabaseError.notInitialized
        }
        
        let publicFolderURL = URL(
            fileURLWithPath: project.folderPath
        ).appendingPathComponent("public")
        var fileRecords: [FileRecord] = []
        
        try dbQueue.write { db in
            for url in urls {
                let fileName = url.lastPathComponent
                let destinationURL = publicFolderURL.appendingPathComponent(fileName)
                
                try FileManager.default.copyItem(
                    at: url,
                    to: destinationURL
                )
                
                var fileRecord = FileRecord(
                    projectId: projectId,
                    name: fileName,
                    originalPath: url.path,
                    publicPath: destinationURL.path,
                    fileType: url.pathExtension.lowercased(),
                    createdAt: Date()
                )
                
                try fileRecord.insert(db)
                fileRecords.append(fileRecord)
            }
        }
        
        return fileRecords
    }
    
    func fetchFiles(
        for project: Project
    ) throws -> [FileRecord] {
        guard let projectId = project.id else {
            throw DatabaseError.notInitialized
        }
        
        return try dbQueue.read { db in
            try FileRecord
                .filter(Column("projectId") == projectId)
                .order(Column("createdAt").desc)
                .fetchAll(db)
        }
    }
    
    func deleteFile(
        _ fileRecord: FileRecord
    ) throws {
        let fileURL = URL(fileURLWithPath: fileRecord.publicPath)
        try? FileManager.default.removeItem(at: fileURL)
        
        _ = try dbQueue.write { db in
            try fileRecord.delete(db)
        }
    }
    
    // MARK: - Note Operations

    func createNote(
        for project: Project,
        title: String,
        content: String
    ) throws -> Note {
        guard let projectId = project.id else {
            throw DatabaseError.notInitialized
        }
        
        var note = Note(
            projectId: projectId,
            title: title,
            content: content,
            createdAt: Date()
        )
        
        try dbQueue.write { db in
            try note.insert(db)
        }
        
        return note
    }

    func fetchNotes(
        for project: Project
    ) throws -> [Note] {
        guard let projectId = project.id else {
            throw DatabaseError.notInitialized
        }
        
        return try dbQueue.read { db in
            try Note
                .filter(Column("projectId") == projectId)
                .order(Column("createdAt").desc)
                .fetchAll(db)
        }
    }

    func deleteNote(
        _ note: Note
    ) throws {
        _ = try dbQueue.write { db in
            try note.delete(db)
        }
    }

    func updateNote(
        _ note: Note,
        title: String,
        content: String
    ) throws -> Note {
        var updatedNote = note
        updatedNote.title = title
        updatedNote.content = content
        
        try dbQueue.write { db in
            try updatedNote.update(db)
        }
        
        return updatedNote
    }
    
    // MARK: - Additional Convenience Methods
    
    func projectCount() -> Int {
        do {
            return try dbQueue.read { db in
                try Project.fetchCount(db)
            }
        } catch {
            return 0
        }
    }
    
    func fileCount(
        for project: Project
    ) -> Int {
        guard let projectId = project.id else { return 0 }
        
        do {
            return try dbQueue.read { db in
                try FileRecord.filter(Column("projectId") == projectId).fetchCount(db)
            }
        } catch {
            return 0
        }
    }
    
    func clearAllData() throws {
        try dbQueue.write { db in
            try Project.deleteAll(db)
            try FileRecord.deleteAll(db)
        }
    }
}

enum DatabaseError: Error {
    case notInitialized
    case projectNotFound
}
