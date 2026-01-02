//
//  FileRowView.swift
//  Raven
//
//  Created by Eldar Tutnjic on 24.07.25.
//

import QuickLook
import RDatabaseManager
import SwiftUI

struct FileRowView: View {
    let file: FileRecord
    let onDelete: () -> Void
    @State private var selectedURL: URL?
    
    var body: some View {
        HStack(spacing: 12) {
            fileIcon(for: file.fileType)
                .accessibilityHidden(true)
            
            VStack(
                alignment: .leading,
                spacing: 2
            ) {
                Text(file.name)
                    .font(.subheadline)
                    .lineLimit(1)
                    .accessibilityLabel("File: \(file.name)")
                
                Text(
                    file.createdAt.formatted(
                        date: .numeric,
                        time: .shortened
                    )
                )
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Added \(file.createdAt.formatted(date: .numeric, time: .shortened))")
            }
            
            Spacer()
            
            Menu {
                Button {
                    selectedURL = URL(fileURLWithPath: file.publicPath)
                } label: {
                    Text("Preview")
                }
                .accessibilityLabel("Preview \(file.name)")
                .accessibilityHint("Opens preview of the file")
                
                Button {
                    onDelete()
                } label: {
                    Text("Delete")
                }
                .accessibilityLabel("Delete \(file.name)")
                .accessibilityHint("Deletes this file from the chat")
     
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
            .menuStyle(.borderlessButton)
            .accessibilityLabel("File Actions")
            .accessibilityHint("Opens menu with actions for \(file.name)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(
            8,
            corners: .allCorners
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(file.name), \(file.fileType) file, added \(file.createdAt.formatted(date: .numeric, time: .shortened))")
        .accessibilityIdentifier("fileRow_\(String(describing: file.id))")
        .quickLookPreview(
            $selectedURL,
            in: [URL(
                fileURLWithPath: file.publicPath
            )]
        )
    }
    
    func fileIcon(for fileType: String) -> some View {
        let iconName: String
        let color: Color
        
        switch fileType.lowercased() {
        case "mp3", "wav", "aiff", "m4a":
            iconName = "waveform"
            color = .blue
        case "jpg", "jpeg", "png", "tiff", "heic":
            iconName = "photo"
            color = .green
        case "pdf":
            iconName = "doc.richtext"
            color = .red
        case "mp4", "mov", "avi", "mkv", "m4v":
            iconName = "film"
            color = .purple
        default:
            iconName = "doc"
            color = .gray
        }
        
        return Image(systemName: iconName)
            .foregroundColor(color)
            .font(.title3)
            .accessibilityLabel("\(fileType) file icon")
    }
}
