//
//  MessageTimeGutter.swift
//  Raven
//
//  Messages-style message times: swiping the transcript left (two fingers on a
//  Mac trackpad, one finger on iPhone and iPad) pulls the bubbles aside and
//  shows each message's time in a trailing gutter. On Mac the times hide a
//  second after release; on iPhone and iPad they spring back at once. Show Message Times (Mac View menu, iOS ⋯ menu) keeps them
//  visible, and VoiceOver reads each time in the message label.
//

import SwiftUI

/// What a message row needs to draw its time: the live swipe and the menu pin.
struct MessageTimeGutterState {
    let reveal: MessageTimeReveal
    let isPinned: Bool
}

extension View {
    /// Adds the swipe-to-reveal time gutter to a transcript row.
    func messageTimeGutter(_ date: Date, reveal state: MessageTimeGutterState) -> some View {
        modifier(MessageTimeGutter(date: date, reveal: state.reveal, isPinned: state.isPinned))
    }
}

// MARK: - Reveal state

/// How far the transcript is pulled left, plus the delayed hide after release.
@MainActor
@Observable
final class MessageTimeReveal {
    /// Points the rows slide left. Follows the fingers, rubber-banded past the gutter.
    private(set) var offset: CGFloat = 0
    /// Times are visible (drives the fade when Reduce Motion is on).
    private(set) var isRevealed = false

    @ObservationIgnored private var travel: CGFloat = 0
    @ObservationIgnored private var hideTask: Task<Void, Never>?

    private var gutter: CGFloat { DesignSystem.Conversation.timeGutterWidth }

    /// 0 when hidden, 1 when the gutter is fully open.
    var progress: CGFloat { min(max(offset / gutter, 0), 1) }

    /// The gutter is fully open (or, with Reduce Motion, the times are shown).
    func isFullyOpen(reduceMotion: Bool) -> Bool {
        reduceMotion ? isRevealed : offset >= gutter
    }

    /// Fingers touched the trackpad: keep the times up while they stay down.
    func touchDown() {
        cancelHide()
    }

    /// `delta` is leftward finger travel in points; rightward travel is negative.
    func drag(by delta: CGFloat, reduceMotion: Bool) {
        cancelHide()
        travel = min(max(travel + delta, 0), gutter * 3)
        if reduceMotion {
            let shouldReveal = travel > DesignSystem.Conversation.timeRevealFadeThreshold
            if shouldReveal != isRevealed {
                isRevealed = shouldReveal
            }
        } else {
            offset = Self.rubberBand(travel, limit: gutter)
            isRevealed = offset > 0
        }
    }

    /// Fingers lifted: on Mac, settle any overshoot and hide after a short
    /// pause; on iPhone and iPad, spring back right away.
    func release(reduceMotion: Bool) {
        cancelHide()
        guard isRevealed || offset > 0 else {
            travel = 0
            return
        }
        guard DesignSystem.Conversation.timeHideDelay > .zero else {
            hide(reduceMotion: reduceMotion)
            return
        }
        if !reduceMotion, offset > gutter {
            travel = gutter
            withAnimation(DesignSystem.Conversation.timeRevealSpring) {
                offset = gutter
            }
        }
        hideTask = Task { [weak self] in
            try? await Task.sleep(for: DesignSystem.Conversation.timeHideDelay)
            guard !Task.isCancelled else { return }
            self?.hide(reduceMotion: reduceMotion)
        }
    }

    private func hide(reduceMotion: Bool) {
        travel = 0
        hideTask = nil
        if reduceMotion {
            offset = 0
            isRevealed = false
        } else {
            withAnimation(DesignSystem.Conversation.timeRevealSpring) {
                offset = 0
                isRevealed = false
            }
        }
    }

    private func cancelHide() {
        hideTask?.cancel()
        hideTask = nil
    }

