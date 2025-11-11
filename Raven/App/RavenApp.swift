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
        }
        #if os(macOS)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button {
                    appContainer.projectsFeature.send(.showNewProjectAlert)
                } label: {
                    Text("New Chat")
                }
                .keyboardShortcut(
                    "n",
                    modifiers: [.command]
                )
            }
        }
        #endif
    }
}
