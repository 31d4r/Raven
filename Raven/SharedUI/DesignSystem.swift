//
//  DesignSystem.swift
//  Raven
//
//  Shared spacing, colors, icons, strings, tooltips and shortcuts.
//  Every visible string lives here so it ships in Localizable.xcstrings.
//

import SwiftUI

enum DesignSystem {}

// MARK: - Command titles

extension DesignSystem {
    /// Title of a command that opens a dialog, sheet or picker.
    /// macOS keeps the HIG ellipsis; iOS and iPadOS show the plain title.
    /// VoiceOver always gets the plain title, so pass that one to `accessibilityLabel`.
    static func dialogCommand(_ macTitle: String, plain: String) -> String {
        #if os(macOS)
        macTitle
        #else
        plain
        #endif
    }
}

// MARK: - Spacing and layout

extension DesignSystem {
    enum Spacing {
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let contentPadding: CGFloat = 20
        static let labelToMeta: CGFloat = 2
    }

    enum Layout {
        static let minTouchTarget: CGFloat = 44
        static let windowDefaultSize = CGSize(width: 1080, height: 720)
        static let windowMinimumSize = CGSize(width: 640, height: 460)
        static let readableContentWidth: CGFloat = 760
        static let emptyStateMessageWidth: CGFloat = 440
        static let emptyStateButtonWidth: CGFloat = 320
        static let emptyStateImageSize: CGFloat = 96
        static let inspectorMinWidth: CGFloat = 240
        static let inspectorIdealWidth: CGFloat = 280
        static let inspectorMaxWidth: CGFloat = 400
        static let sheetMinWidth: CGFloat = 380
    }

    enum Radius {
        static let bubble: CGFloat = 16
        static let highlight: CGFloat = 10
        static let keyCap: CGFloat = 5
        static let dropZone: CGFloat = 20
    }

    enum Colors {
        /// System `.secondary` often only nearly passes contrast on body and meta copy.
        static let supporting = Color.primary.opacity(0.72)
        static let userBubbleOpacity: Double = 0.14
        static let dropOverContentOpacity: Double = 0.06
        static let dropOnEmptyStateOpacity: Double = 0.08
    }

    enum Storage {
        static let showsSourcesInspector = "showsSourcesInspector"
        static let showsMessageTimes = "showsMessageTimes"
    }

    enum Motion {
        static let bannerTransition = AnyTransition.move(edge: .bottom).combined(with: .opacity)
        static let bannerAutoDismissDelay: Duration = .seconds(8)
    }
}

// MARK: - Icons

extension DesignSystem {
    enum Icons {
        static let newChat = "square.and.pencil"
        static let chat = "bubble.left.and.text.bubble.right"
        static let chats = "bubble.left.and.bubble.right"
        static let add = "plus"
        static let addFiles = "doc.badge.plus"
        static let addPhotos = "photo.on.rectangle"
        static let sources = "books.vertical"
        static let inspector = "sidebar.trailing"
        static let more = "ellipsis.circle"
        static let messageTimes = "clock"
        static let copy = "doc.on.doc"
        static let rename = "pencil"
        static let clearHistory = "clear"
        static let delete = "trash"
        static let send = "arrow.up"
        static let cancel = "xmark"
        static let dismiss = "xmark"
        static let quickLook = "eye"
        static let showInFinder = "folder"
        static let success = "checkmark.circle.fill"
        static let warning = "exclamationmark.triangle.fill"
        static let assistant = "brain.head.profile"
        static let unavailable = "apple.intelligence"
        static let keyboard = "keyboard"
        static let audio = "waveform"
        static let image = "photo"
        static let pdf = "doc.richtext"
        static let video = "film"
        static let text = "doc.text"
        static let file = "doc"
        static let noChatSelected = "text.bubble"
    }
}

// MARK: - Tooltips

extension DesignSystem {
    enum Help {
        static func withShortcut(_ title: String, _ shortcut: String) -> String {
            String(
                localized: "help.withShortcut",
                defaultValue: "\(title) (\(shortcut))",
                comment: "Tooltip first line. First placeholder is the command name, second is its keyboard shortcut, e.g. New Chat (⌘N)"
            )
        }

        static func withDetail(_ firstLine: String, _ detail: String) -> String {
            String(
                localized: "help.withDetail",
                defaultValue: "\(firstLine)\n\(detail)",
                comment: "Tooltip with two lines. First placeholder is the command name (and shortcut), second says what happens or why it is unavailable"
            )
        }

        /// Tooltip = label, optional shortcut, optional detail or disabled reason.
        static func tooltip(_ title: String, shortcut: Shortcut? = nil, detail: String? = nil) -> String {
            let firstLine = shortcut.map { withShortcut(title, $0.display) } ?? title
            guard let detail, !detail.isEmpty else { return firstLine }
            return withDetail(firstLine, detail)
        }
    }
}

// MARK: - Shortcuts

extension DesignSystem {
    struct Shortcut {
        let key: KeyEquivalent
        let modifiers: EventModifiers
        /// Key caps shown in tooltips and the Keyboard Shortcuts window.
        let display: String
    }

