//
//  DashboardView.swift
//  Raven
//
//  Created by Eldar Tutnjic on 18.07.25.
//

import RDatabaseManager
import SwiftUI

struct DashboardView: View {
    @State private var showInspector = true
    @State private var selectedProject: Project?

    var body: some View {
        NavigationSplitView {
            ProjectsView(selectedProject: $selectedProject)
        } detail: {
            MainContentView(
                selectedProject: selectedProject
            )
        }
        .inspector(isPresented: $showInspector) {
            LeftSidebarView(selectedProject: selectedProject)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showInspector.toggle()
                } label: {
                    Image(systemName: "sidebar.trailing")
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}
