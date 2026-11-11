import XCTest

final class SampleNativeUITests: XCTestCase {
    func testGreetingIsVisible() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["Hello, world!"].waitForExistence(timeout: 10))
    }

    func testGreetsByName() {
        let app = XCUIApplication()
        app.launch()
        let field = app.textFields["nameField"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("Ada")
        app.buttons["greetButton"].tap()
        XCTAssertTrue(app.staticTexts["Hello, Ada!"].waitForExistence(timeout: 5))

        // Attachments end up in the result bundle of a `--result-bundle` run.
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "greeting"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
