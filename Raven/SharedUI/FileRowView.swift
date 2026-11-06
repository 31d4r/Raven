//
//  FileRowView.swift
//  Raven
//
//  Created by Eldar Tutnjic on 24.07.25.
//

import RDatabaseManager
import SwiftUI

/// One source in the Sources list. Commands come from the list’s context
/// menu, swipe actions and VoiceOver actions, so the row stays quiet.
struct FileRowView: View {
    let file: FileRecord

    @ScaledMetric(relativeTo: .title3) private var iconWidth: CGFloat = 24

    private var kind: String {
        DesignSystem.Sources.kind(forExtension: file.fileType)
    }

    private var addedDate: String {
        file.createdAt.formatted(date: .abbreviated, time: .shortened)
    }

    private var spokenName: String {
        let base = (file.name as NSString).deletingPathExtension
        return DesignSystem.Sources.spokenName(base.isEmpty ? file.name : base, kind)
    }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.small + 2) {
            Image(systemName: DesignSystem.Sources.icon(forExtension: file.fileType))
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: iconWidth)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.labelToMeta) {
                Text(file.name)
                    .font(.callout)
                    .lineLimit(2)
                    .truncationMode(.middle)

                Text(DesignSystem.Sources.meta(kind, addedDate))
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.supporting)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, DesignSystem.Spacing.labelToMeta)
        .contentShape(Rectangle())
        .help(file.name)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenName)
        .accessibilityValue(DesignSystem.Sources.addedOn(addedDate))
        .accessibilityIdentifier("fileRow_\(String(describing: file.id))")
    }
}
