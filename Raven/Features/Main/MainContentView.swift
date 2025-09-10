//
//  MainContentView.swift
//  Raven
//
//  Created by Eldar Tutnjic on 24.07.25.
//

import MarkdownUI
import SwiftUI

struct MainContentView: View {
    @Binding var showLeftSidebar: Bool
    @Binding var showRightSidebar: Bool
    let selectedProject: Project?
    
    @Environment(MainContentFeature.self) var feature
    
    var body: some View {
        HStack(spacing: 0) {
            if showLeftSidebar {
                LeftSidebarView(selectedProject: selectedProject)
                    .frame(width: 300)
                    .transition(
                        .move(edge: .leading).combined(with: .opacity)
                    )
            }
            
            content()
                .frame(maxWidth: .infinity)
            
            if showRightSidebar {
                RightSidebarView(selectedProject: selectedProject)
                    .frame(width: 300)
                    .transition(
                        .move(edge: .trailing).combined(with: .opacity)
                    )
            }
        }
        .animation(
            .easeInOut(duration: 0.2),
            value: showLeftSidebar
        )
        .animation(
            .easeInOut(duration: 0.2),
            value: showRightSidebar
        )
        .onChange(of: selectedProject?.id) { _, _ in
            feature.send(.clearResponse)
        }
    }
    
    func content() -> some View {
        VStack {
            topToolbarView()
            mainView()
        }
    }
    
    func topToolbarView() -> some View {
        HStack {
            Button {
                showLeftSidebar.toggle()
            } label: {
                Image(systemName: "sidebar.leading")
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            VStack {
                Text("Chat")
                    .font(.title2)
                    .fontWeight(.medium)
                
                if let project = selectedProject {
                    Text(project.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .id(project.id)
                }
            }
            .id(selectedProject?.id)
            
            Spacer()
            
            Button {
                showRightSidebar.toggle()
            } label: {
                Image(systemName: "sidebar.trailing")
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    func mainView() -> some View {
        VStack(spacing: 20) {
            if selectedProject == nil {
                noProjectSelectedView()
            } else {
                chatView()
            }
            
            bottomInputView()
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .background(Color(NSColor.textBackgroundColor))
    }
    
    func noProjectSelectedView() -> some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Project Selected")
                .font(.title)
                .fontWeight(.medium)
            
            Spacer()
            
            Text("Select a project from the sidebar to get started")
                .foregroundColor(.secondary)
        }
    }
    
    func chatView() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
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
        }
    }
    
    func promptView() -> some View {
        HStack {
            Spacer()
            
            Text(feature.value(\.promptText))
                .padding()
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(
            12,
            corners: .allCorners
        )
    }
    
    func responseView() -> some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                Text("AI Response")
                    .font(.headline)
                Spacer()
                
                Button {
                    feature.send(.copyResponse)
                } label: {
                    Text("Copy")
                }
                .buttonStyle(.bordered)
                
                Button {
                    feature.send(.clearResponse)
                } label: {
                    Text("Clear")
                }
                .buttonStyle(.bordered)
            }
            
            ScrollView {
                Markdown(feature.value(\.responseText))
                    .textSelection(.enabled)
                    .padding()
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
            }
            .background(Color.blue.opacity(0.1))
            .cornerRadius(
                12,
                corners: .allCorners
            )
        }
    }
    
    func processingView() -> some View {
        HStack {
            Spacer()
            
            ProgressView()
                .scaleEffect(0.8)
            
            Text("Processing documents and generating response...")
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(
            8,
            corners: .allCorners
        )
    }
    
    func errorView(
        _ message: String
    ) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.red)
            Text(message)
                .foregroundColor(.red)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(
            8,
            corners: .allCorners
        )
    }
    
    func bottomInputView() -> some View {
        VStack {
            HStack {
                TextField(
                    selectedProject == nil ? "Select a project to get started" : "Ask me anything about your documents...",
                    text: feature.binding(for: \.questionText),
                    axis: .vertical
                )
                .textFieldStyle(.roundedBorder)
                .disabled(selectedProject == nil || feature.value(\.isProcessing))
                .onSubmit {
                    if let project = selectedProject {
                        feature.send(.processQuestion(feature.value(\.questionText), project))
                    }
                }
                
                Button {
                    if let project = selectedProject {
                        feature.send(.processQuestion(feature.value(\.questionText), project))
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
            }
            .padding()
        }
    }
}
