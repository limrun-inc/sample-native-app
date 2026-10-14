import XCTest

final class SampleNativeUITests: XCTestCase {
    func testAsksForBackendWithoutEnvironment() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["No backend configured"].waitForExistence(timeout: 10))
    }
}