    enum Shortcuts {
        static let windowID = "keyboard-shortcuts"

        static let newChat = Shortcut(key: "n", modifiers: .command, display: "⌘N")
        static let renameChat = Shortcut(key: "r", modifiers: [.command, .shift], display: "⇧⌘R")
        static let deleteChat = Shortcut(key: .delete, modifiers: [.command, .shift], display: "⇧⌘⌫")
        static let addSources = Shortcut(key: "o", modifiers: .command, display: "⌘O")
        static let sendQuestion = Shortcut(key: .return, modifiers: .command, display: "⌘↩")
        static let cancelAnswer = Shortcut(key: ".", modifiers: .command, display: "⌘.")
        static let copyResponse = Shortcut(key: "c", modifiers: [.command, .shift], display: "⇧⌘C")
        static let clearHistory = Shortcut(key: "k", modifiers: [.command, .shift], display: "⇧⌘K")
        static let toggleSources = Shortcut(key: "i", modifiers: [.command, .option], display: "⌥⌘I")
        static let showMessageTimes = Shortcut(key: "t", modifiers: [.command, .option], display: "⌥⌘T")
        static let keyboardShortcuts = Shortcut(key: "/", modifiers: .command, display: "⌘/")

        static let returnKey = "↩"
        static let escapeKey = "⎋"
        static let spaceKey = String(
            localized: "shortcuts.key.space",
            defaultValue: "Space",
            comment: "Name of the Space bar key in the Keyboard Shortcuts window"
        )
        static let deleteKey = "⌫"
        static let toggleSidebar = "⌃⌘S"
    }
}

extension View {
    func keyboardShortcut(_ shortcut: DesignSystem.Shortcut) -> some View {
        keyboardShortcut(shortcut.key, modifiers: shortcut.modifiers)
    }
}

// MARK: - App and window

extension DesignSystem {
    enum App {
        static var name: String {
            String(localized: "app.name", defaultValue: "Raven", comment: "App name, used as the window title when no chat is selected")
        }

        static var assistantName: String {
            String(localized: "app.assistantName", defaultValue: "Raven", comment: "Name shown above the assistant’s answers in a chat")
        }

        static var you: String {
            String(localized: "app.you", defaultValue: "You", comment: "Name shown above the person’s own questions in a chat")
        }
    }

    enum Window {
        static var noChatSelected: String {
            String(localized: "window.subtitle.noChat", defaultValue: "No chat selected", comment: "macOS window subtitle when no chat is selected")
        }

        static var answering: String {
            String(localized: "window.subtitle.answering", defaultValue: "Answering…", comment: "macOS window subtitle while Raven writes an answer")
        }

        static var answeringLabel: String {
            String(localized: "window.subtitle.answering.a11y", defaultValue: "Answering", comment: "VoiceOver value of the macOS window subtitle while Raven writes an answer (no ellipsis)")
        }

        static func sourceCount(_ count: Int) -> String {
            String(localized: "window.subtitle.sources", defaultValue: "\(count) sources", comment: "Part of the macOS window subtitle; the number of sources in the chat. Has plural variants")
        }

        static func messageCount(_ count: Int) -> String {
            String(localized: "window.subtitle.messages", defaultValue: "\(count) messages", comment: "Part of the macOS window subtitle; the number of messages in the chat. Has plural variants")
        }

        static func subtitle(_ first: String, _ second: String) -> String {
            String(localized: "window.subtitle.joined", defaultValue: "\(first) · \(second)", comment: "macOS window subtitle joining two status parts, e.g. 3 sources · 12 messages")
        }
    }
}

// MARK: - Shared actions

extension DesignSystem {
    enum Common {
        static var cancel: String {
            String(localized: "common.cancel", defaultValue: "Cancel", comment: "Button that closes a dialog or stops a task without changes")
        }

        static var done: String {
            String(localized: "common.done", defaultValue: "Done", comment: "Button that closes a sheet")
        }

        static var ok: String {
            String(localized: "common.ok", defaultValue: "OK", comment: "Button that closes an error alert")
        }

        static var dismiss: String {
            String(localized: "common.dismiss", defaultValue: "Dismiss", comment: "Accessibility label of the button that closes a banner")
        }

        static var more: String {
            String(localized: "common.more", defaultValue: "More", comment: "Toolbar menu with less common chat commands")
        }

        static var moreHelp: String {
            String(localized: "common.more.help", defaultValue: "Rename, clear or delete this chat", comment: "Tooltip and accessibility hint of the More toolbar menu")
        }

        static var copy: String {
            String(localized: "common.copy", defaultValue: "Copy", comment: "Context menu item that copies one message")
        }
    }
}

// MARK: - Chats (sidebar)

extension DesignSystem {
    enum Chats {
        static var sidebarTitle: String {
            String(localized: "chats.title", defaultValue: "Raven", comment: "Title of the chats list on iPhone and iPad")
        }

        static var loading: String {
            String(localized: "chats.loading", defaultValue: "Loading Chats…", comment: "Shown while the list of chats loads")
        }

