//
//  DesignSystem+Conversation.swift
//  Raven
//
//  Tokens and strings for the chat-app look: sidebar rows with avatars,
//  message bubbles, the composer, the ⌘K switcher and the New Chat card.
//

import SwiftUI

extension DesignSystem {
    enum Conversation {
        // Avatars
        static let sidebarAvatarSize: CGFloat = 36
        static let titleAvatarSize: CGFloat = 20
        static let paletteAvatarSize: CGFloat = 28

        // Sidebar
        static let sidebarRowRadius: CGFloat = 10
        static let sidebarRowSpacing: CGFloat = 2
        static let sidebarRowHorizontalPadding: CGFloat = 8
        static let sidebarRowVerticalPadding: CGFloat = 7
        static let sidebarAvatarToText: CGFloat = 10

        // Bubbles
        static let bubbleRadius: CGFloat = 18
        static let bubbleHorizontalPadding: CGFloat = 14
        static let bubbleVerticalPadding: CGFloat = 9
        static let bubbleMaxWidth: CGFloat = 580
        static let userBubbleLeadingInset: CGFloat = 80
        static let assistantTrailingInset: CGFloat = 40
        static let messageSpacing: CGFloat = 10
        static let codeBlockRadius: CGFloat = 10
        static let codeBlockPadding: CGFloat = 12
        static let hoverBarSpacing: CGFloat = 2
        static let hoverButtonSize: CGFloat = 26
        /// A new timestamp separator starts after this much silence.
        static let timestampGap: TimeInterval = 15 * 60

        // Message times (macOS two-finger swipe left, like Messages)
        /// Width of the right-hand gutter that holds each message’s time.
        static let timeGutterWidth: CGFloat = 72
        /// How far past the gutter the transcript can be pulled, as a share of its width.
        static let timeRevealOvershoot: CGFloat = 0.25
        /// Swipe travel before the times fade in when Reduce Motion is on.
        static let timeRevealFadeThreshold: CGFloat = 24
        /// Finger travel before a scroll gesture is judged horizontal or vertical.
        static let swipeDecisionDistance: CGFloat = 6
        /// A swipe counts as horizontal only when it is this many times wider than tall.
        static let swipeHorizontalDominance: CGFloat = 1.5
        /// iOS: drags starting this close to the leading edge are left to swipe-back.
        static let swipeLeadingEdgeExclusion: CGFloat = 24
        /// Times stay visible this long after the fingers lift (Mac only;
        /// on iPhone and iPad they hide as soon as the finger lifts).
        #if os(macOS)
        static let timeHideDelay: Duration = .seconds(1)
        #else
        static let timeHideDelay: Duration = .zero
        #endif
        static let timeRevealSpring = Animation.spring(duration: 0.4, bounce: 0.18)
        static let timeFade = Animation.easeInOut(duration: 0.2)

        // Thinking indicator
        static let dotSize: CGFloat = 7
        static let dotSpacing: CGFloat = 4
        static let dotCycle: TimeInterval = 1.2

        // Composer
        static let composerRadius: CGFloat = 20
        static let composerButtonSize: CGFloat = 28
        static let composerInnerPadding: CGFloat = 6
        static let composerOuterPadding: CGFloat = 16
        static let attachmentSize: CGFloat = 56
        static let attachmentRadius: CGFloat = 10

        // ⌘K switcher
        static let paletteWidth: CGFloat = 460
        static let paletteListMaxHeight: CGFloat = 340
        static let paletteRadius: CGFloat = 16
        static let paletteTopInset: CGFloat = 64
        static let paletteRowRadius: CGFloat = 8

        // New Chat card
        static let newChatCardWidth: CGFloat = 440
        static let shapeColumns = 7
        /// Inset of a shape inside its option, as a fraction of the option.
        static let shapeOptionInset: CGFloat = 0.17
        static let colorSwatchSize: CGFloat = 32
        static let createButtonPadding: CGFloat = 14
        /// The New Chat preview springs into a newly picked shape.
        static let shapeMorph = Animation.spring(response: 0.5, dampingFraction: 0.58)

