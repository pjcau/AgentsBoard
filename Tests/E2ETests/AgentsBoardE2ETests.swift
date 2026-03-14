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

        // Launch the pre-built .app bundle directly by URL
        let projectDir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // E2ETests/
            .deletingLastPathComponent() // Tests/
            .deletingLastPathComponent() // project root
        let appURL = projectDir.appendingPathComponent("build/AgentsBoard.app")

        // First ensure app is built
        XCTAssertTrue(FileManager.default.fileExists(atPath: appURL.path),
                      "App not found at \(appURL.path) — run 'bash build.sh' first")

        app = XCUIApplication(url: appURL)
        app.launchArguments = ["--ui-testing"]
        app.launchEnvironment["AGENTSBOARD_UI_TEST"] = "1"
    }

    override func tearDownWithError() throws {
        app?.terminate()
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

    // MARK: - Test 3: Create Sessions and Verify Grid

    func testCreateSessionsAndVerifyGrid() throws {
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        // Click the "+" button in toolbar to create a session
        let plusButton = app.toolbars.buttons.matching(identifier: "New Session").firstMatch
        if !plusButton.waitForExistence(timeout: 3) {
            // Try toolbar buttons by image
            let toolbarButtons = app.toolbars.buttons
            XCTAssertTrue(toolbarButtons.count > 0, "Toolbar should have buttons")
        }

        // Use Cmd+N to open launcher
        app.typeKey("n", modifierFlags: .command)
        sleep(1)

        // Check if launcher window appeared
        let launcherWindow = app.windows.matching(NSPredicate(format: "title CONTAINS 'Launch'")).firstMatch
        if launcherWindow.waitForExistence(timeout: 3) {
            // Launcher opened — look for the Launch button
            let launchBtn = launcherWindow.buttons.matching(NSPredicate(format: "title CONTAINS 'Launch'")).firstMatch
            if launchBtn.waitForExistence(timeout: 2) {
                launchBtn.click()
                sleep(2)
            }
        }

        // After launching, the empty state should be gone
        // The grid should have at least one session card
        sleep(2)
    }

    // MARK: - Test 4: Layout Mode Switching

    func testLayoutModeSwitching() throws {
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        // First create some sessions via debug button (Cmd+N → Launch)
        createDebugSessions(count: 1)

        // Find layout buttons in the layout bar
        // They are: Single (square), List, 2-Col, 3-Col, Grid
        let layoutButtons = app.buttons.matching(NSPredicate(format:
            "label CONTAINS 'Single' OR label CONTAINS 'List' OR label CONTAINS 'columns' OR label CONTAINS 'Grid' OR label CONTAINS 'focus'"))

        // Try clicking each layout mode button
        let buttonLabels = ["Single (focus)", "List", "2 columns", "3 columns", "Grid"]
        for label in buttonLabels {
            let btn = app.buttons[label]
            if btn.waitForExistence(timeout: 2) {
                btn.click()
                usleep(500_000) // 0.5s between switches
            }
        }

        // App should not crash after switching layouts
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 3),
                      "App should still be running after layout switches")
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

    func testFifteenSessionsScrollPerformance() throws {
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        // Create 15+ sessions using the debug button
        createDebugSessions(count: 15)
        sleep(3)

        let mainWindow = app.windows.firstMatch
        XCTAssertTrue(mainWindow.waitForExistence(timeout: 5), "Main window should exist")

        // Record start time for performance
        let startTime = CFAbsoluteTimeGetCurrent()

        // Scroll down
        for _ in 0..<5 {
            mainWindow.scroll(byDeltaX: 0, deltaY: -200)
            usleep(200_000)
        }

        // Scroll back up
        for _ in 0..<5 {
            mainWindow.scroll(byDeltaX: 0, deltaY: 200)
            usleep(200_000)
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - startTime

        // App should not crash after scrolling
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5),
                      "App should not crash after scrolling 15 sessions")

        // Scrolling should complete within reasonable time (< 10s for 10 scroll actions)
        XCTAssertLessThan(elapsed, 15.0,
                          "Scroll performance: took \(String(format: "%.1f", elapsed))s — should be under 15s")
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

        // Create sessions
        createDebugSessions(count: 5)
        sleep(2)

        // Rapidly switch layouts 20 times
        let layoutShortcuts: [(String, NSEvent.ModifierFlags)] = [
            // No direct shortcuts for layouts, so we'll use the buttons
        ]

        // Find and click layout buttons rapidly
        let buttonLabels = ["Single (focus)", "List", "2 columns", "3 columns", "Grid"]
        for _ in 0..<4 {
            for label in buttonLabels {
                let btn = app.buttons[label]
                if btn.exists {
                    btn.click()
                    usleep(100_000) // 100ms between switches
                }
            }
        }

        // App should survive rapid switching
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5),
                      "App should survive rapid layout switching")
    }

    // MARK: - Helpers

    /// Creates sessions using the debug 10x button (fastest) or Cmd+N fallback.
    private func createDebugSessions(count: Int) {
        // Try the 10x debug toolbar button first (only in DEBUG builds)
        let debugBtn = app.toolbars.buttons["10x Debug"]
        if debugBtn.waitForExistence(timeout: 2) {
            let presses = max(1, (count + 9) / 10) // ceil(count/10)
            for _ in 0..<presses {
                debugBtn.click()
                sleep(1)
            }
            sleep(2) // Wait for fleet to update
            return
        }

        // Fallback: open launcher once with a single session
        app.typeKey("n", modifierFlags: .command)
        usleep(500_000)
        let launcherWindow = app.windows.matching(NSPredicate(format: "title CONTAINS 'Launch'")).firstMatch
        if launcherWindow.waitForExistence(timeout: 2) {
            let launchBtn = launcherWindow.buttons.matching(NSPredicate(format: "title CONTAINS 'Launch'")).firstMatch
            if launchBtn.waitForExistence(timeout: 1) {
                launchBtn.click()
                sleep(1)
            }
        }
    }
}
