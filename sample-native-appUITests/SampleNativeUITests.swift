import XCTest

final class SampleNativeUITests: XCTestCase {
    func testStartScreenIsVisible() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["Subway Runner"].waitForExistence(timeout: 10))
    }

    func testGameStartsAndShowsScore() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["startButton"].waitForExistence(timeout: 10))
        app.buttons["startButton"].tap()
        XCTAssertTrue(app.staticTexts["scoreLabel"].exists)
    }
}