        // iOS chat list
        static let listAvatarSize: CGFloat = 52
        static let listRowVerticalPadding: CGFloat = 8
        static let listAvatarToText: CGFloat = 12
        static let floatingButtonSize: CGFloat = 44
        static let floatingBarPadding: CGFloat = 16
        static let headerFadeHeight: CGFloat = 24

        // iOS New Chat card
        static let newChatAvatarSize: CGFloat = 104
        static let newChatFieldRadius: CGFloat = 16
        static let newChatSheetRadius: CGFloat = 32

        // Sent images
        static let imageCardWidth: CGFloat = 190
        static let imageCardHeight: CGFloat = 150
        static let imageCardRadius: CGFloat = 18
        static let imageStackLimit = 3
        static let imageFanAngle: Double = 7
        static let imageFanOffset: CGFloat = 14
        static let imageThumbnailPixels: CGFloat = 480
        static let viewerImagePixels: CGFloat = 2800
        static let viewerThumbnailSize: CGFloat = 46
        static let viewerThumbnailRadius: CGFloat = 8
        static let viewerMaxZoom: CGFloat = 4
        static let viewerDoubleTapZoom: CGFloat = 2.5

        // Find in chat
        static let findMatchRing: CGFloat = 2
    }

    enum ConversationColors {
        static let assistantBubble = Color.primary.opacity(0.06)
        static let selectedRow = Color.primary.opacity(0.09)
        static let hoveredRow = Color.primary.opacity(0.045)
        static let inlineCode = Color.primary.opacity(0.08)
        static let paletteDim = Color.black.opacity(0.18)
        static let composerBorder = Color.primary.opacity(0.1)
        static let shadow = Color.black.opacity(0.12)
        static let findMatch = Color.yellow.opacity(0.45)
        static let findCurrentMatch = Color.orange.opacity(0.8)
        static let imageCardBorder = Color.primary.opacity(0.12)
        #if canImport(UIKit)
        /// Opaque stand-in for glass when Reduce Transparency is on.
        static let solidSurface = Color(uiColor: .secondarySystemBackground)
        static let listBackground = Color(uiColor: .systemBackground)
        #else
        static let solidSurface = Color(nsColor: .controlBackgroundColor)
        static let listBackground = Color(nsColor: .windowBackgroundColor)
        #endif
    }
}

// MARK: - Icons and shortcuts

extension DesignSystem.Icons {
    static let search = "magnifyingglass"
    static let attach = "paperclip"
    static let stop = "stop.fill"
    static let share = "square.and.arrow.up"
    static let removeAttachment = "xmark.circle.fill"
    static let close = "xmark"
    static let ellipsis = "ellipsis"
    static let back = "chevron.left"
    static let images = "square.on.square"
    static let photoLibrary = "photo.on.rectangle"
    static let camera = "camera"
    static let chooseFile = "folder"
    static let findPrevious = "chevron.up"
    static let findNext = "chevron.down"
    static let imageFailed = "photo"
}

extension DesignSystem.Shortcuts {
    static let searchChats = DesignSystem.Shortcut(key: "k", modifiers: .command, display: "⌘K")

    /// ⌘1…⌘9 open the first nine chats in the sidebar.
    static func chat(at index: Int) -> DesignSystem.Shortcut? {
        guard (0..<9).contains(index), let digit = String(index + 1).first else { return nil }
        return DesignSystem.Shortcut(key: KeyEquivalent(digit), modifiers: .command, display: "⌘\(index + 1)")
    }

    static let chatRange = "⌘1 – ⌘9"
}

// MARK: - Strings

extension DesignSystem.Conversation {
    /// Time in the message gutter: “2:18 PM” today, “Nov 3, 2:18 PM” on other days.
    static func messageTime(_ date: Date) -> String {
        Calendar.current.isDateInToday(date)
            ? date.formatted(.dateTime.hour().minute())
            : date.formatted(.dateTime.month(.abbreviated).day().hour().minute())
    }

    /// The same time for VoiceOver, with the full month on other days.
    static func spokenMessageTime(_ date: Date) -> String {
        Calendar.current.isDateInToday(date)
            ? date.formatted(.dateTime.hour().minute())
            : date.formatted(.dateTime.month(.wide).day().hour().minute())
    }

