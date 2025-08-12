//
//  FileRowView.swift
//  Parrot
//
//  Created by Eldar Tutnjic on 24.07.25.
//

import QuickLook
import SwiftUI

struct FileRowView: View {
    let file: FileRecord
    let onDelete: () -> Void
    @State private var selectedURL: URL?
    
    var body: some View {
        HStack(spacing: 12) {
            fileIcon(for: file.fileType)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.subheadline)
                    .lineLimit(1)
                
                Text(file.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Menu {
                Button {
                    selectedURL = URL(fileURLWithPath: file.publicPath)
                } label: {
                    Text("Preview")
                }
                
                Button {
                    onDelete()
                } label: {
                    Text("Delete")
                }
     
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
            .menuStyle(.borderlessButton)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
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
        default:
            iconName = "doc"
            color = .gray
        }
        
        return Image(systemName: iconName)
            .foregroundColor(color)
            .font(.title3)
    }
}
