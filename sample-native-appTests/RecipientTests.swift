import Testing
@testable import sample_native_app

// Swift Testing runs next to XCTest in the same target.
struct RecipientTests {
    @Test func keepsTheName() {
        #expect(Greeter.recipient(for: "Ada") == "Ada")
    }

    @Test func fallsBackToWorld() {
        #expect(Greeter.recipient(for: "") == "world")
    }
}
