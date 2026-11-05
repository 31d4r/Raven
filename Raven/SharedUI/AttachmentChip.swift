//
//  AttachmentChip.swift
//  Raven
//
//  A file waiting in the composer: thumbnail with a remove button. It is
//  added to the chat’s sources when the user sends.
//

import QuickLookThumbnailing
import SwiftUI
import UniformTypeIdentifiers

struct PendingAttachment: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    /// A copy Raven made (photos, iPad drops); its folder is removed after use.
    let isTemporaryCopy: Bool

    func discard() {
        guard isTemporaryCopy else { return }
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }

    /// Writes image data into its own temporary folder so cleanup can remove it.
    static func temporaryCopy(of data: Data, fileExtension: String) throws -> PendingAttachment {
        let folder = FileManager.default.temporaryDirectory
            .appending(path: "Raven-Attachments", directoryHint: .isDirectory)
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appending(path: "\(UUID().uuidString).\(fileExtension)")
        try data.write(to: url)
        return PendingAttachment(url: url, isTemporaryCopy: true)
    }
}

/// A video from the photo library, copied into its own temporary folder.
nonisolated struct PickedMovie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let folder = FileManager.default.temporaryDirectory
                .appending(path: "Raven-Attachments", directoryHint: .isDirectory)
                .appending(path: UUID().uuidString, directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let destination = folder.appending(path: received.file.lastPathComponent)
            try FileManager.default.copyItem(at: received.file, to: destination)
            return PickedMovie(url: destination)
        }
    }
}

struct AttachmentChip: View {
    let attachment: PendingAttachment
    let onRemove: () -> Void

    @Environment(\.displayScale) private var displayScale
    @Environment(\.colorSchemeContrast) private var contrast
    @ScaledMetric(relativeTo: .body) private var size = DesignSystem.Conversation.attachmentSize
    @State private var thumbnail: CGImage?

    private var fileName: String { attachment.url.lastPathComponent }

    var body: some View {
        preview
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Conversation.attachmentRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DesignSystem.Conversation.attachmentRadius, style: .continuous)
                    .strokeBorder(contrast == .increased ? Color.primary : DesignSystem.ConversationColors.composerBorder)
            }
            .overlay(alignment: .topTrailing) {
                Button(action: onRemove) {
                    Image(systemName: DesignSystem.Icons.removeAttachment)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, Color.black.opacity(0.65))
                        .font(.body)
                }
                .buttonStyle(.plain)
                .padding(DesignSystem.Spacing.xSmall / 2)
                .help(DesignSystem.Conversation.removeAttachment)
                .accessibilityHidden(true)
            }
            .help(fileName)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(DesignSystem.Conversation.attachmentLabel(fileName))
            .accessibilityAction(named: Text(DesignSystem.Conversation.removeAttachment), onRemove)
            .accessibilityIdentifier("attachmentChip")
            .task(id: attachment.url) {
                thumbnail = await Self.makeThumbnail(for: attachment.url, side: size, scale: displayScale)
            }
    }

    @ViewBuilder
    private var preview: some View {
        if let thumbnail {
            Image(decorative: thumbnail, scale: displayScale)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                DesignSystem.ConversationColors.assistantBubble
                VStack(spacing: DesignSystem.Spacing.labelToMeta) {
                    Image(systemName: "doc")
                        .font(.title3)
                    Text(attachment.url.pathExtension.uppercased())
                        .font(.caption2.weight(.semibold))
                        .lineLimit(1)
                }
                .foregroundStyle(DesignSystem.Colors.supporting)
            }
        }
    }

    private static func makeThumbnail(for url: URL, side: CGFloat, scale: CGFloat) async -> CGImage? {
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: CGSize(width: side, height: side),
            scale: scale,
            representationTypes: .thumbnail
        )
        return try? await QLThumbnailGenerator.shared.generateBestRepresentation(for: request).cgImage
    }
}
