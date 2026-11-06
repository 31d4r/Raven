//
//  NewChatCard.swift
//  Raven
//
//  “Create New Chat” card: a morphing shape avatar, the name, a grid of
//  14 shapes and a row of colors, and a full-width Create button.
//  A sheet on iPhone and iPad, a centered card on Mac.
//

import RDatabaseManager
import SwiftUI

/// Shape grid (2 rows of 7) and color row. Each choice is a button with
/// the selected trait; the selected one gets a gray ring.
struct ChatAppearancePicker: View {
    @Binding var appearance: ChatAppearance
    @Environment(\.colorSchemeContrast) private var contrast
    @ScaledMetric(relativeTo: .body) private var swatchSize: CGFloat = DesignSystem.Conversation.colorSwatchSize

    private var ringColor: Color {
        contrast == .increased ? .primary : DesignSystem.Colors.selectionRing
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            shapeGrid
            colorRow
        }
    }

    private var shapeGrid: some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.small),
                count: DesignSystem.Conversation.shapeColumns
            ),
            spacing: DesignSystem.Spacing.small
        ) {
            ForEach(ChatShape.allCases) { shape in
                let isSelected = appearance.shape == shape
                Button {
                    appearance.shape = shape
                } label: {
                    GeometryReader { proxy in
                        ChatShapeGlyph(shape: shape, color: appearance.color)
                            .padding(proxy.size.width * DesignSystem.Conversation.shapeOptionInset)
                            .frame(width: proxy.size.width, height: proxy.size.height)
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .overlay {
                        Circle()
                            .strokeBorder(ringColor, lineWidth: 2)
                            .opacity(isSelected ? 1 : 0)
                    }
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .help(shape.name)
                .accessibilityLabel(DesignSystem.Conversation.shapeOption(shape.name))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityIdentifier("shapeOption_\(shape.rawValue)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(DesignSystem.Conversation.shapeLabel)
        .accessibilityIdentifier("newChatIconPicker")
    }

    private var colorRow: some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.xSmall),
                count: ChatColor.allCases.count
            ),
            spacing: DesignSystem.Spacing.small
        ) {
            ForEach(ChatColor.allCases) { color in
                let isSelected = appearance.color == color
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        appearance.color = color
                    }
                } label: {
                    ColorSwatch(color: color)
                        .padding(3)
                        .overlay {
                            Circle()
                                .strokeBorder(ringColor, lineWidth: 2)
                                .opacity(isSelected ? 1 : 0)
                        }
                        .aspectRatio(1, contentMode: .fit)
                        .frame(maxWidth: swatchSize)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(color.name)
                .accessibilityLabel(color.name)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityIdentifier("colorOption_\(color.rawValue)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(DesignSystem.Conversation.colorLabel)
        .accessibilityIdentifier("newChatColorPicker")
    }
}

/// One round color choice; light and dark fills get a hairline edge.
private struct ColorSwatch: View {
    let color: ChatColor
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Circle()
            .fill(color.color)
            .overlay {
                if color.needsOutline(in: colorScheme) {
                    Circle().strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
                }
            }
    }
}

