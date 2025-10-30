//
//  WindowAccessor.swift
//  Raven
//
//  Created by Eldar Tutnjic on 30.10.25.
//

import SwiftUI

struct WindowAccessor: NSViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(
        context: Context
    ) -> AttachableView {
        let v = AttachableView()
        v.onWindowAvailable = { window in
            window.delegate = context.coordinator
        }
        return v
    }

    func updateNSView(
        _ nsView: AttachableView,
        context: Context
    ) {}

    final class Coordinator: NSObject, NSWindowDelegate {
        private var alertIsPresented = false

        func windowShouldClose(_ sender: NSWindow) -> Bool {
            guard !alertIsPresented else { return true }
            alertIsPresented = true

            let alert = QuitAlert.make()
            alert.beginSheetModal(for: sender) { response in
                if response == .alertFirstButtonReturn {
                    sender.close()
                }
                self.alertIsPresented = false
            }
            return false
        }
    }
}

final class AttachableView: NSView {
    var onWindowAvailable: ((NSWindow) -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let w = window {
            onWindowAvailable?(w)
            onWindowAvailable = nil
        }
    }
}
