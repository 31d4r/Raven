//
//  SwiftUIExtensions.swift
//  Parrot
//
//  Created by Eldar Tutnjic on 24.07.25.
//

import SwiftUI

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: RectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = Path { p in
            let r = min(radius, min(rect.width, rect.height) / 2)
            p.addRoundedRect(in: rect, cornerSize: CGSize(width: r, height: r))
        }
        return path
    }
}

struct RectCorner: OptionSet {
    let rawValue: Int
    static let topLeft = RectCorner(rawValue: 1)
    static let topRight = RectCorner(rawValue: 2)
    static let bottomLeft = RectCorner(rawValue: 4)
    static let bottomRight = RectCorner(rawValue: 8)
    static let allCorners: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: RectCorner) -> some View {
        clipShape(RoundedRectangle(cornerRadius: radius))
    }
}