        static var loadingLabel: String {
            String(localized: "chats.loading.a11y", defaultValue: "Loading chats", comment: "VoiceOver label while the list of chats loads (no ellipsis)")
        }

        static var newChat: String {
            String(localized: "chats.new", defaultValue: "New Chat", comment: "Toolbar button and menu item that creates a chat")
        }

        static var newChatEllipsis: String {
            DesignSystem.dialogCommand(
                String(localized: "chats.new.ellipsis", defaultValue: "New Chat…", comment: "Button and menu item that opens the New Chat sheet"),
                plain: newChat
            )
        }

        static var newChatHelp: String {
            String(localized: "chats.new.help", defaultValue: "Creates a chat where you add sources and ask questions about them.", comment: "Tooltip detail and accessibility hint for New Chat")
        }

        static var renameChat: String {
            DesignSystem.dialogCommand(
                String(localized: "chats.rename", defaultValue: "Rename Chat…", comment: "Menu item that opens the rename dialog for a chat"),
                plain: renameChatLabel
            )
        }

        static var renameChatLabel: String {
            String(localized: "chats.rename.label", defaultValue: "Rename Chat", comment: "iOS menu item and VoiceOver name of Rename Chat (no ellipsis)")
        }

        static var deleteChat: String {
            DesignSystem.dialogCommand(
                String(localized: "chats.delete", defaultValue: "Delete Chat…", comment: "Destructive menu item that asks to delete a chat"),
                plain: deleteChatLabel
            )
        }

        static var deleteChatLabel: String {
            String(localized: "chats.delete.label", defaultValue: "Delete Chat", comment: "iOS menu item and VoiceOver name of Delete Chat (no ellipsis)")
        }

        static var rename: String {
            String(localized: "chats.rename.short", defaultValue: "Rename", comment: "Swipe action and confirm button that renames a chat")
        }

        static var delete: String {
            String(localized: "chats.delete.short", defaultValue: "Delete", comment: "Swipe action that asks to delete a chat")
        }

        static var noChatReason: String {
            String(localized: "chats.reason.noChat", defaultValue: "Select or create a chat first.", comment: "Why a chat command is unavailable when no chat is selected")
        }

        static var emptyTitle: String {
            String(localized: "chats.empty.title", defaultValue: "No Chats Yet", comment: "Empty chats list title")
        }

        static var emptyMessage: String {
            String(localized: "chats.empty.message", defaultValue: "Start a chat, add your documents, and ask questions about them.", comment: "Empty chats list message")
        }

        static func rowAccessibilityLabel(_ name: String, created: String) -> String {
            String(localized: "chats.row.a11y", defaultValue: "Chat: \(name), created \(created)", comment: "VoiceOver label of a chat row. First placeholder is the chat name, second the creation date")
        }

        // New chat sheet
        static var nameField: String {
            String(localized: "chats.sheet.name", defaultValue: "Name", comment: "Label of the chat name field")
        }

        static var namePrompt: String {
            String(localized: "chats.sheet.name.prompt", defaultValue: "Research Notes", comment: "Placeholder example name in the New Chat sheet")
        }

        static var nameFooter: String {
            String(localized: "chats.sheet.footer", defaultValue: "You can add sources and rename the chat later.", comment: "Footer under the name field in the New Chat sheet")
        }

        static var create: String {
            String(localized: "chats.sheet.create", defaultValue: "Create", comment: "Confirm button in the New Chat sheet")
        }

        static var nameRequiredReason: String {
            String(localized: "chats.reason.nameRequired", defaultValue: "Type a name for the chat.", comment: "Why Create or Rename is unavailable")
        }

        static var nameFieldHint: String {
            String(localized: "chats.sheet.name.hint", defaultValue: "Enter a name for the chat.", comment: "Accessibility hint of the chat name field")
        }

        // Rename alert
        static var renameTitle: String {
            String(localized: "chats.renameAlert.title", defaultValue: "Rename Chat", comment: "Title of the rename alert")
        }

        static func renameMessage(_ name: String) -> String {
            String(localized: "chats.renameAlert.message", defaultValue: "Enter a new name for “\(name)”.", comment: "Message of the rename alert; the current chat name")
        }

        // Delete confirmation
        static func deleteConfirmTitle(_ name: String) -> String {
            String(localized: "chats.deleteConfirm.title", defaultValue: "Delete “\(name)”?", comment: "Delete chat confirmation title; the chat name")
        }

        static var deleteConfirmMessage: String {
            String(localized: "chats.deleteConfirm.message", defaultValue: "Its chat history and Raven’s copies of its sources are deleted. Your original files aren’t changed.", comment: "Delete chat confirmation message")
        }
    }
}

// MARK: - Chat (detail)

extension DesignSystem {
    enum Chat {
        static var noChatTitle: String {
            String(localized: "chat.none.title", defaultValue: "Select a Chat", comment: "Detail empty state title when chats exist but none is selected")
        }

        static var noChatMessage: String {
            String(localized: "chat.none.message", defaultValue: "Choose a chat in the sidebar to continue where you left off.", comment: "Detail empty state message when chats exist but none is selected")
        }

