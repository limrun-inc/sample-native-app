import XCTest

final class SampleNativeUITests: XCTestCase {
    func testStartAndMoveBetweenLanes() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["startButton"].waitForExistence(timeout: 10))
        app.buttons["startButton"].tap()
        XCTAssertTrue(app.staticTexts["laneIndicator"].waitForExistence(timeout: 5))
        app.buttons["leftButton"].tap()
        XCTAssertEqual(app.staticTexts["laneIndicator"].label, "LANE 1 / 3")
        app.buttons["rightButton"].tap()
        XCTAssertEqual(app.staticTexts["laneIndicator"].label, "LANE 2 / 3")
    }

    func testPauseAndResume() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["startButton"].tap()
        app.buttons["pauseButton"].tap()
        XCTAssertTrue(app.buttons["continueButton"].waitForExistence(timeout: 5))
        app.buttons["continueButton"].tap()
        XCTAssertTrue(app.buttons["pauseButton"].waitForExistence(timeout: 5))
    }

    func testCollisionAndRetry() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["startButton"].tap()
        XCTAssertTrue(app.buttons["restartButton"].waitForExistence(timeout: 15))
        app.buttons["restartButton"].tap()
        XCTAssertTrue(app.buttons["pauseButton"].waitForExistence(timeout: 5))
    }
}
