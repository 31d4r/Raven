//
//  RightSidebarFeature.swift
//  Parrot
//
//  Created by Eldar Tutnjic on 24.07.25.
//

import AVFoundation
import FoundationModels
import SwiftUI

// MARK: - RightSidebarFeature

extension RightSidebarView {
    struct RightSidebarState {
        var isGenerating = false
        var generatedPodcast = ""
        var isPlaying = false
        var showingCustomization = false
        var hostStyle = "casual"
        var podcastLength = "medium"
        var errorMessage: String?
        
        var notes: [Note] = []
        var isLoadingNotes = false
        var showingNewNoteSheet = false
        var newNoteTitle = ""
        var newNoteContent = ""
    }
    
    enum Action {
        case generatePodcast(Project)
        case playPodcast
        case stopPodcast
        case showCustomization
        case hideCustomization
        case updateHostStyle(String)
        case updatePodcastLength(String)
        
        case loadNotes(Project)
        case showNewNoteSheet
        case hideNewNoteSheet
        case createNote(Project)
        case deleteNote(Note)
        case updateNewNoteTitle(String)
        case updateNewNoteContent(String)
    }
    
    @Observable
    class RightSidebarFeature: NSObject, AVSpeechSynthesizerDelegate {
        private(set) var state = RightSidebarState()
        private let foundationsManager = FoundationsManager.shared
        private let databaseManager: DatabaseManaging
        private let speechSynthesizer = AVSpeechSynthesizer()
        private var currentUtterance: AVSpeechUtterance?
        
        override init() {
            self.databaseManager = DatabaseManager()
            super.init()
            speechSynthesizer.delegate = self
        }
        
        func speechSynthesizer(
            _ synthesizer: AVSpeechSynthesizer,
            didStart utterance: AVSpeechUtterance
        ) {
            Task { @MainActor in
                self.set(\.isPlaying, to: true)
            }
        }
        
        func speechSynthesizer(
            _ synthesizer: AVSpeechSynthesizer,
            didFinish utterance: AVSpeechUtterance
        ) {
            Task { @MainActor in
                self.set(\.isPlaying, to: false)
            }
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
        case .generatePodcast(let project):
            await generatePodcast(for: project)
            
        case .playPodcast:
            await playPodcast()
            
        case .stopPodcast:
            await stopPodcast()
            
        case .showCustomization:
            set(\.showingCustomization, to: true)
            
        case .hideCustomization:
            set(\.showingCustomization, to: false)
            
        case .updateHostStyle(let style):
            set(\.hostStyle, to: style)
            
        case .updatePodcastLength(let length):
            set(\.podcastLength, to: length)
            
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
    
    private func generatePodcast(
        for project: Project
    ) async {
        set(\.isGenerating, to: true)
        set(\.errorMessage, to: nil)

        do {
            let podcastScript = try await foundationsManager.generatePodcastScript(
                for: project,
                hostStyle: value(\.hostStyle),
                length: value(\.podcastLength)
            )
            set(\.generatedPodcast, to: podcastScript)
        } catch {
            set(\.errorMessage, to: error.localizedDescription)
        }

        set(\.isGenerating, to: false)
    }
    
    private func playPodcast() async {
        guard !value(\.generatedPodcast).isEmpty else { return }
        
        if speechSynthesizer.isSpeaking {
            if speechSynthesizer.isPaused {
                speechSynthesizer.continueSpeaking()
            } else {
                speechSynthesizer.pauseSpeaking(at: .immediate)
            }
            set(\.isPlaying, to: !speechSynthesizer.isPaused)
        } else {
            await playParsedPodcast()
            set(\.isPlaying, to: true)
        }
    }
    
    private func stopPodcast() async {
        speechSynthesizer.stopSpeaking(at: .immediate)
        set(\.isPlaying, to: false)
    }
    
    private func playParsedPodcast() async {
        let parsedLines = parsePodcastScript(value(\.generatedPodcast))
        
        let availableVoices = AVSpeechSynthesisVoice.speechVoices()
        
        let host1Voice = availableVoices.first(where: {
            $0.language.hasPrefix("en")
        }) ?? AVSpeechSynthesisVoice(language: "en-US") ?? availableVoices.first!
        
        let host2Voice = availableVoices.first(where: {
            $0.language.hasPrefix("en") && $0 != host1Voice
        }) ?? AVSpeechSynthesisVoice(language: "en-GB") ?? availableVoices[min(1, availableVoices.count - 1)]
        
        for (index, line) in parsedLines.enumerated() {
            let utterance = AVSpeechUtterance(string: line.text)
            
            utterance.rate = 0.45
            utterance.pitchMultiplier = line.isHost1 ? 1.0 : 0.9
            utterance.volume = 0.8
            utterance.voice = line.isHost1 ? host1Voice : host2Voice
            utterance.preUtteranceDelay = index == 0 ? 0.1 : 0.8
            utterance.postUtteranceDelay = 0.3
            
            speechSynthesizer.speak(utterance)
        }
    }
    
    private func parsePodcastScript(_ script: String) -> [(
        text: String,
        isHost1: Bool
    )] {
        let lines = script.components(separatedBy: .newlines)
        var parsedLines: [(text: String, isHost1: Bool)] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedLine.isEmpty { continue }
            
            if trimmedLine.hasPrefix("HOST 1:") {
                let text = String(trimmedLine.dropFirst(7)).trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty {
                    parsedLines.append((text: text, isHost1: true))
                }
            } else if trimmedLine.hasPrefix("HOST 2:") {
                let text = String(trimmedLine.dropFirst(7)).trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty {
                    parsedLines.append((text: text, isHost1: false))
                }
            } else if !trimmedLine.hasPrefix("HOST") {
                parsedLines.append((text: trimmedLine, isHost1: parsedLines.last?.isHost1 == false))
            }
        }
        
        return parsedLines
    }
    
    // MARK: - Notes Functions
    
    private func loadNotes(
        for project: Project
    ) async {
        set(\.isLoadingNotes, to: true)
        
        do {
            let notes = try await databaseManager.fetchNotes(for: project)
            set(\.notes, to: notes)
        } catch {
            set(\.errorMessage, to: error.localizedDescription)
        }
        
        set(\.isLoadingNotes, to: false)
    }
    
    private func createNote(for project: Project) async {
        let title = value(\.newNoteTitle).trimmingCharacters(in: .whitespacesAndNewlines)
        let content = value(\.newNoteContent).trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !title.isEmpty && !content.isEmpty else { return }
        
        do {
            let note = try await databaseManager.createNote(
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
            try await databaseManager.deleteNote(note)
            let updatedNotes = value(\.notes).filter { $0.id != note.id }
            set(\.notes, to: updatedNotes)
        } catch {
            set(\.errorMessage, to: error.localizedDescription)
        }
    }
}
