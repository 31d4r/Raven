//
//  NewChatCard.swift
//  Raven
//
//  “Create New Chat” card: avatar preview, name, icon grid and colors.
//  Mac shows it as a centered card; iOS reuses the pickers in its sheet.
//

import RDatabaseManager
import SwiftUI

/// Icon grid and color row. Each choice is a button with the selected trait.
struct ChatAppearancePicker: View {
    @Binding var appearance: ChatAppearance
    @Environment(\.colorSchemeContrast) private var contrast
    @ScaledMetric(relativeTo: .body) private var cellSize: CGFloat = DesignSystem.Conversation.pickerCellSize
    @ScaledMetric(relativeTo: .body) private var swatchSize: CGFloat = DesignSystem.Conversation.swatchSize
    /// A fixed column count (Mac card); nil wraps to the available width.
    private let columns: Int?

    init(
        appearance: Binding<ChatAppearance>,
        columns: Int? = DesignSystem.Conversation.pickerColumns,
        cellSize: CGFloat = DesignSystem.Conversation.pickerCellSize,
        swatchSize: CGFloat = DesignSystem.Conversation.swatchSize
    ) {
        _appearance = appearance
        self.columns = columns
        _cellSize = ScaledMetric(wrappedValue: cellSize, relativeTo: .body)
        _swatchSize = ScaledMetric(wrappedValue: swatchSize, relativeTo: .body)
    }

    private var symbolColumns: [GridItem] {
        if let columns {
            Array(repeating: GridItem(.fixed(cellSize), spacing: DesignSystem.Spacing.small), count: columns)
        } else {
            [GridItem(.adaptive(minimum: cellSize, maximum: cellSize), spacing: DesignSystem.Spacing.small + DesignSystem.Spacing.xSmall)]
        }
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            symbolGrid
            colorRow
        }
    }

    private var symbolGrid: some View {
        LazyVGrid(
            columns: symbolColumns,
            spacing: columns == nil ? DesignSystem.Spacing.small + DesignSystem.Spacing.xSmall : DesignSystem.Spacing.small
        ) {
            ForEach(ChatSymbol.allCases) { symbol in
                let isSelected = appearance.symbol == symbol
                Button {
                    appearance.symbol = symbol
                } label: {
                    Image(systemName: symbol.rawValue)
                        .font(.system(size: cellSize * 0.42, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.white : appearance.color.color)
                        .frame(width: cellSize, height: cellSize)
                        .background {
                            Circle().fill(isSelected ? AnyShapeStyle(appearance.color.color.gradient) : AnyShapeStyle(DesignSystem.ConversationColors.assistantBubble))
                        }
                        .overlay {
                            if contrast == .increased && isSelected {
                                Circle().strokeBorder(Color.primary, lineWidth: 2)
                            }
                        }
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .help(symbol.name)
                .accessibilityLabel(symbol.name)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(DesignSystem.Conversation.iconLabel)
        .accessibilityIdentifier("newChatIconPicker")
    }

    private var colorRow: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: swatchSize + 6, maximum: swatchSize + 6), spacing: DesignSystem.Spacing.small + DesignSystem.Spacing.xSmall)],
            spacing: DesignSystem.Spacing.small
        ) {
            ForEach(ChatColor.allCases) { color in
                let isSelected = appearance.color == color
                Button {
                    appearance.color = color
                } label: {
                    Circle()
                        .fill(color.color.gradient)
                        .frame(width: swatchSize, height: swatchSize)
                        .padding(3)
                        .overlay {
                            Circle().strokeBorder(isSelected ? color.color : .clear, lineWidth: 2)
                        }
                        .overlay {
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: swatchSize * 0.45, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .help(color.name)
                .accessibilityLabel(color.name)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(DesignSystem.Conversation.colorLabel)
        .accessibilityIdentifier("newChatColorPicker")
    }
}

#if os(macOS)
struct NewChatCard: View {
    @Environment(ProjectsView.ProjectsFeature.self) private var feature
    @FocusState private var isNameFocused: Bool
    @State private var appearance = ChatAppearance.random()

    private var trimmedName: String {
        feature.value(\.newProjectName).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var createUnavailableReason: String? {
        trimmedName.isEmpty ? DesignSystem.Chats.nameRequiredReason : nil
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            VStack(spacing: DesignSystem.Spacing.large) {
                ChatAvatar(appearance: appearance, size: DesignSystem.Conversation.previewAvatarSize)
                    .animation(.snappy(duration: 0.2), value: appearance)

                TextField(
                    DesignSystem.Chats.nameField,
                    text: feature.binding(for: \.newProjectName),
                    prompt: Text(DesignSystem.Conversation.namePrompt)
                )
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.center)
                .font(.title3)
                .frame(maxWidth: DesignSystem.Conversation.newChatNameWidth)
                .focused($isNameFocused)
                .onSubmit(create)
                .accessibilityHint(DesignSystem.Chats.nameFieldHint)
                .accessibilityIdentifier("newChatNameTextField")

                ChatAppearancePicker(appearance: $appearance)
            }
            .padding(DesignSystem.Spacing.large)
            Divider()
            footer
        }
        .frame(width: DesignSystem.Conversation.newChatCardWidth)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear { isNameFocused = true }
        .accessibilityIdentifier("newChatCard")
    }

    private var header: some View {
        HStack {
            Text(DesignSystem.Conversation.createTitle)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Button {
                feature.send(.hideNewProjectAlert)
            } label: {
                Image(systemName: DesignSystem.Icons.close)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(DesignSystem.Colors.supporting)
                    .frame(width: DesignSystem.Conversation.hoverButtonSize, height: DesignSystem.Conversation.hoverButtonSize)
                    .background(Circle().fill(DesignSystem.ConversationColors.assistantBubble))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .help(DesignSystem.Conversation.close)
            .accessibilityLabel(DesignSystem.Conversation.close)
            .accessibilityInputLabels(DesignSystem.VoiceControl.dismiss)
            .accessibilityIdentifier("closeNewChatButton")
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, DesignSystem.Spacing.small + DesignSystem.Spacing.xSmall)
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button(DesignSystem.Common.cancel) {
                feature.send(.hideNewProjectAlert)
            }
            .keyboardShortcut(.cancelAction)
            .accessibilityInputLabels(DesignSystem.VoiceControl.cancel)
            .accessibilityIdentifier("cancelNewChatButton")

            Button(action: create) {
                Text(DesignSystem.Chats.create)
                    .fontWeight(.semibold)
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
            .disabled(createUnavailableReason != nil)
            .help(DesignSystem.Help.tooltip(DesignSystem.Chats.create, detail: createUnavailableReason))
            .accessibilityHint(createUnavailableReason ?? DesignSystem.Chats.newChatHelp)
            .accessibilityInputLabels(DesignSystem.VoiceControl.create)
            .accessibilityIdentifier("createNewChatButton")
        }
        .controlSize(.large)
        .padding(DesignSystem.Spacing.medium)
    }

    private func create() {
        guard createUnavailableReason == nil else { return }
        ChatAppearanceStore.shared.setPendingAppearance(appearance)
        feature.send(.createProject(trimmedName))
    }
}
#endif