        static var firstChatTitle: String {
            String(localized: "chat.first.title", defaultValue: "Start Your First Chat", comment: "Detail empty state title when there are no chats")
        }

        static var firstChatMessage: String {
            String(localized: "chat.first.message", defaultValue: "Create a chat, add PDFs, images, audio or video, and ask questions about them. Apple Intelligence answers on your device.", comment: "Detail empty state message when there are no chats")
        }

        static var addSourcesTitle: String {
            String(localized: "chat.empty.noSources.title", defaultValue: "Add Sources to Get Started", comment: "Chat empty state title when the chat has no sources")
        }

        static var addSourcesMessage: String {
            String(localized: "chat.empty.noSources.message", defaultValue: "Add PDFs, images, audio or video to this chat, then ask about them below. Raven works with copies, so your originals aren’t changed.", comment: "Chat empty state message when the chat has no sources")
        }

        static var askTitle: String {
            String(localized: "chat.empty.title", defaultValue: "Ask About Your Sources", comment: "Chat empty state title when the chat has sources but no messages")
        }

        static func askMessage(_ count: Int) -> String {
            String(localized: "chat.empty.message", defaultValue: "Ask a question about the \(count) sources in this chat. Your conversation is saved here.", comment: "Chat empty state message; the number of sources. Has plural variants")
        }

        static var releaseToAdd: String {
            String(localized: "chat.drop.title", defaultValue: "Release to Add Sources", comment: "Empty state title while files are dragged over the window")
        }

        static var questionPrompt: String {
            String(localized: "chat.input.prompt", defaultValue: "Ask about your sources…", comment: "Placeholder of the question field")
        }

        static var questionLabel: String {
            String(localized: "chat.input.label", defaultValue: "Question", comment: "Accessibility label of the question field")
        }

        static var questionHint: String {
            String(localized: "chat.input.hint", defaultValue: "Type a question about this chat’s sources, then send it.", comment: "Accessibility hint of the question field")
        }

        static var send: String {
            String(localized: "chat.send", defaultValue: "Send Question", comment: "Button and menu item that sends the typed question")
        }

        static var sendDetail: String {
            String(localized: "chat.send.detail", defaultValue: "Raven reads this chat’s sources and answers on your device.", comment: "Tooltip detail and accessibility hint of Send Question")
        }

        static var emptyQuestionReason: String {
            String(localized: "chat.reason.emptyQuestion", defaultValue: "Type a question to send.", comment: "Why Send Question is unavailable")
        }

        static var busyReason: String {
            String(localized: "chat.reason.busy", defaultValue: "Available when Raven finishes answering.", comment: "Why a chat command is unavailable while an answer is being written")
        }

        static var cancelAnswer: String {
            String(localized: "chat.cancel", defaultValue: "Cancel Answer", comment: "Menu item that stops the answer being written")
        }

        static var notAnsweringReason: String {
            String(localized: "chat.reason.notAnswering", defaultValue: "Raven isn’t answering right now.", comment: "Why Cancel Answer is unavailable")
        }

        static var answering: String {
            String(localized: "chat.progress", defaultValue: "Reading your sources and writing an answer…", comment: "Activity bar text while Raven answers")
        }

        static var copyResponse: String {
            String(localized: "chat.copyResponse", defaultValue: "Copy Last Response", comment: "Toolbar button and menu item that copies Raven’s latest answer")
        }

        static var copyResponseShort: String {
            String(localized: "chat.copyResponse.short", defaultValue: "Copy Response", comment: "Short toolbar title for Copy Last Response")
        }

        static var copyResponseDetail: String {
            String(localized: "chat.copyResponse.detail", defaultValue: "Copies Raven’s latest answer so you can paste it anywhere.", comment: "Tooltip detail and accessibility hint of Copy Last Response")
        }

        static var noResponseReason: String {
            String(localized: "chat.reason.noResponse", defaultValue: "Ask a question first. Then you can copy Raven’s answer.", comment: "Why Copy Last Response is unavailable")
        }

        static var copied: String {
            String(localized: "chat.copied", defaultValue: "Copied Raven’s answer.", comment: "VoiceOver announcement after copying an answer")
        }

        static var clearHistory: String {
            DesignSystem.dialogCommand(
                String(localized: "chat.clearHistory", defaultValue: "Clear History…", comment: "Destructive menu item that asks to delete all messages in a chat"),
                plain: clearHistoryLabel
            )
        }

        static var clearHistoryLabel: String {
            String(localized: "chat.clearHistory.label", defaultValue: "Clear History", comment: "iOS menu item and VoiceOver name of Clear History (no ellipsis)")
        }

        static var clearHistoryDetail: String {
            String(localized: "chat.clearHistory.detail", defaultValue: "Deletes this chat’s messages. Its sources stay.", comment: "Tooltip detail and accessibility hint of Clear History")
        }

        static var noMessagesReason: String {
            String(localized: "chat.reason.noMessages", defaultValue: "This chat has no messages to clear.", comment: "Why Clear History is unavailable")
        }

