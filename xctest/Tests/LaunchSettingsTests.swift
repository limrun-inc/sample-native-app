import XCTest

final class LaunchSettingsTests: XCTestCase {
    func testRunnerLaunchSettingsAndAttachment() throws {
        let process = ProcessInfo.processInfo
        XCTAssertTrue(process.arguments.contains("--limrun-runner"))
        XCTAssertTrue(process.arguments.contains("value with spaces"))
        XCTAssertEqual(process.environment["LIMRUN_RUNNER_VALUE"], "value with spaces")
        let configuration = try XCTUnwrap(process.environment["LIMRUN_CONFIGURATION"])
        XCTAssertTrue(["First", "Second"].contains(configuration))
        XCTContext.runActivity(named: "Launch settings: \(configuration)") { activity in
            activity.add(XCTAttachment(string: "Arguments and environment reached the test runner."))
        }
    }

    func testTargetApplicationLaunchSettings() throws {
        let configuration = try XCTUnwrap(ProcessInfo.processInfo.environment["LIMRUN_CONFIGURATION"])
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["Launch argument: app value with spaces"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["Launch environment: \(configuration)"].exists)
        add(XCTAttachment(screenshot: app.screenshot()))
        app.terminate()
    }
}
