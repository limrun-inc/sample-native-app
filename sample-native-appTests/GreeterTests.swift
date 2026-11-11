import XCTest
@testable import sample_native_app

final class GreeterTests: XCTestCase {
    func testGreetsByName() {
        XCTAssertEqual(Greeter.greeting(for: "Ada"), "Hello, Ada!")
    }

    func testTrimsSpaces() {
        XCTAssertEqual(Greeter.greeting(for: "  Ada "), "Hello, Ada!")
    }

    func testGreetsTheWorldWithoutAName() {
        XCTAssertEqual(Greeter.greeting(for: "   "), "Hello, world!")
    }
}
