//
//  FileDrop.swift
//  Raven
//
//  Accepts dropped files as new sources. Mac receives file URLs; iPad
//  receives copies from other apps, so they arrive as an ImportedSource.
//

import SwiftUI
import UniformTypeIdentifiers

nonisolated struct ImportedSource: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .item) { received in
            let folder = FileManager.default.temporaryDirectory
                .appending(path: "Raven-Drops", directoryHint: .isDirectory)
                .appending(path: UUID().uuidString, directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let destination = folder.appending(path: received.file.lastPathComponent)
            try FileManager.default.copyItem(at: received.file, to: destination)
            return ImportedSource(url: destination)
        }
    }
}

private struct FileDropModifier: ViewModifier {
    @Binding var isTargeted: Bool
    let onDrop: (_ urls: [URL], _ isTemporaryCopy: Bool) -> Bool

    func body(content: Content) -> some View {
        #if os(macOS)
        content.dropDestination(for: URL.self) { urls, _ in
            onDrop(urls.filter(\.isFileURL), false)
        } isTargeted: { isTargeted = $0 }
        #else
        content.dropDestination(for: ImportedSource.self) { items, _ in
            onDrop(items.map(\.url), true)
        } isTargeted: { isTargeted = $0 }
        #endif
    }
}

/// Accent border and light fill over a non-empty area while files hover.
struct DropHighlight: View {
    let isTargeted: Bool
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        RoundedRectangle(cornerRadius: DesignSystem.Radius.highlight, style: .continuous)
            .fill(Color.accentColor.opacity(isTargeted ? DesignSystem.Colors.dropOverContentOpacity : 0))
            .strokeBorder(Color.accentColor.opacity(isTargeted ? 1 : 0), lineWidth: contrast == .increased ? 4 : 3)
            .padding(DesignSystem.Spacing.xSmall)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .animation(.easeOut(duration: 0.12), value: isTargeted)
    }
}

extension View {
    func fileDrop(isTargeted: Binding<Bool>, onDrop: @escaping (_ urls: [URL], _ isTemporaryCopy: Bool) -> Bool) -> some View {
        modifier(FileDropModifier(isTargeted: isTargeted, onDrop: onDrop))
    }
}