        static func clearConfirmTitle(_ name: String) -> String {
            String(localized: "chat.clearConfirm.title", defaultValue: "Clear the History of “\(name)”?", comment: "Clear history confirmation title; the chat name")
        }

        static func clearConfirmMessage(_ count: Int) -> String {
            String(localized: "chat.clearConfirm.message", defaultValue: "All \(count) messages in this chat are deleted. Its sources stay.", comment: "Clear history confirmation message; the number of messages. Has plural variants")
        }

        static var clearConfirmButton: String {
            String(localized: "chat.clearConfirm.button", defaultValue: "Clear History", comment: "Destructive button in the clear history confirmation")
        }

        static var userMessageLabel: String {
            String(localized: "chat.message.user.a11y", defaultValue: "You asked", comment: "VoiceOver label of a question bubble; its text is read as the value")
        }

        static var assistantMessageLabel: String {
            String(localized: "chat.message.assistant.a11y", defaultValue: "Raven answered", comment: "VoiceOver label of an answer; its text is read as the value")
        }

        static func switchedAnnouncement(_ name: String) -> String {
            String(localized: "chat.switched.a11y", defaultValue: "Switched to chat \(name)", comment: "VoiceOver announcement after selecting a chat; the chat name")
        }

        static var answerReady: String {
            String(localized: "chat.answerReady.a11y", defaultValue: "Raven answered.", comment: "VoiceOver announcement when an answer arrives")
        }

        // Apple Intelligence availability
        static var unavailableTitle: String {
            String(localized: "chat.unavailable.title", defaultValue: "Apple Intelligence Isn’t Available", comment: "Chat empty state title when the on-device model can’t be used")
        }

        static var unavailableNotEnabled: String {
            #if os(macOS)
            String(localized: "chat.unavailable.notEnabled.mac", defaultValue: "Turn on Apple Intelligence in System Settings ▸ Apple Intelligence & Siri, then come back to ask your question.", comment: "Mac: why answers are unavailable and how to fix it")
            #else
            String(localized: "chat.unavailable.notEnabled.ios", defaultValue: "Turn on Apple Intelligence in Settings ▸ Apple Intelligence & Siri, then come back to ask your question.", comment: "iPhone and iPad: why answers are unavailable and how to fix it")
            #endif
        }

        static var unavailableNotEligible: String {
            String(localized: "chat.unavailable.notEligible", defaultValue: "This device doesn’t support Apple Intelligence, so Raven can’t answer questions here. Your chats and sources are still saved.", comment: "Why answers are unavailable on an unsupported device")
        }

        static var unavailableNotReady: String {
            String(localized: "chat.unavailable.notReady", defaultValue: "Apple Intelligence is still getting ready. Keep your device connected to power and Wi‑Fi, then try again later.", comment: "Why answers are unavailable while the model downloads")
        }

        static var unavailableOther: String {
            String(localized: "chat.unavailable.other", defaultValue: "Apple Intelligence can’t be used right now. Check that it’s turned on in Settings, then try again.", comment: "Generic reason answers are unavailable")
        }
    }
}

// MARK: - Sources

extension DesignSystem {
    enum Sources {
        static var title: String {
            String(localized: "sources.title", defaultValue: "Sources", comment: "Title of the sources inspector and sheet")
        }

        static func count(_ count: Int) -> String {
            String(localized: "sources.count", defaultValue: "\(count) sources", comment: "Header of the sources list; the number of sources. Has plural variants")
        }

        static var show: String {
            String(localized: "sources.show", defaultValue: "Show Sources", comment: "Toolbar button and menu item that shows the sources panel")
        }

        static var hide: String {
            String(localized: "sources.hide", defaultValue: "Hide Sources", comment: "Toolbar button and menu item that hides the sources panel")
        }

        static var toggleDetail: String {
            String(localized: "sources.toggle.detail", defaultValue: "Shows the files Raven reads for this chat.", comment: "Tooltip detail and accessibility hint of Show Sources")
        }

        static var loading: String {
            String(localized: "sources.loading", defaultValue: "Loading Sources…", comment: "Shown while a chat’s sources load")
        }

        static var loadingLabel: String {
            String(localized: "sources.loading.a11y", defaultValue: "Loading sources", comment: "VoiceOver label while a chat’s sources load (no ellipsis)")
        }

        static var addSources: String {
            DesignSystem.dialogCommand(
                String(localized: "sources.add", defaultValue: "Add Sources…", comment: "Button and menu item that opens the file panel to add sources"),
                plain: addSourcesLabel
            )
        }

        static var addSourcesLabel: String {
            String(localized: "sources.add.label", defaultValue: "Add Sources", comment: "iOS title and VoiceOver name of Add Sources (no ellipsis)")
        }

        static var addSourcesDetail: String {
            String(localized: "sources.add.detail", defaultValue: "Adds PDFs, images, audio, video or text files. Raven works with copies.", comment: "Tooltip detail and accessibility hint of Add Sources")
        }

