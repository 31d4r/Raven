//
//  PodcastCustomizationView.swift
//  Parrot
//
//  Created by Eldar Tutnjic on 24.07.25.
//

import SwiftUI

struct PodcastCustomizationView: View {
    var feature: RightSidebarView.RightSidebarFeature

    var body: some View {
        VStack(spacing: 32) {
            Text("Customize Podcast")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Picker(
                "Host Style",
                selection: feature.binding(for: \.hostStyle)
            ) {
                Text("Casual & Friendly")
                    .tag("casual")
                Text("Professional")
                    .tag("professional")
                Text("Entertaining")
                    .tag("entertaining")
            }
            .pickerStyle(.menu)

            Picker(
                "Length",
                selection: feature.binding(for: \.podcastLength)
            ) {
                Text("Short (5-7 min)")
                    .tag("short")
                Text("Medium (10-15 min)")
                    .tag("medium")
                Text("Long (20-25 min)").tag(
                    "long"
                )
            }
            .pickerStyle(.menu)

            HStack(spacing: 12) {
                Button {
                    feature.send(.hideCustomization)
                } label: {
                    Text("Cancel")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    feature.send(.hideCustomization)
                } label: {
                    Text("Done")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding()
        .frame(width: 400)
    }
}

#Preview {
    PodcastCustomizationView(feature: .init())
}
