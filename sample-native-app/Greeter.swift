import Foundation

// The greeting rules live outside the view so the unit tests can call them
// without launching the app.
enum Greeter {
    nonisolated static func recipient(for name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "world" : trimmed
    }

    nonisolated static func greeting(for name: String) -> String {
        "Hello, \(recipient(for: name))!"
    }
}
