import Foundation

// The greeting rules live outside the view so the unit tests can call them
// without driving the UI. The app target isolates code to the main actor by
// default; `nonisolated` lets the tests call these from any context.
nonisolated enum Greeter {
    static func recipient(for name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "world" : trimmed
    }

    static func greeting(for name: String) -> String {
        "Hello, \(recipient(for: name))!"
    }
}
