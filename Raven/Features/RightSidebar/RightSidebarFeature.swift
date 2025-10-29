//
//  RightSidebarFeature.swift
//  Raven
//
//  Created by Eldar Tutnjic on 24.07.25.
//

import AVFoundation
import FoundationModels
import RDatabaseManager
import RFoundationsManager
import SwiftUI

// MARK: - RightSidebarFeature

extension RightSidebarView {
    struct RightSidebarState {
        var errorMessage: String?
        
        var notes: [Note] = []
        var isLoadingNotes = false
        var showingNewNoteSheet = false
        var newNoteTitle = ""
        var newNoteContent = ""
    }
    
    enum Action {
        case loadNotes(Project)
        case showNewNoteSheet
        case hideNewNoteSheet
        case createNote(Project)
        case deleteNote(Note)
        case updateNewNoteTitle(String)
        case updateNewNoteContent(String)
    }
    
    @Observable
    class RightSidebarFeature {
        private(set) var state = RightSidebarState()
        private let foundationsManager: RFoundationsManager
        private let databaseManager: RDatabaseManager
        
        init(
            foundationsManager: RFoundationsManager,
            databaseManager: RDatabaseManager
        ) {
            self.foundationsManager = foundationsManager
            self.databaseManager = databaseManager
        }
    }
}

// MARK: - Utils

extension RightSidebarView.RightSidebarFeature {
    func send(_ action: RightSidebarView.Action) {
        Task {
            await handle(action)
        }
    }
    
    func value<T>(_ keyPath: KeyPath<RightSidebarView.RightSidebarState, T>) -> T {
        state[keyPath: keyPath]
    }
    
    func set<T>(_ keyPath: WritableKeyPath<RightSidebarView.RightSidebarState, T>, to value: T) {
        state[keyPath: keyPath] = value
    }
    
    func binding<T>(for keyPath: WritableKeyPath<RightSidebarView.RightSidebarState, T>) -> Binding<T> {
        Binding<T>(
            get: { self.state[keyPath: keyPath] },
            set: { newValue in
                self.state[keyPath: keyPath] = newValue
            }
        )
    }
}

// MARK: - Actions

extension RightSidebarView.RightSidebarFeature {
    @MainActor
    private func handle(_ action: RightSidebarView.Action) async {
        switch action {
        case .loadNotes(let project):
            await loadNotes(for: project)
            
        case .showNewNoteSheet:
            set(\.showingNewNoteSheet, to: true)
            set(\.newNoteTitle, to: "")
            set(\.newNoteContent, to: "")
            
        case .hideNewNoteSheet:
            set(\.showingNewNoteSheet, to: false)
            
        case .createNote(let project):
            await createNote(for: project)
            
        case .deleteNote(let note):
            await deleteNote(note)
            
        case .updateNewNoteTitle(let title):
            set(\.newNoteTitle, to: title)
            
        case .updateNewNoteContent(let content):
            set(\.newNoteContent, to: content)
        }
    }
    
    // MARK: - Notes Functions
    
    private func loadNotes(
        for project: Project
    ) async {
        set(\.isLoadingNotes, to: true)
        
        do {
            let notes = try databaseManager.fetchNotes(for: project)
            set(\.notes, to: notes)
        } catch {
            set(\.errorMessage, to: error.localizedDescription)
        }
        
        set(\.isLoadingNotes, to: false)
    }
    
    private func createNote(for project: Project) async {
        let title = value(\.newNoteTitle).trimmingCharacters(in: .whitespacesAndNewlines)
        let content = value(\.newNoteContent).trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !title.isEmpty, !content.isEmpty else { return }
        
        do {
            let note = try databaseManager.createNote(
                for: project,
                title: title,
                content: content
            )
            var updatedNotes = value(\.notes)
            updatedNotes.insert(note, at: 0)
            set(\.notes, to: updatedNotes)
            set(\.showingNewNoteSheet, to: false)
        } catch {
            set(\.errorMessage, to: error.localizedDescription)
        }
    }
    
    private func deleteNote(_ note: Note) async {
        do {
            try databaseManager.deleteNote(note)
            let updatedNotes = value(\.notes).filter { $0.id != note.id }
            set(\.notes, to: updatedNotes)
        } catch {
            set(\.errorMessage, to: error.localizedDescription)
        }
    }
}