    static func messageLabel(_ speaker: String, _ time: String) -> String {
        String(localized: "conversation.message.a11y.time", defaultValue: "\(speaker), \(time)", comment: "VoiceOver label of a message on Mac. First placeholder is who wrote it (You asked / Raven answered), second the time it was sent or received")
    }

    static func sentImagesTime(_ time: String) -> String {
        String(localized: "conversation.images.a11y.time", defaultValue: "Sent \(time)", comment: "VoiceOver value of a sent image stack on Mac; the time it was sent")
    }

    static var thinking: String {
        String(localized: "conversation.thinking", defaultValue: "Thinking…", comment: "Shown under the last message while Raven writes an answer")
    }

    static var thinkingAccessibility: String {
        String(localized: "conversation.thinking.a11y", defaultValue: "Raven is thinking", comment: "VoiceOver label of the thinking indicator")
    }

    static func today(_ time: String) -> String {
        String(localized: "conversation.timestamp.today", defaultValue: "Today \(time)", comment: "Separator above messages sent today. Placeholder is the time, e.g. Today 1:55 PM")
    }

    static func yesterday(_ time: String) -> String {
        String(localized: "conversation.timestamp.yesterday", defaultValue: "Yesterday \(time)", comment: "Separator above messages sent yesterday. Placeholder is the time")
    }

    static func otherDay(_ date: String, _ time: String) -> String {
        String(localized: "conversation.timestamp.other", defaultValue: "\(date) \(time)", comment: "Separator above older messages. First placeholder is the date, second the time")
    }

    static var noPreview: String {
        String(localized: "conversation.preview.empty", defaultValue: "No messages yet", comment: "Sidebar preview line of a chat without messages")
    }

    static var addMenu: String {
        String(localized: "conversation.add", defaultValue: "Add Attachments", comment: "Accessibility label of the + menu in the composer")
    }

    static var addMenuDetail: String {
        String(localized: "conversation.add.detail", defaultValue: "Attach files or photos. They’re added to this chat’s sources when you send.", comment: "Tooltip and hint of the + menu in the composer")
    }

    static var attachFiles: String {
        DesignSystem.dialogCommand(
            String(localized: "conversation.attachFiles", defaultValue: "Attach Files…", comment: "Composer menu item that opens the file panel"),
            plain: attachFilesLabel
        )
    }

    static var attachFilesLabel: String {
        String(localized: "conversation.attachFiles.label", defaultValue: "Attach Files", comment: "VoiceOver name of Attach Files (no ellipsis)")
    }

    static var attachConfirm: String {
        String(localized: "conversation.attachFiles.confirm", defaultValue: "Attach", comment: "Confirm button of the file panel opened from the composer")
    }

    static func attachmentLabel(_ name: String) -> String {
        String(localized: "conversation.attachment.a11y", defaultValue: "Attachment: \(name)", comment: "VoiceOver label of a pending attachment. Placeholder is the file name")
    }

    static var removeAttachment: String {
        String(localized: "conversation.attachment.remove", defaultValue: "Remove Attachment", comment: "Button and VoiceOver action that removes a pending attachment")
    }

    static var attachmentsReady: String {
        String(localized: "conversation.attachments.ready", defaultValue: "Send to add these files to the chat’s sources.", comment: "Tooltip of Send when only attachments are waiting")
    }

    static var preparingPhotos: String {
        String(localized: "conversation.photos.preparing", defaultValue: "Preparing photos…", comment: "Shown in the composer while chosen photos are loaded")
    }

    static var preparingPhotosLabel: String {
        String(localized: "conversation.photos.preparing.a11y", defaultValue: "Preparing photos", comment: "VoiceOver label of the composer spinner while chosen photos load (no ellipsis)")
    }

    static var stop: String {
        String(localized: "conversation.stop", defaultValue: "Stop Answering", comment: "Composer button that stops the answer being written")
    }

    static var share: String {
        DesignSystem.dialogCommand(
            String(localized: "conversation.share", defaultValue: "Share…", comment: "Message action that shares the answer"),
            plain: shareLabel
        )
    }