    /// Linear up to `limit`, then resists and never passes `limit` plus the overshoot.
    static func rubberBand(_ value: CGFloat, limit: CGFloat) -> CGFloat {
        guard value > limit else { return value }
        let maxOvershoot = limit * DesignSystem.Conversation.timeRevealOvershoot
        let over = value - limit
        return limit + maxOvershoot * (1 - 1 / (over / maxOvershoot + 1))
    }
}

// MARK: - Row gutter

private struct MessageTimeGutter: ViewModifier {
    let date: Date
    let reveal: MessageTimeReveal
    let isPinned: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let gutter = DesignSystem.Conversation.timeGutterWidth
        // Pinned, or Reduce Motion: the row makes room and the time only fades.
        let reservesGutter = isPinned || (reduceMotion && reveal.isRevealed)
        let slide = reservesGutter || reduceMotion ? 0 : reveal.offset
        let opacity: Double = if isPinned {
            1
        } else if reduceMotion {
            reveal.isRevealed ? 1 : 0
        } else {
            Double(reveal.progress)
        }

        content
            .padding(.trailing, reservesGutter ? gutter : 0)
            .animation(reduceMotion ? nil : DesignSystem.Conversation.timeRevealSpring, value: isPinned)
            .overlay(alignment: .trailing) {
                Text(DesignSystem.Conversation.messageTime(date))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(DesignSystem.Colors.supporting)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
                    .frame(width: gutter, alignment: .trailing)
                    .offset(x: reservesGutter ? 0 : gutter)
                    .opacity(opacity)
                    .animation(reduceMotion ? DesignSystem.Conversation.timeFade : nil, value: reveal.isRevealed)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .offset(x: -slide)
    }
}

// MARK: - Mac trackpad swipe

#if os(macOS)
import AppKit

/// Watches two-finger trackpad scrolls over the transcript. A mostly horizontal
/// swipe drives the time gutter and is kept from the scroll view; anything
/// else, including mouse wheels, passes through untouched.
struct HorizontalSwipeMonitor: NSViewRepresentable {
    var isEnabled: Bool
    let onTouch: () -> Void
    let onDrag: (CGFloat) -> Void
    let onRelease: () -> Void

    func makeNSView(context: Context) -> SwipeMonitorView {
        let view = SwipeMonitorView()
        update(view)
        return view
    }

    func updateNSView(_ view: SwipeMonitorView, context: Context) {
        update(view)
    }

    static func dismantleNSView(_ view: SwipeMonitorView, coordinator: ()) {
        view.stopMonitoring()
    }

    private func update(_ view: SwipeMonitorView) {
        view.isEnabled = isEnabled
        view.onTouch = onTouch
        view.onDrag = onDrag
        view.onRelease = onRelease
    }
}

final class SwipeMonitorView: NSView {
    var isEnabled = true
    var onTouch: () -> Void = {}
    var onDrag: (CGFloat) -> Void = { _ in }
    var onRelease: () -> Void = {}

    private enum Axis {
        case undecided, horizontal, vertical
    }

    private var monitor: Any?
    private var axis: Axis = .undecided
    private var pending = CGSize.zero
    private var swallowsMomentum = false