        static var add: String {
            String(localized: "sources.add.menu", defaultValue: "Add", comment: "iOS menu that offers Add Files and Add from Photos")
        }

        static var addFiles: String {
            DesignSystem.dialogCommand(
                String(localized: "sources.addFiles", defaultValue: "Add Files…", comment: "Button that opens the Files picker"),
                plain: addFilesLabel
            )
        }

        static var addFilesLabel: String {
            String(localized: "sources.addFiles.label", defaultValue: "Add Files", comment: "iOS button and menu item that opens the Files picker (no ellipsis)")
        }

        static var addFilesDetail: String {
            String(localized: "sources.addFiles.detail", defaultValue: "Adds PDFs, audio, video or text files from Files.", comment: "Menu subtitle and accessibility hint of Add Files")
        }

        static var addPhotos: String {
            DesignSystem.dialogCommand(
                String(localized: "sources.addPhotos", defaultValue: "Add from Photos…", comment: "Button that opens the photo picker"),
                plain: addPhotosLabel
            )
        }

        static var addPhotosLabel: String {
            String(localized: "sources.addPhotos.label", defaultValue: "Add from Photos", comment: "iOS button and menu item that opens the photo picker, and its VoiceOver name (no ellipsis)")
        }

        static var addPhotosDetail: String {
            String(localized: "sources.addPhotos.detail", defaultValue: "Adds photos in the order you pick them.", comment: "Menu subtitle and accessibility hint of Add from Photos")
        }

        static var panelConfirm: String {
            String(localized: "sources.panel.confirm", defaultValue: "Add", comment: "Confirm button of the file panel that adds sources")
        }

        static var panelMessage: String {
            String(localized: "sources.panel.message", defaultValue: "Choose PDFs, images, audio, video or text files to add to this chat.", comment: "Message at the top of the Mac file panel")
        }

        static var addingPhotos: String {
            String(localized: "sources.progress.photos", defaultValue: "Adding Photos…", comment: "Activity bar text while photos are imported")
        }

        static var addingPhotosLabel: String {
            String(localized: "sources.progress.photos.a11y", defaultValue: "Adding photos", comment: "VoiceOver label of the activity bar while photos are imported (no ellipsis)")
        }

        static var noChatTitle: String {
            String(localized: "sources.noChat.title", defaultValue: "No Chat Selected", comment: "Sources panel title when no chat is selected")
        }

        static var noChatMessage: String {
            String(localized: "sources.noChat.message", defaultValue: "Select a chat to see and add its sources.", comment: "Sources panel message when no chat is selected")
        }

        static var emptyTitle: String {
            String(localized: "sources.empty.title", defaultValue: "Add Your First Source", comment: "Sources panel empty state title")
        }

        static var emptyMessage: String {
            String(localized: "sources.empty.message", defaultValue: "Add PDFs, images, audio or video. Raven copies them into this chat, so your originals aren’t changed.", comment: "Sources panel empty state message")
        }

        static var footer: String {
            String(localized: "sources.footer", defaultValue: "Raven works with copies of these files. Your originals aren’t changed.", comment: "Footer under the sources list")
        }

        static var quickLook: String {
            String(localized: "sources.quickLook", defaultValue: "Quick Look", comment: "Menu item that previews a source")
        }

        static var showInFinder: String {
            String(localized: "sources.showInFinder", defaultValue: "Show in Finder", comment: "Mac menu item that reveals Raven’s copy of a source in Finder")
        }

        static var removeSource: String {
            DesignSystem.dialogCommand(
                String(localized: "sources.remove", defaultValue: "Remove Source…", comment: "Destructive menu item that asks to remove a source from the chat"),
                plain: removeSourceLabel
            )
        }

        static var removeSourceLabel: String {
            String(localized: "sources.remove.label", defaultValue: "Remove Source", comment: "iOS menu item and VoiceOver name of Remove Source (no ellipsis)")
        }

        static var remove: String {
            String(localized: "sources.remove.short", defaultValue: "Remove", comment: "Swipe action and destructive confirm button that removes a source")
        }

        static func removeConfirmTitle(_ name: String) -> String {
            String(localized: "sources.removeConfirm.title", defaultValue: "Remove “\(name)”?", comment: "Remove source confirmation title; the file name")
        }

        static var removeConfirmMessage: String {
            String(localized: "sources.removeConfirm.message", defaultValue: "Raven deletes its copy from this chat. Your original file isn’t changed.", comment: "Remove source confirmation message")
        }

        static func added(_ count: Int) -> String {
            String(localized: "sources.added.banner", defaultValue: "Added \(count) sources. Ask a question below and Raven reads them on your device.", comment: "Success banner after adding sources; the number added. Has plural variants")
        }

        static func meta(_ kind: String, _ date: String) -> String {
            String(localized: "sources.row.meta", defaultValue: "\(kind) · \(date)", comment: "Meta line under a source name. First placeholder is the file kind (PDF, Image…), second the date it was added")
        }

        static func spokenName(_ name: String, _ kind: String) -> String {
            String(localized: "sources.row.a11y", defaultValue: "\(name), \(kind)", comment: "VoiceOver label of a source. First placeholder is the file name without extension, second the file kind")
        }