    static var shareLabel: String {
        String(localized: "conversation.share.label", defaultValue: "Share", comment: "iOS title and VoiceOver name of the message Share action (no ellipsis)")
    }

    static var messageActions: String {
        String(localized: "conversation.messageActions", defaultValue: "More Actions", comment: "Menu with more actions for one answer")
    }

    // ⌘K switcher
    static var searchChats: String {
        String(localized: "conversation.search", defaultValue: "Search Chats", comment: "Title of the chat switcher and its toolbar button")
    }

    static var searchChatsEllipsis: String {
        DesignSystem.dialogCommand(
            String(localized: "conversation.search.menu", defaultValue: "Search Chats…", comment: "Menu item that opens the chat switcher"),
            plain: searchChats
        )
    }

    static var searchPrompt: String {
        String(localized: "conversation.search.prompt", defaultValue: "Search chats", comment: "Placeholder of the chat switcher search field")
    }

    static var searchHint: String {
        String(localized: "conversation.search.hint", defaultValue: "Type to filter. Use the arrow keys to choose, Return to open and Escape to close.", comment: "Accessibility hint and tooltip of the chat switcher")
    }

    static var noResults: String {
        String(localized: "conversation.search.empty", defaultValue: "No Chats Found", comment: "Chat switcher title when nothing matches")
    }

    static var goToChat: String {
        String(localized: "conversation.goTo", defaultValue: "Go to Chat", comment: "Menu section listing the first nine chats with ⌘1–⌘9")
    }

    // New Chat card
    static var createTitle: String {
        String(localized: "conversation.create.title", defaultValue: "Create New Chat", comment: "Title of the New Chat card")
    }

    static var namePrompt: String {
        String(localized: "conversation.create.prompt", defaultValue: "Name your chat", comment: "Placeholder of the name field in the New Chat card")
    }

    static var shapeLabel: String {
        String(localized: "conversation.create.shape", defaultValue: "Shape", comment: "Label of the shape picker in the New Chat card")
    }

    static func shapeOption(_ name: String) -> String {
        String(localized: "conversation.create.shapeOption", defaultValue: "\(name) shape", comment: "VoiceOver label of a shape in the New Chat card. Placeholder is the shape name, e.g. Heart shape")
    }

    static var colorLabel: String {
        String(localized: "conversation.create.color", defaultValue: "Color", comment: "Label of the color picker in the New Chat card")
    }

    static var close: String {
        String(localized: "conversation.close", defaultValue: "Close", comment: "Close button of the New Chat card")
    }

    // iOS chat list
    static var searchField: String {
        String(localized: "conversation.list.search", defaultValue: "Search", comment: "Placeholder of the floating search field at the bottom of the chat list")
    }

    static var searchFieldHint: String {
        String(localized: "conversation.list.search.hint", defaultValue: "Filters chats by name and message text.", comment: "Accessibility hint of the chat list search field")
    }

    static var clearSearch: String {
        String(localized: "conversation.list.search.clear", defaultValue: "Clear Search", comment: "Round button beside the chat list search field")
    }

    // Chat screen (iOS)
    static var back: String {
        String(localized: "conversation.back", defaultValue: "Back to Chats", comment: "Floating back button on the iPhone chat screen")
    }

    static func ask(_ name: String) -> String {
        String(localized: "conversation.ask", defaultValue: "Ask \(name)", comment: "Composer placeholder on iPhone. Placeholder is the chat name")
    }

    static var photoOrVideo: String {
        String(localized: "conversation.add.photo", defaultValue: "Photo or Video", comment: "Composer + menu item that opens the photo library")
    }

    static var takePhoto: String {
        String(localized: "conversation.add.camera", defaultValue: "Take Photo", comment: "Composer + menu item that opens the camera")
    }

    static var chooseFile: String {
        String(localized: "conversation.add.file", defaultValue: "Choose File", comment: "Composer + menu item that opens the file browser")
    }

    static var chatSources: String {
        String(localized: "conversation.more.sources", defaultValue: "Chat Sources", comment: "Chat ⋯ menu item that opens the sources of this chat")
    }

