//
//  LeftSidebarView.swift
//  Parrot
//
//  Created by Eldar Tutnjic on 24.07.25.
//

import SwiftUI

struct LeftSidebarView: View {
    @State var feature = LeftSidebarFeature()
    let selectedProject: Project?
    
    init(selectedProject: Project?) {
        self.selectedProject = selectedProject
    }
    
    var body: some View {
        content()
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .topLeading
            )
            .padding(.top)
            .background(Color(NSColor.controlBackgroundColor))
            .onChange(of: selectedProject) { _, newProject in
                if let project = newProject {
                    feature.send(.loadFiles(project))
                }
            }
            .task {
                if let project = selectedProject {
                    feature.send(.loadFiles(project))
                }
            }
    }
    
    func content() -> some View {
        VStack(
            alignment: .leading,
            spacing: 0
        ) {
            headerView()
            
            if selectedProject != nil {
                filesListView()
            } else {
                noProjectSelectedView()
            }
        }
    }
    
    func headerView() -> some View {
        VStack(spacing: 10) {
            ButtonView(
                systemImageName: "plus",
                buttonText: "Add Sources"
            ) {
                if selectedProject != nil {
                    feature.openFilePicker()
                }
            }
            .disabled(selectedProject == nil)
        }
    }
    
    func noProjectSelectedView() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            
            Text("Select a project to add sources")
                .foregroundColor(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }
    
    func filesListView() -> some View {
        VStack(
            alignment: .leading,
            spacing: 0
        ) {
            if feature.value(\.isLoading) {
                ProgressView("Loading files...")
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
            } else if feature.value(\.files).isEmpty {
                emptyFilesView()
            } else {
                filesList()
            }
        }
    }
    
    func emptyFilesView() -> some View {
        VStack(spacing: 15) {
            Image(systemName: "doc.plaintext")
                .font(.system(size: 24))
                .foregroundColor(.secondary)
            
            Text("No sources added yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Click 'Add Sources' to get started")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }
    
    func filesList() -> some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(feature.value(\.files), id: \.id) { file in
                    FileRowView(file: file) {
                        feature.send(.deleteFile(file))
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
