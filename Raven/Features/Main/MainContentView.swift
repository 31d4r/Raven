//
//  MainContentView.swift
//  Raven
//
//  Created by Eldar Tutnjic on 24.07.25.
//

import MarkdownUI
import RDatabaseManager
import SwiftUI

struct MainContentView: View {
    let selectedProject: Project?
    
    @Environment(MainContentFeature.self) var feature
    @State private var isAddProjectFilesPresented = false
    
    var body: some View {
        HStack(spacing: 0) {
            content()
                .frame(maxWidth: .infinity)
        }
        .onChange(of: selectedProject?.id) { _, newId in
            feature.send(.clearResponse)
            if let projectName = selectedProject?.name {
                AccessibilityHelper.announce("Switched to chat: \(projectName)")
            }
        }
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isAddProjectFilesPresented = true
                } label: {
                    Image(systemName: "folder")
                }
                .accessibilityLabel("Add Files")
                .accessibilityHint("Opens the file picker to add documents to the current chat")
            }
        }
        .sheet(isPresented: $isAddProjectFilesPresented) {
            NavigationStack {
                ProjectFilesView(selectedProject: selectedProject)
                    .toolbar {
                        Button {
                            isAddProjectFilesPresented = false
                        } label: {
                            Text("Dismiss")
                        }
                        .accessibilityLabel("Dismiss")
                        .accessibilityHint("Closes the file picker")
                    }
            }
        }
        #endif
    }
    
    func content() -> some View {
        mainView()
    }
    
    func mainView() -> some View {
        VStack(spacing: 20) {
            if selectedProject == nil {
                noProjectSelectedView()
            } else {
                chatView()
                bottomInputView()
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        #if os(macOS)
        .background(Color(NSColor.textBackgroundColor))
        #endif
    }
    
    func noProjectSelectedView() -> some View {
        VStack(spacing: 20) {
            Spacer()

            Text("No Chat Selected")
                .font(.title)
                .fontWeight(.medium)
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel("No Chat Selected")
                .accessibilityHint("Select a chat from the sidebar to begin")
                .supportsDynamicType()
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
    
    func chatView() -> some View {
        ScrollView {
            let (isAvailable, message) = feature.checkModelAvailability()
            
            if isAvailable {
                VStack(
                    alignment: .leading,
                    spacing: 20
                ) {
                    if !feature.value(\.responseText).isEmpty {
                        promptView()
                        responseView()
                    }
                    
                    if feature.value(\.isProcessing) {
                        processingView()
                    }
                    
                    if let errorMessage = feature.value(\.errorMessage) {
                        errorView(errorMessage)
                    }
                    
                    Spacer()
                }
                .padding()
            } else {
                VStack(
                    alignment: .leading,
                    spacing: 20
                ) {
                    Spacer()
                    errorView(message)
                    Spacer()
                }
                .padding()
            }
        }
    }
    
    func promptView() -> some View {
        HStack {
            Spacer()
            
            Text(feature.value(\.promptText))
                .padding()
                .accessibilityLabel("User Question")
                .accessibilityValue(feature.value(\.promptText))
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(
            12,
            corners: .allCorners
        )
        .accessibilityElement(children: .combine)
    }
    
    func responseView() -> some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                    .accessibilityHidden(true)
                Text("AI Response")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                    .supportsDynamicType()
                Spacer()
                
                Button {
                    feature.send(.copyResponse)
                    AccessibilityHelper.announce("Response copied to clipboard")
                } label: {
                    Text("Copy")
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Copy Response")
                .accessibilityHint("Copies the AI response to the clipboard")
                .accessibilityIdentifier("copyResponseButton")
                
                Button {
                    feature.send(.clearResponse)
                } label: {
                    Text("Clear")
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Clear Response")
                .accessibilityHint("Clears the current AI response")
                .accessibilityIdentifier("clearResponseButton")
            }
            
            ScrollView {
                Markdown(feature.value(\.responseText))
                    .textSelection(.enabled)
                    .padding()
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .accessibilityLabel("AI Response Content")
                    .accessibilityValue(feature.value(\.responseText))
            }
            .background(Color.blue.opacity(0.1))
            .cornerRadius(
                12,
                corners: .allCorners
            )
        }
        .accessibilityElement(children: .contain)
    }
    
    func processingView() -> some View {
        HStack {
            Spacer()
            
            ProgressView()
                .scaleEffect(0.8)
                .accessibilityLabel("Processing")
            
            Text("Processing documents and generating response...")
                .foregroundColor(.secondary)
                .accessibilityLabel("Processing documents and generating response")
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(
            8,
            corners: .allCorners
        )
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.updatesFrequently)
    }
    
    func errorView(
        _ message: String
    ) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.red)
                .accessibilityHidden(true)
            Text(message)
                .foregroundColor(.red)
                .accessibilityLabel("Error: \(message)")
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(
            8,
            corners: .allCorners
        )
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }
    
    func bottomInputView() -> some View {
        VStack {
            HStack {
                TextField(
                    "Ask me anything about your documents...",
                    text: feature.binding(for: \.questionText),
                    axis: .vertical
                )
                .textFieldStyle(.roundedBorder)
                .disabled(selectedProject == nil || feature.value(\.isProcessing))
                .accessibilityLabel("Question Input")
                .accessibilityHint("Enter your question about the documents")
                .accessibilityValue(feature.value(\.questionText))
                .accessibilityIdentifier("questionTextField")
                .onSubmit {
                    if let project = selectedProject {
                        feature.send(.processQuestion(feature.value(\.questionText), project))
                    }
                }
                
                Button {
                    if let project = selectedProject {
                        feature.send(.processQuestion(feature.value(\.questionText), project))
                        AccessibilityHelper.announce("Processing question")
                    }
                } label: {
                    Image(systemName: feature.value(\.isProcessing) ? "stop.circle.fill" : "paperplane.fill")
                        .foregroundColor(selectedProject == nil ? .secondary : .blue)
                }
                .buttonStyle(.plain)
                .disabled(
                    selectedProject == nil || feature.value(
                        \.questionText
                    ).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
                .accessibilityLabel(feature.value(\.isProcessing) ? "Stop Processing" : "Send Question")
                .accessibilityHint(feature.value(\.isProcessing) ? "Stops processing the current question" : "Sends your question to the AI")
                .accessibilityIdentifier("sendQuestionButton")
            }
            .padding()
        }
    }
}
