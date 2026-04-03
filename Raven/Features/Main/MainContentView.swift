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
    @FocusState private var isQuestionFieldFocused: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            content()
                .frame(maxWidth: .infinity)
        }
        .task(id: selectedProject?.id) {
            feature.send(.loadChat(selectedProject))
        }
        .onChange(of: selectedProject?.id) { _, newId in
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
                .accessibilityInputLabels(["Add Files", "Files", "Folder", "Import", "Documents"])
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
                        .accessibilityInputLabels(["Dismiss", "Close", "Cancel", "Done"])
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
                .supportsDynamicType()
            
            Text("Select a chat from the sidebar to begin")
                .font(.subheadline)
                .foregroundColor(.secondary)
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
                    if feature.value(\.messages).isEmpty && !feature.value(\.isProcessing) {
                        emptyConversationView()
                    } else {
                        conversationView()
                    }
                    
                    if feature.value(\.isProcessing) {
                        processingView()
                    }
                    
                    if let errorMessage = feature.value(\.errorMessage) {
                        errorView(errorMessage)
                            .onAppear {
                                AccessibilityHelper.announce("Error: \(errorMessage)")
                            }
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
    
    func conversationView() -> some View {
        LazyVStack(
            alignment: .leading,
            spacing: 16
        ) {
            ForEach(feature.value(\.messages)) { message in
                messageBubble(message)
            }
        }
    }

    func messageBubble(
        _ message: ChatMessage
    ) -> some View {
        VStack(
            alignment: message.role == .user ? .trailing : .leading,
            spacing: 8
        ) {
            HStack {
                if message.role == .assistant {
                    Label("Raven", systemImage: "brain.head.profile")
                        .foregroundColor(.blue)
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                } else {
                    Spacer()
                    Text("You")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .accessibilityAddTraits(.isHeader)
                }
            }

            Group {
                if message.role == .assistant {
                    Markdown(message.content)
                        .textSelection(.enabled)
                } else {
                    Text(message.content)
                }
            }
            .padding()
            .frame(
                maxWidth: .infinity,
                alignment: message.role == .user ? .trailing : .leading
            )
            .background(
                message.role == .user
                    ? Color.gray.opacity(0.15)
                    : Color.blue.opacity(0.15)
            )
            .cornerRadius(
                12,
                corners: .allCorners
            )
            .accessibilityLabel(message.role == .user ? "User Message" : "AI Response")
            .accessibilityValue(message.content)
        }
        .frame(
            maxWidth: .infinity,
            alignment: message.role == .user ? .trailing : .leading
        )
    }

    func emptyConversationView() -> some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            Text("No Messages Yet")
                .font(.title3)
                .fontWeight(.semibold)
                .accessibilityAddTraits(.isHeader)

            Text("Ask a question to start a chat that will be saved in this conversation.")
                .foregroundColor(.secondary)
                .supportsDynamicType()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.08))
        .cornerRadius(
            12,
            corners: .allCorners
        )
    }

    func latestAssistantResponseControls() -> some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            HStack {
                Spacer()
                
                Button {
                    feature.send(.copyResponse)
                    AccessibilityHelper.announce("Response copied to clipboard")
                } label: {
                    Text("Copy")
                }
                .buttonStyle(.bordered)
                .disabled(feature.value(\.messages).last(where: { $0.role == .assistant }) == nil)
                .accessibilityLabel("Copy Response")
                .accessibilityHint("Copies the AI response to the clipboard")
                .accessibilityInputLabels(["Copy Response", "Copy", "Copy Text"])
                .accessibilityIdentifier("copyResponseButton")
                
                Button {
                    if let selectedProject {
                        feature.send(.clearHistory(selectedProject))
                    }
                } label: {
                    Text("Clear History")
                }
                .buttonStyle(.bordered)
                .disabled(selectedProject == nil || feature.value(\.messages).isEmpty)
                .accessibilityLabel("Clear Chat History")
                .accessibilityHint("Clears the saved messages in this chat")
                .accessibilityInputLabels(["Clear History", "Clear Chat", "Delete History", "Remove Messages"])
                .accessibilityIdentifier("clearResponseButton")
            }
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
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.15))
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
        .background(Color.red.opacity(0.15))
        .cornerRadius(
            8,
            corners: .allCorners
        )
        .accessibilityElement(children: .combine)
    }
    
    func bottomInputView() -> some View {
        VStack {
            latestAssistantResponseControls()
                .padding(.horizontal)

            HStack {
                TextField(
                    "Ask me anything about your documents...",
                    text: feature.binding(for: \.questionText),
                    axis: .vertical
                )
                .textFieldStyle(.roundedBorder)
                .focused($isQuestionFieldFocused)
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
                .accessibilityInputLabels(feature.value(\.isProcessing) ? ["Stop Processing", "Stop", "Cancel"] : ["Send Question", "Send", "Submit", "Ask"])
                .accessibilityIdentifier("sendQuestionButton")
            }
            .padding()
        }
        .onChange(of: feature.value(\.isProcessing)) { wasProcessing, isProcessing in
            if wasProcessing && !isProcessing {
                isQuestionFieldFocused = true
            }
        }
        .onChange(of: feature.value(\.errorMessage)) { _, error in
            if error != nil {
                isQuestionFieldFocused = true
            }
        }
    }
}
