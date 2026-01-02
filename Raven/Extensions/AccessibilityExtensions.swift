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
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    func body(content: Content) -> some View {
        content
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

extension View {
    func supportsDynamicType() -> some View {
        modifier(DynamicTypeModifier())
    }
}

