//
//  AccessibilityExtensions.swift
//  Raven
//
//  Created for accessibility improvements
//

import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@MainActor
struct AccessibilityHelper {
    static func announce(_ message: String) {
        #if os(iOS)
        UIAccessibility.post(notification: .announcement, argument: message)
        #elseif os(macOS)
        if let window = NSApplication.shared.mainWindow {
            let userInfo: [NSAccessibility.NotificationUserInfoKey: Any] = [
                .announcement: message,
                .priority: NSAccessibilityPriorityLevel.high.rawValue
            ]
            NSAccessibility.post(
                element: window,
                notification: .announcementRequested,
                userInfo: userInfo
            )
        }
        #endif
    }
}

struct DynamicTypeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .dynamicTypeSize(...DynamicTypeSize.accessibility5)
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

