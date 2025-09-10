//
//  AppContainer.swift
//  Raven
//
//  Created by Eldar Tutnjic on 10.09.25.
//

import SwiftUI

@Observable
class AppContainer {
    let databaseManager = DatabaseManager()
    let foundationsManager = FoundationsManager()

    var projectsFeature: ProjectsView.ProjectsFeature
    var leftSidebarFeature: LeftSidebarView.LeftSidebarFeature
    var rightSidebarFeature: RightSidebarView.RightSidebarFeature
    var mainContentFeature: MainContentView.MainContentFeature

    init() {
        self.projectsFeature = ProjectsView.ProjectsFeature(
            databaseManager: databaseManager
        )
        self.leftSidebarFeature = LeftSidebarView.LeftSidebarFeature(
            databaseManager: databaseManager
        )
        self.rightSidebarFeature = RightSidebarView.RightSidebarFeature(
            foundationsManager: foundationsManager,
            databaseManager: databaseManager
        )
        self.mainContentFeature = MainContentView.MainContentFeature()
    }
}
