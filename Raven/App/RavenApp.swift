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
                .environment(appContainer.leftSidebarFeature)
                .environment(appContainer.rightSidebarFeature)
                .environment(appContainer.mainContentFeature)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button {
                    appContainer.projectsFeature.send(.showNewProjectAlert)
                } label: {
                    Text("New Project")
                }
                .keyboardShortcut(
                    "n",
                    modifiers: [.command]
                )
            }
        }
    }
}
