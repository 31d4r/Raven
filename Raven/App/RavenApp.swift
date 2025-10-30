//
//  RavenApp.swift
//  Raven
//
//  Created by Eldar Tutnjic on 25.07.25.
//

import SwiftUI

@main
struct RavenApp: App {
    @State private var appContainer = AppContainer()

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environment(appContainer.projectsFeature)
                .environment(appContainer.projectFilesFeature)
                .environment(appContainer.mainContentFeature)
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
