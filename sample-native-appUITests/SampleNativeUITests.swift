import XCTest

final class SampleNativeUITests: XCTestCase {
    func testStartPauseAndResume() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.buttons["startButton"].waitForExistence(timeout: 10))
        app.buttons["startButton"].tap()
        XCTAssertTrue(app.staticTexts["scoreLabel"].waitForExistence(timeout: 5))

        app.buttons["pauseButton"].tap()
        XCTAssertTrue(app.buttons["resumeButton"].waitForExistence(timeout: 5))
        app.buttons["resumeButton"].tap()
        XCTAssertTrue(app.staticTexts["scoreLabel"].exists)
    }

    func testCollisionAllowsAnotherRun() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["startButton"].tap()

        XCTAssertTrue(app.buttons["retryButton"].waitForExistence(timeout: 15))
        app.buttons["retryButton"].tap()
        XCTAssertTrue(app.staticTexts["scoreLabel"].waitForExistence(timeout: 5))
    }
}
