//
//  ChatAppearance.swift
//  Raven
//
//  The shape and color a chat shows in the sidebar, title and bubbles.
//  Stored in UserDefaults by chat id, so the database schema stays as is.
//

import RDatabaseManager
import SwiftUI

/// Avatar colors, in picker order. Raw values are what side storage saves,
/// so existing ones never change (“graphite” is shown as Gray).
enum ChatColor: String, CaseIterable, Identifiable, Codable {
    case white, brown, red, orange, amber, green, teal, blue, purple, pink, graphite, black

    var id: String { rawValue }

    /// Avatar fill.
    var color: Color {
        switch self {
        case .white: Color(white: 0.98)
        case .brown: .brown
        case .red: .red
        case .orange: .orange
        case .amber: Color(red: 0.98, green: 0.75, blue: 0.16)
        case .green: .green
        case .teal: .teal
        case .blue: .blue
        case .purple: .purple
        case .pink: .pink
        case .graphite: Color(white: 0.56)
        case .black: Color(white: 0.1)
        }
    }

    /// Tint for things drawn on the window background, like the typing
    /// dots; white would vanish there.
    var accent: Color {
        switch self {
        case .white: .gray
        case .black: .primary
        default: color
        }
    }

    /// Fills that sit close to the background get a hairline edge.
    func needsOutline(in scheme: ColorScheme) -> Bool {
        switch self {
        case .white: scheme == .light
        case .black: scheme == .dark
        default: false
        }
    }

    /// Fill for the user’s bubbles: darkened so white text stays legible,
    /// and darker again with Increase Contrast.
    func bubbleFill(increasedContrast: Bool) -> Color {
        let extra = increasedContrast ? 0.15 : 0
        switch self {
        case .white: return Color(white: increasedContrast ? 0.22 : 0.34)
        case .black: return Color(white: increasedContrast ? 0.06 : 0.14)
        case .graphite: return Color(white: 0.56).mix(with: .black, by: 0.4 + extra)
        case .amber: return color.mix(with: .black, by: 0.42 + extra)
        case .orange, .green, .teal: return color.mix(with: .black, by: 0.32 + extra)
        case .pink, .brown: return color.mix(with: .black, by: 0.2 + extra)
        default: return color.mix(with: .black, by: 0.1 + extra)
        }
    }

    var name: String {
        switch self {
        case .white: String(localized: "chatColor.white", defaultValue: "White", comment: "Chat color name")
        case .brown: String(localized: "chatColor.brown", defaultValue: "Brown", comment: "Chat color name")
        case .red: String(localized: "chatColor.red", defaultValue: "Red", comment: "Chat color name")
        case .orange: String(localized: "chatColor.orange", defaultValue: "Orange", comment: "Chat color name")
        case .amber: String(localized: "chatColor.amber", defaultValue: "Yellow", comment: "Chat color name")
        case .green: String(localized: "chatColor.green", defaultValue: "Green", comment: "Chat color name")
        case .teal: String(localized: "chatColor.teal", defaultValue: "Teal", comment: "Chat color name")
        case .blue: String(localized: "chatColor.blue", defaultValue: "Blue", comment: "Chat color name")
        case .purple: String(localized: "chatColor.purple", defaultValue: "Purple", comment: "Chat color name")
        case .pink: String(localized: "chatColor.pink", defaultValue: "Pink", comment: "Chat color name")
        case .graphite: String(localized: "chatColor.graphite", defaultValue: "Gray", comment: "Chat color name")
        case .black: String(localized: "chatColor.black", defaultValue: "Black", comment: "Chat color name")
        }
    }

    /// Reads a saved value, including colors that are no longer offered.
    static func stored(_ rawValue: String) -> (color: ChatColor, isLegacy: Bool)? {
        if let color = ChatColor(rawValue: rawValue) { return (color, false) }
        return rawValue == "indigo" ? (.blue, true) : nil
    }
}

struct ChatAppearance: Equatable, Codable {
    var shape: ChatShape
    var color: ChatColor

    /// Chats without a saved choice get a stable color from their id, in
    /// the order the original palette used.
    static func fallback(for id: Int64?) -> ChatAppearance {
        let colors: [ChatColor] = [.graphite, .blue, .blue, .purple, .pink, .red, .orange, .green, .teal, .brown]
        let index = Int((id ?? 0).magnitude % UInt64(colors.count))
        return ChatAppearance(shape: .circle, color: colors[index])
    }

