import Foundation

// The greeting rules live outside the view so the unit tests can call them
// without driving the UI. The app target isolates code to the main actor by
// default; `nonisolated` lets the tests call these from any context.
nonisolated enum Greeter {
    // A longer name does not fit the heading on one line.
    static let maxNameLength = 16

    static func greeting(for name: String) -> String {
        "Hello, \(recipient(for: name))!"
    }

    static func recipient(for name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return "world"
        }
        if trimmed.count > maxNameLength {
            return shortened(trimmed)
        }
        return trimmed
    }

    // Prefers the first name, and cuts a single long word.
    static func shortened(_ name: String) -> String {
        if let first = name.split(whereSeparator: \.isWhitespace).first, first.count <= maxNameLength {
            return String(first)
        }
        return name.prefix(maxNameLength - 1) + "…"
    }
}
