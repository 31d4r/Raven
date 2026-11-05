//
//  ImageGallery.swift
//  Raven
//
//  Sent images in the chat: a fanned pile of rounded cards with a count,
//  and a full-screen dark viewer with paging, zoom and a thumbnail strip.
//

import ImageIO
import SwiftUI

// MARK: - Loading

nonisolated private struct DecodedImage: @unchecked Sendable {
    let image: CGImage
}

private enum ImageDecoder {
    /// Downsamples off the main actor; orientation is applied.
    static func load(_ url: URL, maxPixelSize: CGFloat) async -> CGImage? {
        let decoded = await Task.detached(priority: .userInitiated) { () -> DecodedImage? in
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
            ]
            guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
            return DecodedImage(image: image)
        }.value
        return decoded?.image
    }
}

/// A local image file, decoded at the size it is shown.
struct LocalImage: View {
    let url: URL
    let maxPixelSize: CGFloat
    var contentMode: ContentMode = .fill

    @Environment(\.displayScale) private var displayScale
    @State private var image: CGImage?
    @State private var didFail = false

    var body: some View {
        ZStack {
            if let image {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                Rectangle()
                    .fill(DesignSystem.ConversationColors.assistantBubble)
                    .overlay {
                        if didFail {
                            Image(systemName: DesignSystem.Icons.imageFailed)
                                .foregroundStyle(DesignSystem.Colors.supporting)
                        } else {
                            ProgressView()
                        }
                    }
            }
        }
        .task(id: url) {
            image = await ImageDecoder.load(url, maxPixelSize: maxPixelSize * displayScale)
            didFail = image == nil
        }
    }
}

// MARK: - Pile in the chat

/// Up to three cards fanned behind the first image, with a “N images” caption.
struct ImageStack: View {
    let urls: [URL]
    let onOpen: (Int) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    @ScaledMetric(relativeTo: .body) private var cardWidth = DesignSystem.Conversation.imageCardWidth
    @ScaledMetric(relativeTo: .body) private var cardHeight = DesignSystem.Conversation.imageCardHeight

    private var visible: [URL] { Array(urls.prefix(DesignSystem.Conversation.imageStackLimit)) }

    private var caption: String {
        urls.count == 1 ? DesignSystem.Conversation.oneImage : DesignSystem.Conversation.images(urls.count)
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: DesignSystem.Spacing.small) {
            Button {
                onOpen(0)
            } label: {
                ZStack {
                    ForEach(Array(visible.enumerated().reversed()), id: \.offset) { index, url in
                        card(url)
                            .rotationEffect(.degrees(angle(for: index)))
                            .offset(x: -CGFloat(index) * DesignSystem.Conversation.imageFanOffset)
                    }
                }
                .padding(.leading, CGFloat(visible.count - 1) * DesignSystem.Conversation.imageFanOffset)
                .padding(.vertical, visible.count > 1 ? DesignSystem.Spacing.small : 0)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Label(caption, systemImage: DesignSystem.Icons.images)
                .font(.footnote.weight(.medium))
                .foregroundStyle(DesignSystem.Colors.supporting)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(caption)
        .accessibilityHint(DesignSystem.Conversation.openImagesHint)
        .accessibilityAddTraits([.isButton, .isImage])
        .accessibilityAction { onOpen(0) }
        .accessibilityIdentifier("sentImages")
    }

    private func angle(for index: Int) -> Double {
        guard visible.count > 1, index > 0 else { return 0 }
        let direction: Double = index.isMultiple(of: 2) ? 1 : -1
        return direction * DesignSystem.Conversation.imageFanAngle * Double((index + 1) / 2)
    }

    private func card(_ url: URL) -> some View {
        let shape = RoundedRectangle(cornerRadius: DesignSystem.Conversation.imageCardRadius, style: .continuous)
        return LocalImage(url: url, maxPixelSize: DesignSystem.Conversation.imageThumbnailPixels)
            .frame(width: cardWidth, height: cardHeight)
            .clipShape(shape)
            .overlay(shape.strokeBorder(contrast == .increased ? Color.primary : DesignSystem.ConversationColors.imageCardBorder, lineWidth: 1))
            .shadow(color: DesignSystem.ConversationColors.shadow, radius: 6, y: 2)
    }
}

// MARK: - Viewer

/// What the viewer shows; Identifiable so it can drive a cover or sheet.
struct ImageViewerContent: Identifiable {
    let id = UUID()
    let urls: [URL]
    let startIndex: Int
}

struct ImageViewer: View {
    let urls: [URL]
    @State private var selection: Int
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(content: ImageViewerContent) {
        urls = content.urls
        _selection = State(initialValue: min(max(content.startIndex, 0), max(content.urls.count - 1, 0)))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            pager
        }
        .overlay(alignment: .top) { topBar }
        .overlay(alignment: .bottom) {
            if urls.count > 1 { thumbnailStrip }
        }
        .environment(\.colorScheme, .dark)
        #if os(macOS)
        .frame(minWidth: 640, minHeight: 480)
        .onKeyPress(.leftArrow) { move(by: -1) }
        .onKeyPress(.rightArrow) { move(by: 1) }
        .onKeyPress(.escape) { dismiss(); return .handled }
        #endif
        .accessibilityIdentifier("imageViewer")
    }

