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
        VStack(
            alignment: .leading,
            spacing: 20
        ) {
            Text("Customize Podcast")
                .font(.title2)
                .fontWeight(.medium)
            
            VStack(
                alignment: .leading,
                spacing: 10
            ) {
                Text("Host Style")
                    .font(.headline)
                
                Picker(
                    "Host Style",
                    selection: feature.binding(for: \.hostStyle)
                ) {
                    Text("Casual & Friendly").tag("casual")
                    Text("Professional").tag("professional")
                    Text("Entertaining").tag("entertaining")
                }
                .pickerStyle(.segmented)
            }
            
            VStack(
                alignment: .leading,
                spacing: 10
            ) {
                Text("Podcast Length")
                    .font(.headline)
                
                Picker(
                    "Length",
                    selection: feature.binding(for: \.podcastLength)
                ) {
                    Text("Short (5-7 min)").tag("short")
                    Text("Medium (10-15 min)").tag("medium")
                    Text("Long (20-25 min)").tag("long")
                }
                .pickerStyle(.segmented)
            }
            
            Spacer()
            
            HStack {
                Button {
                    feature.send(.hideCustomization)
                } label: {
                    Text("Cancel")
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button {
                    feature.send(.hideCustomization)
                } label: {
                    Text("Done")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(
            width: 400,
            height: 300
        )
    }
}
