//
//  DashboardView.swift
//  Parrot
//
//  Created by Eldar Tutnjic on 18.07.25.
//

import SwiftUI

struct DashboardView: View {
    @State private var showLeftSidebar = true
    @State private var showRightSidebar = true
    @State private var selectedProject: Project?

    var body: some View {
        NavigationSplitView {
            ProjectsView(selectedProject: $selectedProject)
        } detail: {
            MainContentView(
                showLeftSidebar: $showLeftSidebar,
                showRightSidebar: $showRightSidebar,
                selectedProject: selectedProject
            )
        }
        .navigationSplitViewStyle(.balanced)
    }
}