    static var shareChat: String {
        DesignSystem.dialogCommand(
            String(localized: "conversation.more.share", defaultValue: "Share Chat…", comment: "Chat ⋯ menu item that shares the conversation as text"),
            plain: shareChatLabel
        )
    }

    static var shareChatLabel: String {
        String(localized: "conversation.more.share.label", defaultValue: "Share Chat", comment: "iOS chat ⋯ menu item that shares the conversation, and its VoiceOver name (no ellipsis)")
    }

    static func transcriptLine(_ speaker: String, _ text: String) -> String {
        String(localized: "conversation.transcript.line", defaultValue: "\(speaker): \(text)", comment: "One message in a shared chat transcript. First placeholder is who wrote it")
    }

    static var transcriptYou: String {
        String(localized: "conversation.transcript.you", defaultValue: "You", comment: "Speaker name of the user's messages in a shared transcript")
    }

    // Find in chat
    static var findInChat: String {
        String(localized: "conversation.find", defaultValue: "Find in Chat", comment: "Chat ⋯ menu item that searches the open conversation")
    }

    static var findPrompt: String {
        String(localized: "conversation.find.prompt", defaultValue: "Find in chat", comment: "Placeholder of the find-in-chat field")
    }

    static func findPosition(_ current: Int, _ total: Int) -> String {
        String(localized: "conversation.find.position", defaultValue: "\(current) of \(total)", comment: "Find-in-chat match counter, e.g. 2 of 5")
    }

    static var findNoMatches: String {
        String(localized: "conversation.find.none", defaultValue: "No matches", comment: "Find-in-chat counter when nothing matches")
    }

    static var findPrevious: String {
        String(localized: "conversation.find.previous", defaultValue: "Previous Match", comment: "Find-in-chat button that moves to the previous match")
    }

    static var findNext: String {
        String(localized: "conversation.find.next", defaultValue: "Next Match", comment: "Find-in-chat button that moves to the next match")
    }

    static func findAnnouncement(_ current: Int, _ total: Int) -> String {
        String(localized: "conversation.find.announce", defaultValue: "Match \(current) of \(total)", comment: "VoiceOver announcement when find-in-chat moves to a match")
    }

    // Sent images
    static var oneImage: String {
        String(localized: "conversation.images.one", defaultValue: "1 image", comment: "Caption under one sent image")
    }

    static func images(_ count: Int) -> String {
        String(localized: "conversation.images.many", defaultValue: "\(count) images", comment: "Caption under a pile of sent images. Placeholder is how many")
    }

    static var openImagesHint: String {
        String(localized: "conversation.images.hint", defaultValue: "Opens the images full screen.", comment: "Accessibility hint of a sent image pile")
    }

    static func imagePosition(_ index: Int, _ total: Int) -> String {
        String(localized: "conversation.image.position", defaultValue: "Image \(index) of \(total)", comment: "VoiceOver label of an image in the viewer. Placeholders are its position and the total")
    }

    static var imageActions: String {
        String(localized: "conversation.image.more", defaultValue: "Image Actions", comment: "⋯ menu in the image viewer")
    }

    static var shareImage: String {
        DesignSystem.dialogCommand(
            String(localized: "conversation.image.share", defaultValue: "Share Image…", comment: "Image viewer menu item that shares the image"),
            plain: shareImageLabel
        )
    }

    static var shareImageLabel: String {
        String(localized: "conversation.image.share.label", defaultValue: "Share Image", comment: "iOS image viewer menu item that shares the image, and its VoiceOver name (no ellipsis)")
    }

    static var previousImage: String {
        String(localized: "conversation.image.previous", defaultValue: "Previous Image", comment: "Image viewer button on Mac")
    }

    static var nextImage: String {
        String(localized: "conversation.image.next", defaultValue: "Next Image", comment: "Image viewer button on Mac")
    }

    static var zoomHint: String {
        String(localized: "conversation.image.zoom.hint", defaultValue: "Pinch or double-tap to zoom.", comment: "Accessibility hint of an image in the viewer")
    }
}