    /// Clicks, hovers and drags go to the transcript underneath.
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil {
            stopMonitoring()
        } else {
            startMonitoring()
        }
    }

    func stopMonitoring() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
        axis = .undecided
        swallowsMomentum = false
    }

    private func startMonitoring() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            guard let self else { return event }
            return self.handle(event)
        }
    }

    /// Returns `nil` for events the swipe consumes.
    private func handle(_ event: NSEvent) -> NSEvent? {
        guard let window, event.window === window, !isHiddenOrHasHiddenAncestor else { return event }

        // Momentum after a horizontal swipe belongs to the swipe, not the scroll view.
        if !event.momentumPhase.isEmpty {
            guard swallowsMomentum else { return event }
            if event.momentumPhase.contains(.ended) || event.momentumPhase.contains(.cancelled) {
                swallowsMomentum = false
            }
            return nil
        }

        let phase = event.phase
        guard !phase.isEmpty, event.hasPreciseScrollingDeltas else { return event }

        if phase.contains(.mayBegin) {
            if isEnabled, isInside(event) { onTouch() }
            return event
        }

        if phase.contains(.began) {
            swallowsMomentum = false
            pending = .zero
            axis = isEnabled && isInside(event) ? .undecided : .vertical
            if axis == .undecided { onTouch() }
        }

        if phase.contains(.ended) || phase.contains(.cancelled) {
            let wasHorizontal = axis == .horizontal
            axis = .undecided
            pending = .zero
            onRelease()
            if wasHorizontal {
                swallowsMomentum = true
                return nil
            }
            return event
        }

        guard phase.contains(.began) || phase.contains(.changed) else { return event }
        let leftward = leftwardTravel(event)

        switch axis {
        case .vertical:
            return event
        case .horizontal:
            onDrag(leftward)
            return nil
        case .undecided:
            pending.width += leftward
            pending.height += event.scrollingDeltaY
            let width = abs(pending.width)
            let height = abs(pending.height)
            guard max(width, height) >= DesignSystem.Conversation.swipeDecisionDistance else { return event }
            if width > height * DesignSystem.Conversation.swipeHorizontalDominance {
                axis = .horizontal
                onDrag(pending.width)
                return nil
            }
            axis = .vertical
            return event
        }
    }

    private func isInside(_ event: NSEvent) -> Bool {
        bounds.contains(convert(event.locationInWindow, from: nil))
    }

    /// Finger travel to the left, whatever the natural scrolling setting.
    private func leftwardTravel(_ event: NSEvent) -> CGFloat {
        event.isDirectionInvertedFromDevice ? -event.scrollingDeltaX : event.scrollingDeltaX
    }
}
#endif

// MARK: - iOS one-finger pan

#if os(iOS)
import UIKit

/// A UIKit pan bridged into SwiftUI. It only begins for a mostly horizontal,
/// leftward drag that doesn't start at the leading edge, and it runs alongside
/// the scroll view's own pan, so vertical scrolling, swipe-back, long-press
/// menus and taps keep their recognizers.
struct MessageTimePan: UIGestureRecognizerRepresentable {
    var isEnabled: Bool
    let onDrag: (CGFloat) -> Void
    let onRelease: () -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer()
        pan.maximumNumberOfTouches = 1
        pan.delegate = context.coordinator
        pan.isEnabled = isEnabled
        return pan
    }

    func updateUIGestureRecognizer(_ recognizer: UIPanGestureRecognizer, context: Context) {
        recognizer.isEnabled = isEnabled
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        let coordinator = context.coordinator
        switch recognizer.state {
        case .began, .changed:
            if recognizer.state == .began { coordinator.lastX = 0 }
            let x = recognizer.translation(in: recognizer.view).x
            onDrag(coordinator.lastX - x)
            coordinator.lastX = x
        case .ended, .cancelled, .failed:
            coordinator.lastX = 0
            onRelease()
        default:
            break
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var lastX: CGFloat = 0

        /// Leave touches at the leading edge to the navigation swipe-back.
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            guard let window = touch.window else { return true }
            let x = touch.location(in: window).x
            let edge = DesignSystem.Conversation.swipeLeadingEdgeExclusion
            if window.effectiveUserInterfaceLayoutDirection == .rightToLeft {
                return x < window.bounds.width - edge
            }
            return x > edge
        }

        /// Claim only leftward drags that are clearly wider than tall.
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
            var motion = pan.translation(in: pan.view)
            if motion == .zero {
                motion = pan.velocity(in: pan.view)
            }
            return motion.x < 0
                && abs(motion.x) > abs(motion.y) * DesignSystem.Conversation.swipeHorizontalDominance
        }

        /// Never block the scroll view, context menus, or anything else.
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}
#endif
