//
//  ChatAppearance.swift
//  Raven
//
//  The icon and color a chat shows in the sidebar, title and bubbles.
//  Stored in UserDefaults by chat id, so the database schema stays as is.
//

import RDatabaseManager
import SwiftUI

enum ChatColor: String, CaseIterable, Identifiable, Codable {
    case graphite, blue, indigo, purple, pink, red, orange, green, teal, brown

    var id: String { rawValue }

    /// Avatar fill. Every color keeps a white symbol readable.
    var color: Color {
        switch self {
        case .graphite: Color(white: 0.26)
        case .blue: .blue
        case .indigo: .indigo
        case .purple: .purple
        case .pink: .pink
        case .red: .red
        case .orange: .orange
        case .green: .green
        case .teal: .teal
        case .brown: .brown
        }
    }

    /// Fill for the user’s bubbles: darkened so white text stays legible,
    /// and darker again with Increase Contrast.
    func bubbleFill(increasedContrast: Bool) -> Color {
        let base: Double = switch self {
        case .orange, .green, .teal: 0.32
        case .pink, .brown: 0.2
        case .graphite: 0
        default: 0.1
        }
        return color.mix(with: .black, by: increasedContrast ? base + 0.15 : base)
    }

    var name: String {
        switch self {
        case .graphite: String(localized: "chatColor.graphite", defaultValue: "Graphite", comment: "Chat color name")
        case .blue: String(localized: "chatColor.blue", defaultValue: "Blue", comment: "Chat color name")
        case .indigo: String(localized: "chatColor.indigo", defaultValue: "Indigo", comment: "Chat color name")
        case .purple: String(localized: "chatColor.purple", defaultValue: "Purple", comment: "Chat color name")
        case .pink: String(localized: "chatColor.pink", defaultValue: "Pink", comment: "Chat color name")
        case .red: String(localized: "chatColor.red", defaultValue: "Red", comment: "Chat color name")
        case .orange: String(localized: "chatColor.orange", defaultValue: "Orange", comment: "Chat color name")
        case .green: String(localized: "chatColor.green", defaultValue: "Green", comment: "Chat color name")
        case .teal: String(localized: "chatColor.teal", defaultValue: "Teal", comment: "Chat color name")
        case .brown: String(localized: "chatColor.brown", defaultValue: "Brown", comment: "Chat color name")
        }
    }
}

enum ChatSymbol: String, CaseIterable, Identifiable, Codable {
    case bubble = "bubble.left.fill"
    case book = "book.closed.fill"
    case document = "doc.text.fill"
    case folder = "folder.fill"
    case lightbulb = "lightbulb.fill"
    case star = "star.fill"
    case heart = "heart.fill"
    case leaf = "leaf.fill"
    case flame = "flame.fill"
    case bolt = "bolt.fill"
    case graduation = "graduationcap.fill"
    case briefcase = "briefcase.fill"
    case music = "music.note"
    case camera = "camera.fill"

    var id: String { rawValue }

    var name: String {
        switch self {
        case .bubble: String(localized: "chatSymbol.bubble", defaultValue: "Speech Bubble", comment: "Chat icon name")
        case .book: String(localized: "chatSymbol.book", defaultValue: "Book", comment: "Chat icon name")
        case .document: String(localized: "chatSymbol.document", defaultValue: "Document", comment: "Chat icon name")
        case .folder: String(localized: "chatSymbol.folder", defaultValue: "Folder", comment: "Chat icon name")
        case .lightbulb: String(localized: "chatSymbol.lightbulb", defaultValue: "Light Bulb", comment: "Chat icon name")
        case .star: String(localized: "chatSymbol.star", defaultValue: "Star", comment: "Chat icon name")
        case .heart: String(localized: "chatSymbol.heart", defaultValue: "Heart", comment: "Chat icon name")
        case .leaf: String(localized: "chatSymbol.leaf", defaultValue: "Leaf", comment: "Chat icon name")
        case .flame: String(localized: "chatSymbol.flame", defaultValue: "Flame", comment: "Chat icon name")
        case .bolt: String(localized: "chatSymbol.bolt", defaultValue: "Bolt", comment: "Chat icon name")
        case .graduation: String(localized: "chatSymbol.graduation", defaultValue: "Graduation Cap", comment: "Chat icon name")
        case .briefcase: String(localized: "chatSymbol.briefcase", defaultValue: "Briefcase", comment: "Chat icon name")
        case .music: String(localized: "chatSymbol.music", defaultValue: "Music", comment: "Chat icon name")
        case .camera: String(localized: "chatSymbol.camera", defaultValue: "Camera", comment: "Chat icon name")
        }
    }
}

struct ChatAppearance: Equatable, Codable {
    var symbol: ChatSymbol
    var color: ChatColor

    /// Chats without a saved choice get a stable color from their id.
    static func fallback(for id: Int64?) -> ChatAppearance {
        let colors = ChatColor.allCases
        let index = Int((id ?? 0).magnitude % UInt64(colors.count))
        return ChatAppearance(symbol: .bubble, color: colors[index])
    }

    static func random() -> ChatAppearance {
        ChatAppearance(symbol: .bubble, color: ChatColor.allCases.randomElement() ?? .blue)
    }
}

/// Saves each chat’s appearance in UserDefaults under one dictionary,
/// keyed by chat id. No database or schema change.
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
        for (key, value) in saved {
            let parts = value.split(separator: Self.separator).map(String.init)
            guard let id = Int64(key), parts.count == 2,
                  let symbol = ChatSymbol(rawValue: parts[0]),
                  let color = ChatColor(rawValue: parts[1]) else { continue }
            appearances[id] = ChatAppearance(symbol: symbol, color: color)
        }
        self.appearances = appearances
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

    func removeAppearance(for id: Int64) {
        guard appearances[id] != nil else { return }
        appearances[id] = nil
        save()
    }

    private func save() {
        let encoded = Dictionary(uniqueKeysWithValues: appearances.map { id, appearance in
            (String(id), "\(appearance.symbol.rawValue)\(Self.separator)\(appearance.color.rawValue)")
        })
        defaults.set(encoded, forKey: Self.storageKey)
    }

    private static let storageKey = "chatAppearances"
    private static let separator: Character = "|"
}

/// Round avatar: the chat color with its white symbol.
struct ChatAvatar: View {
    let appearance: ChatAppearance
    let size: CGFloat
    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

    var body: some View {
        let diameter = size * scale
        Circle()
            .fill(appearance.color.color.gradient)
            .overlay {
                Image(systemName: appearance.symbol.rawValue)
                    .font(.system(size: diameter * DesignSystem.Conversation.avatarSymbolScale, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: diameter, height: diameter)
            .accessibilityHidden(true)
    }
}