    static func random() -> ChatAppearance {
        ChatAppearance(
            shape: ChatShape.allCases.randomElement() ?? .circle,
            color: ChatColor.allCases.filter { $0 != .white && $0 != .black }.randomElement() ?? .blue
        )
    }
}

/// Saves each chat’s appearance in UserDefaults under one dictionary,
/// keyed by chat id, as "shape|color". No database or schema change.
/// Values saved before shapes held an SF Symbol name; they load as the
/// matching shape and are rewritten once.
@Observable
final class ChatAppearanceStore {
    static let shared = ChatAppearanceStore()

    private var appearances: [Int64: ChatAppearance]
    /// Chosen in the New Chat card, assigned once the chat is created.
    @ObservationIgnored private var pendingAppearance: ChatAppearance?
    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let saved = defaults.dictionary(forKey: Self.storageKey) as? [String: String] ?? [:]
        var appearances: [Int64: ChatAppearance] = [:]
        var needsMigration = false
        for (key, value) in saved {
            let parts = value.split(separator: Self.separator).map(String.init)
            guard let id = Int64(key), parts.count == 2, let color = ChatColor.stored(parts[1]) else { continue }
            let shape: ChatShape
            if let current = ChatShape(rawValue: parts[0]) {
                shape = current
            } else {
                shape = ChatShape.legacy(symbolName: parts[0]) ?? .circle
                needsMigration = true
            }
            needsMigration = needsMigration || color.isLegacy
            appearances[id] = ChatAppearance(shape: shape, color: color.color)
        }
        self.appearances = appearances
        if needsMigration { save() }
    }

    func appearance(for project: Project?) -> ChatAppearance {
        guard let id = project?.id else { return .fallback(for: nil) }
        return appearances[id] ?? .fallback(for: id)
    }

    func setPendingAppearance(_ appearance: ChatAppearance) {
        pendingAppearance = appearance
    }

    func assignPendingAppearance(to id: Int64) {
        guard let pendingAppearance else { return }
        self.pendingAppearance = nil
        appearances[id] = pendingAppearance
        save()
    }

    func setAppearance(_ appearance: ChatAppearance, for id: Int64) {
        guard appearances[id] != appearance else { return }
        appearances[id] = appearance
        save()
    }

    func removeAppearance(for id: Int64) {
        guard appearances[id] != nil else { return }
        appearances[id] = nil
        save()
    }

    private func save() {
        let encoded = Dictionary(uniqueKeysWithValues: appearances.map { id, appearance in
            (String(id), "\(appearance.shape.rawValue)\(Self.separator)\(appearance.color.rawValue)")
        })
        defaults.set(encoded, forKey: Self.storageKey)
    }

    private static let storageKey = "chatAppearances"
    private static let separator: Character = "|"
}

/// A chat's shape in its color, with a hairline edge where the fill sits
/// close to the background. Fills its frame and
/// morphs when the shape changes inside an animation.
struct ChatShapeGlyph: View {
    let shape: ChatShape
    let color: ChatColor
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            ChatShapeOutline(points: shape.outline)
                .fill(color.color)
            if color.needsOutline(in: colorScheme) {
                ChatShapeOutline(points: shape.outline)
                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

/// A chat's avatar at a fixed size that follows Dynamic Type.
struct ChatAvatar: View {
    let appearance: ChatAppearance
    let size: CGFloat
    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

    var body: some View {
        let side = size * scale
        ChatShapeGlyph(shape: appearance.shape, color: appearance.color)
            .frame(width: side, height: side)
            .accessibilityHidden(true)
    }
}

/// The large avatar in the New Chat card: springs between shapes, or
/// crossfades with Reduce Motion.
struct ChatAvatarPreview: View {
    let appearance: ChatAppearance
    let size: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            ZStack {
                ChatAvatar(appearance: appearance, size: size)
                    .id(appearance.shape)
                    .transition(.opacity)
            }
            .animation(.easeInOut(duration: 0.25), value: appearance)
        } else {
            ChatAvatar(appearance: appearance, size: size)
                .animation(DesignSystem.Conversation.shapeMorph, value: appearance.shape)
                .animation(.easeInOut(duration: 0.2), value: appearance.color)
        }
    }
}
