//
//  RavenApp.swift
//  Raven
//
//  Created by Eldar Tutnjic on 25.07.25.
//

import SwiftUI

#if os(macOS)
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool { true }
}
#endif

@main
struct RavenApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    @State private var appContainer = AppContainer()

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environment(appContainer.projectsFeature)
                .environment(appContainer.projectFilesFeature)
                .environment(appContainer.mainContentFeature)
            #if os(macOS)
                .background(WindowAccessor())
            #endif
                .accessibilityElement(children: .contain)
        }
        #if os(macOS)
        .defaultSize(
            width: DesignSystem.Layout.windowDefaultSize.width,
            height: DesignSystem.Layout.windowDefaultSize.height
        )
        .windowResizability(.contentMinSize)
        .windowToolbarStyle(.unified(showsTitle: false))
        #endif
        .commands {
            RavenCommands(
                projectsFeature: appContainer.projectsFeature,
                filesFeature: appContainer.projectFilesFeature,
                chatFeature: appContainer.mainContentFeature
            )
        }

        #if os(macOS)
        Window(DesignSystem.Menu.keyboardShortcuts, id: DesignSystem.Shortcuts.windowID) {
            KeyboardShortcutsView()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        #endif
    }
}
