//
//  MarkdownStyle.swift
//  Raven
//
//  Answer formatting: inline code chips, code blocks in rounded boxes and
//  light syntax colors for common languages.
//

import MarkdownUI
import SwiftUI

extension Theme {
    static var raven: Theme {
        Theme.basic
            .code {
                FontFamilyVariant(.monospaced)
                FontSize(.em(0.88))
                BackgroundColor(DesignSystem.ConversationColors.inlineCode)
            }
            .link {
                ForegroundColor(.accentColor)
            }
            .codeBlock { configuration in
                ScrollView(.horizontal) {
                    configuration.label
                        .fixedSize(horizontal: false, vertical: true)
                        .relativeLineSpacing(.em(0.2))
                        .markdownTextStyle {
                            FontFamilyVariant(.monospaced)
                            FontSize(.em(0.85))
                        }
                        .padding(DesignSystem.Conversation.codeBlockPadding)
                }
                .background {
                    RoundedRectangle(cornerRadius: DesignSystem.Conversation.codeBlockRadius, style: .continuous)
                        .fill(.background)
                }
                .markdownMargin(top: .zero, bottom: .em(0.8))
            }
    }
}

/// Small keyword/string/comment/number colorer. Not a full parser; it only
/// has to make code blocks easier to scan.
nonisolated struct RavenCodeHighlighter: CodeSyntaxHighlighter {
    func highlightCode(_ code: String, language: String?) -> Text {
        let hashComments = Self.hashCommentLanguages.contains(language?.lowercased() ?? "")
        let pattern = [
            hashComments ? #"(?<comment>#[^\n]*|//[^\n]*)"# : #"(?<comment>//[^\n]*|/\*[\s\S]*?\*/)"#,
            #"(?<string>"(?:\\.|[^"\\\n])*"|'(?:\\.|[^'\\\n])*'|`[^`]*`)"#,
            #"(?<number>\b\d+(?:\.\d+)?\b)"#,
            #"(?<word>\b[A-Za-z_][A-Za-z0-9_]*\b)"#
        ].joined(separator: "|")

        guard let regex = try? NSRegularExpression(pattern: pattern) else { return Text(code) }
        let source = code as NSString
        var result = AttributedString()
        var cursor = 0

        for match in regex.matches(in: code, range: NSRange(location: 0, length: source.length)) {
            let color: Color?
            if match.range(withName: "comment").location != NSNotFound {
                color = .secondary
            } else if match.range(withName: "string").location != NSNotFound {
                color = .red
            } else if match.range(withName: "number").location != NSNotFound {
                color = .orange
            } else if Self.keywords.contains(source.substring(with: match.range)) {
                color = .pink
            } else {
                color = nil
            }
            guard let color else { continue }

            if match.range.location > cursor {
                result += AttributedString(source.substring(with: NSRange(location: cursor, length: match.range.location - cursor)))
            }
            var token = AttributedString(source.substring(with: match.range))
            token.foregroundColor = color
            result += token
            cursor = match.range.location + match.range.length
        }
        if cursor < source.length {
            result += AttributedString(source.substring(from: cursor))
        }
        return Text(result)
    }

    private static let hashCommentLanguages: Set<String> = ["python", "py", "sh", "bash", "zsh", "shell", "ruby", "rb", "yaml", "yml", "toml", "r"]

    private static let keywords: Set<String> = [
        "import", "from", "as", "func", "function", "def", "let", "var", "const", "return", "if", "else", "elif",
        "for", "while", "in", "guard", "switch", "case", "default", "break", "continue", "struct", "class", "enum",
        "protocol", "extension", "interface", "type", "public", "private", "internal", "fileprivate", "static",
        "async", "await", "throws", "throw", "try", "catch", "do", "new", "self", "Self", "super", "this",
        "true", "false", "nil", "null", "None", "True", "False", "and", "or", "not", "export", "package",
        "void", "int", "string", "bool", "with", "yield", "lambda", "where", "some", "any", "final", "override"
    ]
}
