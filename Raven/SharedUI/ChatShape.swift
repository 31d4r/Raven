//
//  ChatShape.swift
//  Raven
//
//  The soft shape avatars for chats. Every shape is the same number of
//  outline points, sampled by angle from the top and going clockwise, so
//  any shape can morph into any other point by point.
//

import SwiftUI

/// The shape of a chat's avatar. The raw value is what side storage saves.
nonisolated enum ChatShape: String, CaseIterable, Identifiable, Codable, Sendable {
    case circle, blob, roundedSquare, pill, triangle, hexagon, cloud
    case teardrop, rhombus, star, flower, heart, pentagon, scallop

    var id: String { rawValue }

    var name: String {
        switch self {
        case .circle: String(localized: "chatShape.circle", defaultValue: "Circle", comment: "Chat avatar shape name")
        case .blob: String(localized: "chatShape.blob", defaultValue: "Blob", comment: "Chat avatar shape name")
        case .roundedSquare: String(localized: "chatShape.roundedSquare", defaultValue: "Square", comment: "Chat avatar shape name")
        case .pill: String(localized: "chatShape.pill", defaultValue: "Pill", comment: "Chat avatar shape name")
        case .triangle: String(localized: "chatShape.triangle", defaultValue: "Triangle", comment: "Chat avatar shape name")
        case .hexagon: String(localized: "chatShape.hexagon", defaultValue: "Hexagon", comment: "Chat avatar shape name")
        case .cloud: String(localized: "chatShape.cloud", defaultValue: "Cloud", comment: "Chat avatar shape name")
        case .teardrop: String(localized: "chatShape.teardrop", defaultValue: "Drop", comment: "Chat avatar shape name")
        case .rhombus: String(localized: "chatShape.rhombus", defaultValue: "Diamond", comment: "Chat avatar shape name")
        case .star: String(localized: "chatShape.star", defaultValue: "Star", comment: "Chat avatar shape name")
        case .flower: String(localized: "chatShape.flower", defaultValue: "Flower", comment: "Chat avatar shape name")
        case .heart: String(localized: "chatShape.heart", defaultValue: "Heart", comment: "Chat avatar shape name")
        case .pentagon: String(localized: "chatShape.pentagon", defaultValue: "Pentagon", comment: "Chat avatar shape name")
        case .scallop: String(localized: "chatShape.scallop", defaultValue: "Scallop", comment: "Chat avatar shape name")
        }
    }

    /// Outline in unit space (−1…1, y down), fitted to the unit square.
    var outline: OutlinePoints {
        ChatShapeGeometry.outlines[self] ?? ChatShapeGeometry.outlines[.circle] ?? .zero
    }

    /// Chats saved before shapes stored an SF Symbol name; each maps to a shape.
    static func legacy(symbolName: String) -> ChatShape? {
        switch symbolName {
        case "bubble.left.fill": .circle
        case "book.closed.fill": .roundedSquare
        case "doc.text.fill": .pill
        case "folder.fill": .hexagon
        case "lightbulb.fill": .blob
        case "star.fill": .star
        case "heart.fill": .heart
        case "leaf.fill": .teardrop
        case "flame.fill": .triangle
        case "bolt.fill": .rhombus
        case "graduationcap.fill": .pentagon
        case "briefcase.fill": .cloud
        case "music.note": .scallop
        case "camera.fill": .flower
        default: nil
        }
    }
}

// MARK: - Animatable outline

