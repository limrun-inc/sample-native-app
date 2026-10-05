import XCTest

final class SampleNativeUITests: XCTestCase {
    private func launchCleanApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append("-resetTodosForUITests")
        app.launch()
        return app
    }

    func testAddCompleteFilterAndDeleteTask() {
        let app = launchCleanApp()
        XCTAssertTrue(app.staticTexts["A fresh start"].waitForExistence(timeout: 10))

        let input = app.textFields["todoInput"]
        input.tap()
        input.typeText("Buy groceries")
        app.buttons["addTodoButton"].tap()

        XCTAssertTrue(app.staticTexts["Buy groceries"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["1 task on your mind today."].exists)

        app.buttons["Complete Buy groceries"].tap()
        XCTAssertTrue(app.staticTexts["You're all caught up. Enjoy the moment."].exists)

        app.buttons["filterActive"].tap()
        XCTAssertTrue(app.staticTexts["Nothing left to do"].exists)
        app.buttons["filterDone"].tap()
        XCTAssertTrue(app.staticTexts["Buy groceries"].exists)

        app.buttons["Delete Buy groceries"].tap()
        XCTAssertTrue(app.staticTexts["No completed tasks yet"].exists)
    }

    func testTaskPersistsAcrossLaunches() {
        let app = launchCleanApp()
        let input = app.textFields["todoInput"]
        input.tap()
        input.typeText("Read a book")
        app.buttons["addTodoButton"].tap()
        XCTAssertTrue(app.staticTexts["Read a book"].waitForExistence(timeout: 5))

        app.terminate()
        let reopened = XCUIApplication()
        reopened.launch()
        XCTAssertTrue(reopened.staticTexts["Read a book"].waitForExistence(timeout: 10))
    }
}