struct NewChatCard: View {
    @Environment(ProjectsView.ProjectsFeature.self) private var feature
    @Environment(\.colorSchemeContrast) private var contrast
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
            #if os(macOS)
            form
            #else
            ScrollView {
                form
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
            #endif
            createButton
        }
        #if os(macOS)
        .frame(width: DesignSystem.Conversation.newChatCardWidth)
        .fixedSize(horizontal: false, vertical: true)
        #else
        .presentationDetents([.large])
        .presentationCornerRadius(DesignSystem.Conversation.newChatSheetRadius)
        #endif
        .onAppear { isNameFocused = true }
        .accessibilityIdentifier("newChatCard")
    }

    private var form: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            ChatAvatarPreview(appearance: appearance, size: DesignSystem.Conversation.newChatAvatarSize)
            nameField
            ChatAppearancePicker(appearance: $appearance)
        }
        .padding(.horizontal, DesignSystem.Spacing.large)
        .padding(.vertical, DesignSystem.Spacing.small)
    }

    private var header: some View {
        ZStack {
            Text(DesignSystem.Conversation.createTitle)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            HStack {
                closeButton
                Spacer()
            }
        }
        #if os(macOS)
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.top, DesignSystem.Spacing.medium)
        .padding(.bottom, DesignSystem.Spacing.small)
        #else
        .padding(.horizontal, DesignSystem.Conversation.floatingBarPadding)
        .padding(.top, DesignSystem.Conversation.floatingBarPadding)
        .padding(.bottom, DesignSystem.Spacing.small)
        #endif
    }

    @ViewBuilder
    private var closeButton: some View {
        #if os(macOS)
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
        .keyboardShortcut(.cancelAction)
        .help(DesignSystem.Conversation.close)
        .accessibilityLabel(DesignSystem.Conversation.close)
        .accessibilityInputLabels(DesignSystem.VoiceControl.dismiss)
        .accessibilityIdentifier("closeNewChatButton")
        #else
        Button {
            feature.send(.hideNewProjectAlert)
        } label: {
            FloatingIcon(systemImage: DesignSystem.Icons.close)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(DesignSystem.Common.cancel)
        .accessibilityInputLabels(DesignSystem.VoiceControl.cancel)
        .accessibilityIdentifier("cancelNewChatButton")
        #endif
    }

    private var nameField: some View {
        let shape = RoundedRectangle(cornerRadius: DesignSystem.Conversation.newChatFieldRadius, style: .continuous)
        return TextField(
            DesignSystem.Chats.nameField,
            text: feature.binding(for: \.newProjectName),
            prompt: Text(DesignSystem.Conversation.namePrompt)
        )
        .font(.title3.weight(.semibold))
        .multilineTextAlignment(.center)
        .textFieldStyle(.plain)
        .padding(.vertical, DesignSystem.Spacing.medium)
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .background(shape.fill(DesignSystem.ConversationColors.assistantBubble))
        .overlay {
            if contrast == .increased {
                shape.strokeBorder(Color.primary, lineWidth: 1)
            }
        }
        .focused($isNameFocused)
        #if os(iOS)
        .submitLabel(.done)
        #endif
        .onSubmit(create)
        .accessibilityHint(DesignSystem.Chats.nameFieldHint)
        .accessibilityIdentifier("newChatNameTextField")
    }

    private var createButton: some View {
        Button(action: create) {
            Text(DesignSystem.Chats.create)
                .font(.headline)
        }
        .buttonStyle(CreateCapsuleButtonStyle())
        .keyboardShortcut(.defaultAction)
        .disabled(createUnavailableReason != nil)
        #if os(macOS)
        .help(DesignSystem.Help.tooltip(DesignSystem.Chats.create, detail: createUnavailableReason))
        #endif
        .accessibilityHint(createUnavailableReason ?? DesignSystem.Chats.newChatHelp)
        .accessibilityInputLabels(DesignSystem.VoiceControl.create)
        .accessibilityIdentifier("createNewChatButton")
        .padding(.horizontal, DesignSystem.Spacing.large)
        .padding(.top, DesignSystem.Spacing.small)
        .padding(.bottom, DesignSystem.Conversation.floatingBarPadding)
    }

    private func create() {
        guard createUnavailableReason == nil else { return }
        ChatAppearanceStore.shared.setPendingAppearance(appearance)
        feature.send(.createProject(trimmedName))
    }
}

/// Full-width capsule in the primary color: black in light mode, white in
/// dark mode, dimmed while disabled.
private struct CreateCapsuleButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Conversation.createButtonPadding)
            .background {
                Capsule().fill(Color.primary.opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.22))
            }
            .contentShape(Capsule())
    }
}