        static func addedOn(_ date: String) -> String {
            String(localized: "sources.row.a11y.value", defaultValue: "Added \(date)", comment: "VoiceOver value of a source; the date it was added")
        }

        static func kind(forExtension fileExtension: String) -> String {
            switch fileExtension.lowercased() {
            case "pdf":
                String(localized: "sources.kind.pdf", defaultValue: "PDF", comment: "File kind of a PDF source")
            case "mp3", "wav", "aiff", "aif", "m4a", "caf":
                String(localized: "sources.kind.audio", defaultValue: "Audio", comment: "File kind of an audio source")
            case "jpg", "jpeg", "png", "tiff", "tif", "heic", "gif", "bmp":
                String(localized: "sources.kind.image", defaultValue: "Image", comment: "File kind of an image source")
            case "mp4", "mov", "m4v", "avi", "mkv":
                String(localized: "sources.kind.video", defaultValue: "Video", comment: "File kind of a video source")
            case "txt", "text", "md", "rtf":
                String(localized: "sources.kind.text", defaultValue: "Text", comment: "File kind of a text source")
            default:
                String(localized: "sources.kind.file", defaultValue: "File", comment: "File kind of any other source")
            }
        }

        static func icon(forExtension fileExtension: String) -> String {
            switch fileExtension.lowercased() {
            case "pdf": Icons.pdf
            case "mp3", "wav", "aiff", "aif", "m4a", "caf": Icons.audio
            case "jpg", "jpeg", "png", "tiff", "tif", "heic", "gif", "bmp": Icons.image
            case "mp4", "mov", "m4v", "avi", "mkv": Icons.video
            case "txt", "text", "md", "rtf": Icons.text
            default: Icons.file
            }
        }
    }
}

// MARK: - Errors

extension DesignSystem {
    enum Errors {
        static var title: String {
            String(localized: "error.title", defaultValue: "Something Went Wrong", comment: "Title of every error alert")
        }

        static var answerFailed: String {
            String(localized: "error.answer", defaultValue: "Raven couldn’t answer this question. Make sure Apple Intelligence is ready, then try again.", comment: "Error when generating an answer fails")
        }

        static var contextTooLong: String {
            String(localized: "error.answer.contextTooLong", defaultValue: "This chat’s sources and history are too long for Apple Intelligence to read at once. Remove some sources or clear the history, then try again.", comment: "Error when the model context window is exceeded")
        }

        static var guardrail: String {
            String(localized: "error.answer.guardrail", defaultValue: "Apple Intelligence couldn’t answer this question because of its safety guidelines. Try asking it a different way.", comment: "Error when the model refuses because of safety guidelines")
        }

        static var loadChatFailed: String {
            String(localized: "error.loadChat", defaultValue: "This chat’s history couldn’t be loaded. Select the chat again to retry.", comment: "Error when chat messages can’t be loaded")
        }

        static var clearFailed: String {
            String(localized: "error.clearHistory", defaultValue: "The chat history couldn’t be cleared. Try again.", comment: "Error when clearing chat history fails")
        }

        static var loadChatsFailed: String {
            String(localized: "error.loadChats", defaultValue: "Your chats couldn’t be loaded. Quit and reopen Raven to try again.", comment: "Error when the chats list can’t be loaded")
        }

        static var createChatFailed: String {
            String(localized: "error.createChat", defaultValue: "The chat couldn’t be created. Make sure there’s space on this device, then try again.", comment: "Error when creating a chat fails")
        }

        static var renameChatFailed: String {
            String(localized: "error.renameChat", defaultValue: "The chat couldn’t be renamed. Try again.", comment: "Error when renaming a chat fails")
        }

        static var deleteChatFailed: String {
            String(localized: "error.deleteChat", defaultValue: "The chat couldn’t be deleted. Try again.", comment: "Error when deleting a chat fails")
        }

        static var loadSourcesFailed: String {
            String(localized: "error.loadSources", defaultValue: "This chat’s sources couldn’t be loaded. Select the chat again to retry.", comment: "Error when sources can’t be loaded")
        }

        static var addSourcesFailed: String {
            String(localized: "error.addSources", defaultValue: "The files couldn’t be added. Make sure they’re PDFs, images, audio, video or text files you can open, and that there’s space on this device, then try again.", comment: "Error when adding sources fails")
        }

        static var addPhotosFailed: String {
            String(localized: "error.addPhotos", defaultValue: "Some photos couldn’t be added. If they’re in iCloud, try again when they’ve downloaded.", comment: "Error when some photos can’t be imported")
        }

        static var removeSourceFailed: String {
            String(localized: "error.removeSource", defaultValue: "The source couldn’t be removed. Try again.", comment: "Error when removing a source fails")
        }

        static var unsupportedDrop: String {
            String(localized: "error.unsupportedDrop", defaultValue: "Raven can’t read some of these files. Add PDFs, images, audio, video or text files.", comment: "Error when dropped files have an unsupported type")
        }
    }
}

