//
//  AccessibilityExtensions.swift
//  Raven
//
//  Created for accessibility improvements
//

import SwiftUI


@MainActor
struct AccessibilityHelper {
    /// Speaks a short status update with VoiceOver on every platform.
    static func announce(_ message: String) {
        AccessibilityNotification.Announcement(message).post()
    }
}

struct DynamicTypeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}

struct ReducedMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    var animation: Animation?
    var value: AnyHashable
    
    func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? nil : animation, value: value)
    }
}

struct HighContrastModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) var contrast
    var normalColor: Color
    var highContrastColor: Color
    
    func body(content: Content) -> some View {
        content
            .foregroundStyle(contrast == .increased ? highContrastColor : normalColor)
    }
}

extension View {
    func supportsDynamicType() -> some View {
        modifier(DynamicTypeModifier())
    }
    
    func respectsReducedMotion(animation: Animation? = .default, value: AnyHashable) -> some View {
        modifier(ReducedMotionModifier(animation: animation, value: value))
    }
    
    func adaptiveColor(normal: Color, highContrast: Color) -> some View {
        modifier(HighContrastModifier(normalColor: normal, highContrastColor: highContrast))
    }
}

