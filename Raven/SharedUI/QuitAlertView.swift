//
//  QuitAlertView.swift
//  Raven
//
//  Created by Eldar Tutnjic on 30.10.25.
//

import SwiftUI

#if os(macOS)
enum QuitAlert {
    static func make() -> NSAlert {
        let alert = NSAlert()
        alert.messageText = DesignSystem.Quit.title
        alert.informativeText = DesignSystem.Quit.message
        alert.alertStyle = .informational
        alert.addButton(withTitle: DesignSystem.Quit.quit)
        alert.addButton(withTitle: DesignSystem.Common.cancel)
        return alert
    }
}
#endif
