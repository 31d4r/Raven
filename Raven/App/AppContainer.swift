//
//  AppContainer.swift
//  Raven
//
//  Created by Eldar Tutnjic on 10.09.25.
//

import RDatabaseManager
import RFoundationsManager
import SwiftUI

@Observable
class AppContainer {
    let databaseManager = RDatabaseManager()
    let foundationsManager = RFoundationsManager()

    var projectsFeature: ProjectsView.ProjectsFeature
    var projectFilesFeature: ProjectFilesView.ProjectFilesFeature
    var mainContentFeature: MainContentView.MainContentFeature

    init() {
        self.projectsFeature = ProjectsView.ProjectsFeature(
            databaseManager: databaseManager
        )
        self.projectFilesFeature = ProjectFilesView.ProjectFilesFeature(
            databaseManager: databaseManager
        )
        self.mainContentFeature = MainContentView.MainContentFeature()
    }
}
