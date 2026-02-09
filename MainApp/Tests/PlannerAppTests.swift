import XCTest
@testable import MainApp

class PlannerAppTests: XCTestCase {
    var app: PlannerApp!
    var modelContainer: ModelContainer!
    var themeManager: ThemeManager!

    override func setUp() {
        super.setUp()

        // Initialize the shared model container and theme manager
        self.modelContainer = ModelContainer()
        self.themeManager = ThemeManager()

        // Create an instance of the app with a mock selectedTabTag
        self.app = PlannerApp(selectedTabTag: "dashboard")
    }

    override func tearDown() {
        super.tearDown()

        // Clean up any resources if needed
        self.modelContainer = nil
        self.themeManager = nil
        self.app = nil
    }

    func testModelContainerInitialization() {
        XCTAssertNotNil(self.modelContainer, "Model container should not be nil")
    }

    func testThemeManagerInitialization() {
        XCTAssertNotNil(self.themeManager, "Theme manager should not be nil")
    }

    func testAppBodyCreation() {
        let scene = self.app.body as? WindowGroup
        XCTAssertNotNil(scene, "Scene should not be nil")

        if let windowGroup = scene {
            let views = windowGroup.content.children.map { $0 }
            XCTAssertEqual(views.count, 1, "There should be one view in the window group")

            if let overlayView = views.first as? MainTabView {
                XCTAssertEqual(overlayView.selectedTabTag.wrappedValue, "dashboard", "Initial tab tag should be 'dashboard'")
            } else {
                XCTFail("Overlay view is not of type MainTabView")
            }
        }
    }

    func testLegacyDataMigration() {
        // Mock the model context to ensure migration logic is called
        let mockContext = MockModelContext()
        LegacyDataMigrator.migrateIfNeeded(context: mockContext)

        // Verify that the migration logic was called
        XCTAssertTrue(mockContext.didMigrate, "Legacy data migration should have been called")
    }
}

// Mock Model Context for testing
class MockModelContext: NSManagedObjectContext {
    var didMigrate = false

    override func save(_ error: NSErrorPointer) throws {
        self.didMigrate = true
        super.save(error)
    }
}