/// A flat list of x, y pairs that SwiftUI can interpolate value by value.
nonisolated struct OutlinePoints: VectorArithmetic, Sendable {
    var values: [Double]

    static var zero: OutlinePoints { OutlinePoints(values: []) }

    static func + (lhs: OutlinePoints, rhs: OutlinePoints) -> OutlinePoints {
        combine(lhs, rhs, +)
    }

    static func - (lhs: OutlinePoints, rhs: OutlinePoints) -> OutlinePoints {
        combine(lhs, rhs, -)
    }

    mutating func scale(by rhs: Double) {
        for index in values.indices { values[index] *= rhs }
    }

    var magnitudeSquared: Double {
        values.reduce(0) { $0 + $1 * $1 }
    }

    /// `zero` is empty, so a missing side counts as all zeros.
    private static func combine(_ lhs: OutlinePoints, _ rhs: OutlinePoints, _ op: (Double, Double) -> Double) -> OutlinePoints {
        let count = max(lhs.values.count, rhs.values.count)
        var result = [Double](repeating: 0, count: count)
        for index in 0..<count {
            let left = index < lhs.values.count ? lhs.values[index] : 0
            let right = index < rhs.values.count ? rhs.values[index] : 0
            result[index] = op(left, right)
        }
        return OutlinePoints(values: result)
    }

    var pointCount: Int { values.count / 2 }

    func point(_ index: Int) -> CGPoint {
        CGPoint(x: values[index * 2], y: values[index * 2 + 1])
    }
}

