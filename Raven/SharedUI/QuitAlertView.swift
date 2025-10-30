//
//  QuitAlertView.swift
//  Raven
//
//  Created by Eldar Tutnjic on 30.10.25.
//

import SwiftUI

enum QuitAlert {
    static let title = "Quit Raven?"
    static let message = "Are you sure you want to quit Raven?"
    static let primary = "Quit"
    static let cancel = "Cancel"

    static func make() -> NSAlert {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: primary)
        alert.addButton(withTitle: cancel)
        return alert
    }
}