// MARK: - Menus and Keyboard Shortcuts window

extension DesignSystem {
    enum Menu {
        static var chat: String {
            String(localized: "menu.chat", defaultValue: "Chat", comment: "Menu bar menu with chat commands")
        }

        static var keyboardShortcuts: String {
            String(localized: "menu.keyboardShortcuts", defaultValue: "Keyboard Shortcuts", comment: "Help menu item and window title listing keyboard shortcuts")
        }

        static var sectionChats: String {
            String(localized: "shortcuts.section.chats", defaultValue: "Chats", comment: "Keyboard Shortcuts window section")
        }

        static var sectionConversation: String {
            String(localized: "shortcuts.section.conversation", defaultValue: "Conversation", comment: "Keyboard Shortcuts window section")
        }

        static var sectionSources: String {
            String(localized: "shortcuts.section.sources", defaultValue: "Sources", comment: "Keyboard Shortcuts window section")
        }

        static var sectionView: String {
            String(localized: "shortcuts.section.view", defaultValue: "View", comment: "Keyboard Shortcuts window section")
        }

        static var sectionDialogs: String {
            String(localized: "shortcuts.section.dialogs", defaultValue: "Dialogs", comment: "Keyboard Shortcuts window section")
        }

        static var toggleSidebar: String {
            String(localized: "shortcuts.toggleSidebar", defaultValue: "Show or Hide Sidebar", comment: "Keyboard Shortcuts window row for the system sidebar toggle")
        }

        static var showMessageTimes: String {
            String(localized: "menu.showMessageTimes", defaultValue: "Show Message Times", comment: "Mac View menu toggle and Keyboard Shortcuts row that keeps the time of every message visible")
        }

        static var toggleSources: String {
            String(localized: "shortcuts.toggleSources", defaultValue: "Show or Hide Sources", comment: "Keyboard Shortcuts window row for the sources panel")
        }

        static var sendFromField: String {
            String(localized: "shortcuts.sendFromField", defaultValue: "Send Question from the Question Field", comment: "Keyboard Shortcuts window row: Return in the question field")
        }

        static var quickLookSelected: String {
            String(localized: "shortcuts.quickLook", defaultValue: "Quick Look Selected Source", comment: "Keyboard Shortcuts window row")
        }

        static var removeSelected: String {
            DesignSystem.dialogCommand(
                String(localized: "shortcuts.removeSelected", defaultValue: "Remove Selected Source…", comment: "Keyboard Shortcuts window row"),
                plain: removeSelectedLabel
            )
        }

        static var removeSelectedLabel: String {
            String(localized: "shortcuts.removeSelected.label", defaultValue: "Remove Selected Source", comment: "VoiceOver name of the Remove Selected Source row in the Keyboard Shortcuts window (no ellipsis)")
        }

        static var confirmDialog: String {
            String(localized: "shortcuts.confirm", defaultValue: "Create or Confirm", comment: "Keyboard Shortcuts window row: Return confirms a sheet")
        }

        static var cancelDialog: String {
            String(localized: "shortcuts.cancelDialog", defaultValue: "Cancel a Sheet or Dialog", comment: "Keyboard Shortcuts window row: Escape cancels")
        }
    }

    enum Quit {
        static var title: String {
            String(localized: "quit.title", defaultValue: "Quit Raven?", comment: "Title of the alert shown when closing the Mac window")
        }

        static var message: String {
            String(localized: "quit.message", defaultValue: "Your chats and sources are saved, so you can pick up where you left off.", comment: "Message of the alert shown when closing the Mac window")
        }

        static var quit: String {
            String(localized: "quit.button", defaultValue: "Quit", comment: "Confirm button that quits Raven")
        }
    }
}

// MARK: - Voice Control synonyms

extension DesignSystem {
    /// Extra names people can say with Voice Control. The first matches the visible title.
    enum VoiceControl {
        static var newChat: [Text] { [Text(Chats.newChat), Text("Add Chat"), Text("Create Chat")] }
        static var addSources: [Text] { [Text(Sources.addSources), Text("Add Files"), Text("Import")] }
        static var addPhotos: [Text] { [Text(Sources.addPhotos), Text("Add Photos"), Text("Add Images")] }
        static var send: [Text] { [Text(Chat.send), Text("Send"), Text("Ask")] }
        static var cancel: [Text] { [Text(Common.cancel), Text("Stop")] }
        static var copyResponse: [Text] { [Text(Chat.copyResponse), Text("Copy Response"), Text("Copy")] }
        static var clearHistory: [Text] { [Text(Chat.clearHistory), Text("Clear Chat")] }
        static var sources: [Text] { [Text(Sources.show), Text("Sources"), Text("Files")] }
        static var more: [Text] { [Text(Common.more), Text("Options"), Text("Menu")] }
        static var dismiss: [Text] { [Text(Common.dismiss), Text("Close")] }
        static var create: [Text] { [Text(Chats.create), Text("Create Chat")] }
        static var rename: [Text] { [Text(Chats.rename), Text("Save")] }
    }
}