/// The avatar body. Morphs when its points change inside an animation.
nonisolated struct ChatShapeOutline: Shape {
    var points: OutlinePoints

    var animatableData: OutlinePoints {
        get { points }
        set { points = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let count = points.pointCount
        guard count > 2 else { return Path(ellipseIn: rect) }
        let mapped = (0..<count).map { ChatShapeGeometry.map(points.point($0), into: rect) }
        var path = Path()
        // Quadratic curves through the midpoints keep the outline smooth.
        path.move(to: ChatShapeGeometry.mid(mapped[count - 1], mapped[0]))
        for index in 0..<count {
            let next = mapped[(index + 1) % count]
            path.addQuadCurve(to: ChatShapeGeometry.mid(mapped[index], next), control: mapped[index])
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Geometry

/// Builds each outline once: ray-cast the shape from its centre at evenly
/// spaced angles, soften the radii a little, then fit it to the unit square.
nonisolated enum ChatShapeGeometry {
    static let pointCount = 120

    static let outlines: [ChatShape: OutlinePoints] = Dictionary(
        uniqueKeysWithValues: ChatShape.allCases.map { ($0, makeOutline($0)) }
    )

    static func map(_ point: CGPoint, into rect: CGRect) -> CGPoint {
        let half = min(rect.width, rect.height) / 2
        return CGPoint(x: rect.midX + point.x * half, y: rect.midY + point.y * half)
    }

    static func mid(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
    }

    private static func makeOutline(_ shape: ChatShape) -> OutlinePoints {
        let (polylines, centre, softness) = parts(for: shape)
        var radii: [Double] = []
        radii.reserveCapacity(pointCount)
        for index in 0..<pointCount {
            let angle = -Double.pi / 2 + 2 * Double.pi * Double(index) / Double(pointCount)
            let direction = CGPoint(x: cos(angle), y: sin(angle))
            let hit = polylines.compactMap { farthestHit(from: centre, direction: direction, polyline: $0) }.max()
            radii.append(hit ?? radii.last ?? 1)
        }
        if softness > 0 { radii = smooth(radii, sigma: softness) }

        var points: [CGPoint] = []
        for (index, radius) in radii.enumerated() {
            let angle = -Double.pi / 2 + 2 * Double.pi * Double(index) / Double(pointCount)
            points.append(CGPoint(x: centre.x + radius * cos(angle), y: centre.y + radius * sin(angle)))
        }
        let minX = points.map(\.x).min() ?? -1, maxX = points.map(\.x).max() ?? 1
        let minY = points.map(\.y).min() ?? -1, maxY = points.map(\.y).max() ?? 1
        let scale = 2 / max(maxX - minX, maxY - minY, .ulpOfOne)
        let midX = (minX + maxX) / 2, midY = (minY + maxY) / 2
        var values: [Double] = []
        values.reserveCapacity(pointCount * 2)
        for point in points {
            values.append((point.x - midX) * scale)
            values.append((point.y - midY) * scale)
        }
        return OutlinePoints(values: values)
    }

    /// The polylines making up a shape (unioned), the centre to cast from,
    /// and how much to soften the radii (in samples).
    private static func parts(for shape: ChatShape) -> ([[CGPoint]], CGPoint, Double) {
        let origin = CGPoint.zero
        switch shape {
        case .circle:
            return ([circle(origin, 1)], origin, 0)
        case .blob:
            return ([radial { 1 + 0.07 * sin(2 * $0 + 0.6) + 0.06 * cos(3 * $0 - 0.4) }], origin, 1)
        case .roundedSquare:
            return ([roundedPolygon([CGPoint(x: -1, y: -1), CGPoint(x: 1, y: -1), CGPoint(x: 1, y: 1), CGPoint(x: -1, y: 1)], radius: 0.5)], origin, 0.8)
        case .pill:
            return ([roundedPolygon([CGPoint(x: -1, y: -0.58), CGPoint(x: 1, y: -0.58), CGPoint(x: 1, y: 0.58), CGPoint(x: -1, y: 0.58)], radius: 0.58)], origin, 0.8)
        case .triangle:
            return ([roundedPolygon(regular(3), radius: 0.3)], CGPoint(x: 0, y: 0.05), 0.8)
        case .hexagon:
            return ([roundedPolygon(regular(6), radius: 0.24)], origin, 0.8)
        case .pentagon:
            return ([roundedPolygon(regular(5), radius: 0.26)], origin, 0.8)
        case .rhombus:
            return ([roundedPolygon([CGPoint(x: 0, y: -1), CGPoint(x: 0.8, y: 0), CGPoint(x: 0, y: 1), CGPoint(x: -0.8, y: 0)], radius: 0.24)], origin, 0.8)
        case .star:
            let tips = (0..<8).map { index -> CGPoint in
                let angle = -Double.pi / 2 + Double(index) * Double.pi / 4
                let radius = index.isMultiple(of: 2) ? 1.0 : 0.46
                return CGPoint(x: radius * cos(angle), y: radius * sin(angle))
            }
            return ([roundedPolygon(tips, radius: 0.16)], origin, 1)
        case .flower:
            let petals = (0..<4).map { index -> [CGPoint] in
                let angle = -Double.pi / 2 + Double(index) * Double.pi / 2
                return circle(CGPoint(x: 0.47 * cos(angle), y: 0.47 * sin(angle)), 0.53)
            }
            return (petals, origin, 2)
        case .heart:
            let outline = (0..<360).map { step -> CGPoint in
                let t = Double(step) / 360 * 2 * Double.pi
                let x = 16 * pow(sin(t), 3)
                let y = -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t))
                return CGPoint(x: x / 17, y: y / 17)
            }
            return ([outline], CGPoint(x: 0, y: -0.05), 2)
        case .scallop:
            return ([radial { 0.88 + 0.12 * abs(cos(5 * $0)) }], origin, 1.6)
        case .cloud:
            let base = roundedPolygon([CGPoint(x: -0.95, y: 0.02), CGPoint(x: 0.95, y: 0.02), CGPoint(x: 0.95, y: 0.56), CGPoint(x: -0.95, y: 0.56)], radius: 0.27)
            return ([
                circle(CGPoint(x: -0.48, y: 0.1), 0.42),
                circle(CGPoint(x: 0.04, y: -0.18), 0.56),
                circle(CGPoint(x: 0.52, y: 0.1), 0.42),
                base
            ], CGPoint(x: 0, y: 0.12), 1.6)
        case .teardrop:
            let bulb = circle(CGPoint(x: 0, y: 0.3), 0.7)
            let tip = roundedPolygon([CGPoint(x: 0, y: -1), CGPoint(x: 0.59, y: -0.077), CGPoint(x: -0.59, y: -0.077)], radius: 0.14)
            return ([bulb, tip], CGPoint(x: 0, y: 0.2), 1.2)
        }
    }

    // MARK: Primitives

    private static func circle(_ centre: CGPoint, _ radius: Double, steps: Int = 180) -> [CGPoint] {
        (0..<steps).map { step in
            let angle = 2 * Double.pi * Double(step) / Double(steps)
            return CGPoint(x: centre.x + radius * cos(angle), y: centre.y + radius * sin(angle))
        }
    }

    private static func radial(steps: Int = 360, _ radius: (Double) -> Double) -> [CGPoint] {
        (0..<steps).map { step in
            let angle = 2 * Double.pi * Double(step) / Double(steps)
            let length = radius(angle)
            return CGPoint(x: length * cos(angle), y: length * sin(angle))
        }
    }

    /// A regular polygon with its first vertex at the top.
    private static func regular(_ sides: Int) -> [CGPoint] {
        (0..<sides).map { index in
            let angle = -Double.pi / 2 + 2 * Double.pi * Double(index) / Double(sides)
            return CGPoint(x: cos(angle), y: sin(angle))
        }
    }

    /// A closed polygon with every corner, convex or concave, filleted.
    private static func roundedPolygon(_ vertices: [CGPoint], radius: Double, arcSteps: Int = 10) -> [CGPoint] {
        var result: [CGPoint] = []
        let count = vertices.count
        for index in 0..<count {
            let vertex = vertices[index]
            let previous = vertices[(index + count - 1) % count]
            let next = vertices[(index + 1) % count]
            let toPrevious = unit(previous - vertex), toNext = unit(next - vertex)
            let cosine = max(-1, min(1, toPrevious.x * toNext.x + toPrevious.y * toNext.y))
            let angle = acos(cosine)
            guard angle > 0.01, angle < Double.pi - 0.01 else {
                result.append(vertex)
                continue
            }
            let limit = min(length(previous - vertex), length(next - vertex)) / 2
            var tangent = radius / tan(angle / 2)
            var fillet = radius
            if tangent > limit {
                tangent = limit
                fillet = limit * tan(angle / 2)
            }
            let start = vertex + toPrevious * tangent
            let end = vertex + toNext * tangent
            let bisector = unit(toPrevious + toNext)
            let centre = vertex + bisector * (fillet / sin(angle / 2))
            let startAngle = atan2(start.y - centre.y, start.x - centre.x)
            let endAngle = atan2(end.y - centre.y, end.x - centre.x)
            // Sweep the short way round the fillet.
            var sweep = endAngle - startAngle
            while sweep > Double.pi { sweep -= 2 * Double.pi }
            while sweep < -Double.pi { sweep += 2 * Double.pi }
            for step in 0...arcSteps {
                let t = startAngle + sweep * Double(step) / Double(arcSteps)
                result.append(CGPoint(x: centre.x + fillet * cos(t), y: centre.y + fillet * sin(t)))
            }
        }
        return result
    }

    // MARK: Ray casting and smoothing

    /// Distance to the farthest crossing of a ray with a closed polyline.
    private static func farthestHit(from origin: CGPoint, direction: CGPoint, polyline: [CGPoint]) -> Double? {
        var best: Double?
        let count = polyline.count
        for index in 0..<count {
            let a = polyline[index], b = polyline[(index + 1) % count]
            let edge = b - a
            let denominator = direction.x * edge.y - direction.y * edge.x
            guard abs(denominator) > 1e-12 else { continue }
            let offset = a - origin
            let t = (offset.x * edge.y - offset.y * edge.x) / denominator
            let u = (offset.x * direction.y - offset.y * direction.x) / denominator
            if t > 0, u >= 0, u <= 1 {
                best = max(best ?? t, t)
            }
        }
        return best
    }

    /// Circular Gaussian blur of the radii, which rounds cusps and tips.
    private static func smooth(_ values: [Double], sigma: Double) -> [Double] {
        let reach = Int((sigma * 3).rounded(.up))
        let weights = (-reach...reach).map { exp(-Double($0 * $0) / (2 * sigma * sigma)) }
        let total = weights.reduce(0, +)
        let count = values.count
        return (0..<count).map { index in
            var sum = 0.0
            for (offset, weight) in zip(-reach...reach, weights) {
                sum += values[(index + offset + count) % count] * weight
            }
            return sum / total
        }
    }

    private static func unit(_ point: CGPoint) -> CGPoint {
        let size = length(point)
        return size > 0 ? CGPoint(x: point.x / size, y: point.y / size) : .zero
    }

    private static func length(_ point: CGPoint) -> Double {
        (point.x * point.x + point.y * point.y).squareRoot()
    }
}

nonisolated private func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint { CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y) }
nonisolated private func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint { CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y) }
nonisolated private func * (lhs: CGPoint, rhs: Double) -> CGPoint { CGPoint(x: lhs.x * rhs, y: lhs.y * rhs) }
