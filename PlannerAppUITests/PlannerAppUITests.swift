//
//  PlannerAppUITests.swift
//  PlannerAppUITests
//
//  Comprehensive visual regression testing with screenshot capture
//

import XCTest

final class PlannerAppUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
        
        // Wait for app to fully load
        sleep(2)
    }

    override func tearDownWithError() throws {
        // Cleanup if needed
    }
    
    // MARK: - Helper Functions
    
    /// Captures a screenshot with a descriptive name
    private func captureScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    /// Safely tap a navigation element
    private func tapElement(_ identifier: String) -> Bool {
        let element = app.buttons[identifier].firstMatch
        if element.exists && element.isHittable {
            element.tap()
            sleep(1)
            return true
        }
        return false
    }
    
    /// Safely tap a tab bar button if it exists
    private func tapTab(_ tabName: String) -> Bool {
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            let tab = tabBar.buttons[tabName].firstMatch
            if tab.exists {
                tab.tap()
                sleep(1)
                return true
            }
        }
        return false
    }

    // MARK: - Launch Tests
    
    @MainActor
    func testAppLaunchScreenshot() throws {
        // Capture initial launch state
        captureScreenshot(named: "Launch_Main")
        
        // Verify app launched
        XCTAssertTrue(app.state == .runningForeground, "App should be running")
    }

    // MARK: - Main Navigation Screenshots
    
    @MainActor
    func testMainNavigationScreenshots() throws {
        // Capture the main view
        captureScreenshot(named: "MainView_Initial")
        
        // Look for common planner navigation elements
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            let tabs = tabBar.buttons.allElementsBoundByIndex
            for (index, tab) in tabs.enumerated() {
                tab.tap()
                sleep(1)
                captureScreenshot(named: String(format: "Tab%02d_%@", index + 1, tab.label))
            }
        }
    }
    
    // MARK: - Today View Screenshots
    
    @MainActor
    func testTodayViewScreenshots() throws {
        // Try navigating to Today view
        if tapTab("Today") || tapElement("Today") {
            captureScreenshot(named: "Today_Main")
            
            // Scroll if there's content
            let scrollView = app.scrollViews.firstMatch
            if scrollView.exists {
                scrollView.swipeUp()
                sleep(1)
                captureScreenshot(named: "Today_Scrolled")
            }
        } else {
            // Capture whatever is showing
            captureScreenshot(named: "Today_DefaultView")
        }
    }
    
    // MARK: - Calendar View Screenshots
    
    @MainActor
    func testCalendarViewScreenshots() throws {
        // Try navigating to Calendar view
        if tapTab("Calendar") || tapElement("Calendar") {
            captureScreenshot(named: "Calendar_Main")
            
            // Try navigating to next month if possible
            let nextButton = app.buttons["chevron.right"].firstMatch
            if nextButton.exists {
                nextButton.tap()
                sleep(1)
                captureScreenshot(named: "Calendar_NextMonth")
            }
        }
    }
    
    // MARK: - Tasks/Items View Screenshots
    
    @MainActor
    func testTasksViewScreenshots() throws {
        // Try navigating to Tasks/Items view
        let taskNavItems = ["Tasks", "Items", "All Tasks", "To Do", "List"]
        
        for navItem in taskNavItems {
            if tapTab(navItem) || tapElement(navItem) {
                captureScreenshot(named: "Tasks_Main")
                
                // Look for empty state
                let emptyLabels = app.staticTexts.matching(
                    NSPredicate(format: "label CONTAINS[c] 'no tasks' OR label CONTAINS[c] 'empty' OR label CONTAINS[c] 'add'")
                ).allElementsBoundByIndex
                
                if emptyLabels.count > 0 {
                    captureScreenshot(named: "Tasks_EmptyState")
                }
                break
            }
        }
    }
    
    // MARK: - Add Task Flow Screenshots
    
    @MainActor
    func testAddTaskFlowScreenshots() throws {
        // Try to open add task sheet/view
        let addButtons = ["+", "Add", "Add Task", "plus", "New Task", "Create"]
        
        for buttonName in addButtons {
            if tapElement(buttonName) {
                captureScreenshot(named: "AddTask_Sheet")
                
                // Check for form fields
                let titleField = app.textFields.firstMatch
                if titleField.exists {
                    captureScreenshot(named: "AddTask_Form")
                }
                
                // Try to dismiss
                _ = tapElement("Cancel") || tapElement("Close")
                break
            }
        }
    }
    
    // MARK: - Settings View Screenshots
    
    @MainActor
    func testSettingsViewScreenshots() throws {
        // Try navigating to Settings/More
        let settingsItems = ["Settings", "More", "gear", "Preferences", "Options"]
        
        for item in settingsItems {
            if tapTab(item) || tapElement(item) {
                captureScreenshot(named: "Settings_Main")
                
                // Scroll settings
                let scrollView = app.scrollViews.firstMatch
                if scrollView.exists {
                    scrollView.swipeUp()
                    sleep(1)
                    captureScreenshot(named: "Settings_Scrolled")
                }
                break
            }
        }
    }
    
    // MARK: - Full App Tour Screenshots
    
    @MainActor
    func testFullAppScreenshotTour() throws {
        // Comprehensive screenshot tour of the app
        
        // 1. Launch
        captureScreenshot(named: "Tour_01_Launch")
        
        // 2. Try different main views
        let viewsToCapture = ["Today", "Calendar", "Tasks", "All", "Settings"]
        var viewIndex = 2
        
        for viewName in viewsToCapture {
            if tapTab(viewName) || tapElement(viewName) {
                captureScreenshot(named: String(format: "Tour_%02d_%@", viewIndex, viewName))
                viewIndex += 1
            }
        }
        
        // Final screenshot
        captureScreenshot(named: "Tour_Final")
    }
    
    // MARK: - Accessibility Verification
    
    @MainActor
    func testAccessibilityLabelsExist() throws {
        captureScreenshot(named: "Accessibility_Verification")
        
        // Check buttons have labels
        let buttons = app.buttons.allElementsBoundByIndex
        var labeledButtonCount = 0
        for button in buttons.prefix(10) {
            if button.isHittable && !(button.label.isEmpty) {
                labeledButtonCount += 1
            }
        }
        XCTAssertGreaterThan(labeledButtonCount, 0, "Should have buttons with accessibility labels")
    }
    
    // MARK: - Performance Tests

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
