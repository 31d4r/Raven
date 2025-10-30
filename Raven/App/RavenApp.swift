//
//  RavenApp.swift
//  Raven
//
//  Created by Eldar Tutnjic on 25.07.25.
//

import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool { true }
}

@main
struct RavenApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appContainer = AppContainer()

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environment(appContainer.projectsFeature)
                .environment(appContainer.projectFilesFeature)
                .environment(appContainer.mainContentFeature)
                .background(WindowAccessor())
        }
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
    }
}