    @ViewBuilder
    private var pager: some View {
        #if os(iOS)
        TabView(selection: $selection) {
            ForEach(urls.indices, id: \.self) { index in
                ZoomableImage(url: urls[index], label: DesignSystem.Conversation.imagePosition(index + 1, urls.count))
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
        #else
        if urls.indices.contains(selection) {
            ZoomableImage(url: urls[selection], label: DesignSystem.Conversation.imagePosition(selection + 1, urls.count))
                .id(selection)
                .overlay(alignment: .leading) { pageButton(-1) }
                .overlay(alignment: .trailing) { pageButton(1) }
        }
        #endif
    }

    #if os(macOS)
    @ViewBuilder
    private func pageButton(_ offset: Int) -> some View {
        let target = selection + offset
        if urls.indices.contains(target) {
            Button {
                _ = move(by: offset)
            } label: {
                FloatingIcon(systemImage: offset < 0 ? "chevron.left" : "chevron.right")
            }
            .buttonStyle(.plain)
            .padding(DesignSystem.Conversation.floatingBarPadding)
            .help(offset < 0 ? DesignSystem.Conversation.previousImage : DesignSystem.Conversation.nextImage)
            .accessibilityLabel(offset < 0 ? DesignSystem.Conversation.previousImage : DesignSystem.Conversation.nextImage)
        }
    }
    #endif

    private func move(by offset: Int) -> KeyPress.Result {
        let target = selection + offset
        guard urls.indices.contains(target) else { return .ignored }
        withAnimation(reduceMotion ? nil : .snappy(duration: 0.2)) { selection = target }
        return .handled
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                FloatingIcon(systemImage: DesignSystem.Icons.close)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)
            .help(DesignSystem.Conversation.close)
            .accessibilityLabel(DesignSystem.Conversation.close)
            .accessibilityInputLabels(DesignSystem.VoiceControl.dismiss)
            .accessibilityIdentifier("closeImageViewerButton")

            Spacer()

            if urls.indices.contains(selection) {
                Menu {
                    ShareLink(item: urls[selection]) {
                        Label(DesignSystem.Conversation.shareImage, systemImage: DesignSystem.Icons.share)
                    }
                } label: {
                    FloatingIcon(systemImage: DesignSystem.Icons.ellipsis)
                }
                .menuStyle(.button)
                .buttonStyle(.plain)
                .menuIndicator(.hidden)
                .fixedSize()
                .help(DesignSystem.Conversation.imageActions)
                .accessibilityLabel(DesignSystem.Conversation.imageActions)
                .accessibilityIdentifier("imageViewerMoreMenu")
            }
        }
        .padding(.horizontal, DesignSystem.Conversation.floatingBarPadding)
        .padding(.top, DesignSystem.Spacing.small)
    }

    private var thumbnailStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: DesignSystem.Spacing.small) {
                    ForEach(urls.indices, id: \.self) { index in
                        thumbnail(index)
                            .id(index)
                    }
                }
                .padding(.horizontal, DesignSystem.Conversation.floatingBarPadding)
                .padding(.vertical, DesignSystem.Spacing.small)
            }
            .scrollIndicators(.never)
            .defaultScrollAnchor(.center)
            .onChange(of: selection) { _, index in
                withAnimation(reduceMotion ? nil : .snappy) { proxy.scrollTo(index, anchor: .center) }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.bottom, DesignSystem.Spacing.small)
    }

    private func thumbnail(_ index: Int) -> some View {
        let isSelected = index == selection
        let shape = RoundedRectangle(cornerRadius: DesignSystem.Conversation.viewerThumbnailRadius, style: .continuous)
        return Button {
            withAnimation(reduceMotion ? nil : .snappy(duration: 0.2)) { selection = index }
        } label: {
            LocalImage(url: urls[index], maxPixelSize: DesignSystem.Conversation.viewerThumbnailSize * 2)
                .frame(width: DesignSystem.Conversation.viewerThumbnailSize, height: DesignSystem.Conversation.viewerThumbnailSize)
                .clipShape(shape)
                .overlay(shape.strokeBorder(isSelected ? Color.white : .clear, lineWidth: 2))
                .opacity(isSelected ? 1 : 0.6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(DesignSystem.Conversation.imagePosition(index + 1, urls.count))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// One image that pinches, double-taps and drags when zoomed.
private struct ZoomableImage: View {
    let url: URL
    let label: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        LocalImage(url: url, maxPixelSize: DesignSystem.Conversation.viewerImagePixels, contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scaleEffect(scale)
            .offset(offset)
            .contentShape(Rectangle())
            .gesture(magnify)
            .simultaneousGesture(pan, including: scale > 1 ? .all : .subviews)
            .onTapGesture(count: 2) { toggleZoom() }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityHint(DesignSystem.Conversation.zoomHint)
            .accessibilityAddTraits(.isImage)
            .accessibilityZoomAction { action in
                switch action.direction {
                case .zoomIn: setScale(scale + 1)
                case .zoomOut: setScale(scale - 1)
                @unknown default: break
                }
            }
    }

    private var magnify: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                scale = clamped(lastScale * value.magnification)
            }
            .onEnded { _ in
                if scale <= 1 { setScale(1) } else { lastScale = scale }
            }
    }

    private var pan: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in lastOffset = offset }
    }

    private func toggleZoom() {
        setScale(scale > 1 ? 1 : DesignSystem.Conversation.viewerDoubleTapZoom)
    }

    private func setScale(_ value: CGFloat) {
        withAnimation(reduceMotion ? nil : .snappy(duration: 0.25)) {
            scale = clamped(value)
            lastScale = scale
            if scale == 1 {
                offset = .zero
                lastOffset = .zero
            }
        }
    }

    private func clamped(_ value: CGFloat) -> CGFloat {
        min(max(value, 1), DesignSystem.Conversation.viewerMaxZoom)
    }
}
