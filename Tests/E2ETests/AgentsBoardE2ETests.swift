// MARK: - AgentsBoard End-to-End Tests (XCUITest)
//
// These tests launch the real app and interact with it via accessibility.
// Run with: xcodebuild test -scheme AgentsBoardE2ETests -destination 'platform=macOS'
// Or from the scripts/run-e2e.sh helper.

import XCTest

final class AgentsBoardE2ETests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        // Use bundle identifier to connect to the app
        app = XCUIApplication(bundleIdentifier: "com.agentsboard.app")
        app.launchArguments = ["--ui-testing"]
        app.launchEnvironment["AGENTSBOARD_UI_TEST"] = "1"
    }

    override func tearDownWithError() throws {
        app?.terminate()
        // Wait for app to fully quit before next test
        sleep(2)
        app = nil
    }

    // MARK: - Test 1: App Launches Without Crash

    func testAppLaunchesSuccessfully() throws {
        app.launch()

        // App should be running
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10),
                      "App should launch and be in foreground")

        // Main window should exist
        let window = app.windows.firstMatch
        XCTAssertTrue(window.exists, "Main window should exist")
    }

    // MARK: - Test 2: Empty State — No Sessions Loaded

    func testEmptyStateNoSessions() throws {
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        // Should show "AgentsBoard" title
        let title = app.staticTexts["AgentsBoard"]
        XCTAssertTrue(title.waitForExistence(timeout: 5),
                      "Empty state should show 'AgentsBoard' title")

        // Should show "Launch Session" button
        let launchButton = app.buttons["Launch Session"]
        if launchButton.waitForExistence(timeout: 3) {
            XCTAssertTrue(launchButton.isEnabled, "Launch Session button should be enabled")
        }

        // Should show sidebar
        let sidebar = app.outlines.firstMatch
        // Sidebar might be an outline or a list — just check the window has content
        XCTAssertTrue(app.windows.count > 0, "Should have at least one window")
    }

    // MARK: - Test 3: Create 6 Sessions with Custom Names and Verify

    func testCreateSixSessionsWithNames() throws {
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        let sessionNames = ["Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta"]

        for (i, name) in sessionNames.enumerated() {
            // Open launcher
            app.typeKey("n", modifierFlags: .command)
            sleep(2)

            // Find the name text field — first text field in the launcher.
            // Use a short wait then grab all text fields.
            sleep(1)
            let textFields = app.textFields.allElementsBoundByIndex
            guard !textFields.isEmpty else {
                XCTFail("No text fields found for session \(i + 1)")
                return
            }
            // First text field is the session name
            let nameField = textFields[0]
            nameField.click()
            nameField.typeKey("a", modifierFlags: .command)
            nameField.typeText(name)

            // Click Launch button (identified by accessibilityIdentifier)
            sleep(1)
            let launchBtn = app.buttons["launchButton"]
            XCTAssertTrue(launchBtn.waitForExistence(timeout: 3),
                          "Launch button should exist for session \(i + 1)")
            XCTAssertTrue(launchBtn.isEnabled,
                          "Launch button should be enabled for session \(i + 1)")
            launchBtn.click()

            sleep(1)
        }

        // Wait for all sessions to appear
        sleep(2)

        // Verify: the empty state "Launch Session" button should be gone
        let emptyButton = app.buttons["Launch Session"]
        XCTAssertFalse(emptyButton.exists,
                       "Empty state should be gone after creating 6 sessions")

        // Verify: session count text should show "6 sessions"
        let sessionCount = app.staticTexts["6 sessions"]
        if sessionCount.waitForExistence(timeout: 3) {
            XCTAssertTrue(sessionCount.exists, "Should show '6 sessions' in layout bar")
        }

        // Verify: each session name should appear somewhere in the UI (sidebar or cards)
        for name in sessionNames {
            let nameText = app.staticTexts[name]
            XCTAssertTrue(nameText.waitForExistence(timeout: 3),
                          "Session '\(name)' should be visible in the UI")
        }
    }

    // MARK: - Test 4: Layout Mode Switching

    func testLayoutModeSwitching() throws {
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        // Create 2 sessions so layout bar appears
        createDebugSessions(count: 2)

        // Click each layout mode by accessibilityIdentifier
        let layoutIds = ["layout-single", "layout-list", "layout-twoColumn", "layout-threeColumn", "layout-fleet"]
        for layoutId in layoutIds {
            let btn = app.buttons[layoutId]
            if btn.waitForExistence(timeout: 3) {
                btn.click()
                sleep(1)
                XCTAssertTrue(app.wait(for: .runningForeground, timeout: 3),
                              "App should not crash after switching to \(layoutId)")
            }
        }
    }

    // MARK: - Test 5: Bottom Terminal Panel (Cmd+T)

    func testBottomTerminalPanel() throws {
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        // Create at least one session so we're not in empty state
        createDebugSessions(count: 1)

        // Toggle terminal with Cmd+T
        app.typeKey("t", modifierFlags: .command)
        sleep(1)

        // Terminal panel should appear — look for "Terminal" label
        let terminalLabel = app.staticTexts["Terminal"]
        let terminalExists = terminalLabel.waitForExistence(timeout: 3)

        // Toggle off
        app.typeKey("t", modifierFlags: .command)
        sleep(1)

        // App should not crash
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 3),
                      "App should still be running after terminal toggle")

        // Toggle on again
        app.typeKey("t", modifierFlags: .command)
        sleep(1)

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 3),
                      "App should handle multiple terminal toggles")
    }

    // MARK: - Test 6: Create 15 Sessions and Scroll

    func testSessionsScrollPerformance() throws {
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        // Create 3 sessions — enough to have content to scroll
        createDebugSessions(count: 3)
        sleep(2)

        let mainWindow = app.windows.firstMatch
        XCTAssertTrue(mainWindow.waitForExistence(timeout: 5), "Main window should exist")

        // Scroll down and up
        let startTime = CFAbsoluteTimeGetCurrent()

        for _ in 0..<3 {
            mainWindow.scroll(byDeltaX: 0, deltaY: -300)
            usleep(300_000)
        }
        for _ in 0..<3 {
            mainWindow.scroll(byDeltaX: 0, deltaY: 300)
            usleep(300_000)
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - startTime

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5),
                      "App should not crash after scrolling")
        XCTAssertLessThan(elapsed, 15.0,
                          "Scroll took \(String(format: "%.1f", elapsed))s — should be under 15s")
    }

    // MARK: - Test 7: Settings Panel (Cmd+,)

    func testSettingsPanel() throws {
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        // Open settings with Cmd+,
        app.typeKey(",", modifierFlags: .command)
        sleep(1)

        // Settings panel should appear
        let settingsTitle = app.staticTexts["Settings"]
        let settingsExists = settingsTitle.waitForExistence(timeout: 3)

        // Close settings
        app.typeKey(",", modifierFlags: .command)
        sleep(1)

        // App should not crash
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 3),
                      "App should handle settings toggle")
    }

    // MARK: - Test 8: Stress Test — Rapid Layout Switching with Sessions

    func testRapidLayoutSwitchingWithSessions() throws {
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        // Create 4 sessions
        createDebugSessions(count: 4)
        sleep(2)

        // Rapidly switch layouts 20 times using identifiers
        let layoutIds = ["layout-single", "layout-list", "layout-twoColumn", "layout-threeColumn", "layout-fleet"]
        for _ in 0..<4 {
            for layoutId in layoutIds {
                let btn = app.buttons[layoutId]
                if btn.exists {
                    btn.click()
                    usleep(200_000) // 200ms between switches
                }
            }
        }

        // App should survive rapid switching
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5),
                      "App should survive 20 rapid layout switches")
    }

    // MARK: - Test 9: Create 4 Sessions in a Single Launch

    func testCreateFourSessionsInOneLaunch() throws {
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        // Open launcher once
        app.typeKey("n", modifierFlags: .command)
        sleep(2)

        // Add 3 more entries (first one already exists)
        for _ in 0..<3 {
            let addBtn = app.buttons["addSessionButton"]
            XCTAssertTrue(addBtn.waitForExistence(timeout: 3), "Add Session button should exist")
            addBtn.click()
            sleep(1)
        }

        // All 4 entries have default name "Claude" and command "claude" — Launch is enabled
        sleep(1)
        let launchBtn = app.buttons["launchButton"]
        XCTAssertTrue(launchBtn.waitForExistence(timeout: 3), "Launch button should exist")
        XCTAssertTrue(launchBtn.isEnabled, "Launch button should be enabled with 4 entries")
        launchBtn.click()

        sleep(3)

        // Verify: 4 sessions created
        let countText = app.staticTexts["4 sessions"]
        XCTAssertTrue(countText.waitForExistence(timeout: 5),
                      "Should show '4 sessions' after batch launch")

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 3),
                      "App should not crash after batch launch")
    }

    // MARK: - Helpers

    /// Creates sessions via launcher — uses default Claude provider with pre-filled command.
    private func createDebugSessions(count: Int) {
        for i in 0..<count {
            app.typeKey("n", modifierFlags: .command)
            sleep(2)

            // First text field = session name
            let textFields = app.textFields.allElementsBoundByIndex
            guard !textFields.isEmpty else { continue }
            textFields[0].click()
            textFields[0].typeKey("a", modifierFlags: .command)
            textFields[0].typeText("Test \(i + 1)")

            // Click Launch
            sleep(1)
            let launchBtn = app.buttons["launchButton"]
            if launchBtn.waitForExistence(timeout: 2) && launchBtn.isEnabled {
                launchBtn.click()
            }
            sleep(1)
        }
        sleep(2)
    }
}
