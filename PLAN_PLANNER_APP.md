## Plan: PlannerApp audit & test

Audit PlannerApp macOS/iOS code, run XCTests on iPhone 17, and propose frontend/backend improvements for users/devs.

**Steps**
1. Build/test setup: open PlannerApp/README.md for env; ensure Xcode 15+/iOS 17 SDK installed; select simulator iPhone 17; prefer xcodebuild -project PlannerApp/PlannerApp.xcodeproj -scheme PlannerApp -destination 'platform=iOS Simulator,name=iPhone 17'.
2. Run iOS unit/UI tests: xcodebuild test -project PlannerApp/PlannerApp.xcodeproj -scheme PlannerApp -destination 'platform=iOS Simulator,name=iPhone 17'; capture failures; note flaky/slow tests under PlannerApp/PlannerAppTests and PlannerApp/PlannerAppUITests.
3. Run macOS tests (if target present): xcodebuild test -project PlannerApp/PlannerApp.xcodeproj -scheme PlannerApp -destination 'platform=macOS'; compare coverage gaps.
4. Static checks: make lint / make format (SwiftLint/SwiftFormat); review .github/workflows/ci.yml alignment (iPhone 15 currently).
5. Architecture review: read PlannerApp/ARCHITECTURE.md and key files MainApp/PlannerApp.swift, PlannerApp/ContentView.swift; map Models/ViewModels/Views to feature flows (tasks/goals/journal/calendar).
6. Persistence/sync audit: inspect SwiftData models/managers in PlannerApp/DataManagers and CloudKit helpers in PlannerApp/CloudKit; check error handling, conflict resolution, background sync, offline behavior.
7. Services/utilities: review PlannerApp/PlannerApp/Services (timers, analytics), PlannerApp/PlannerApp/Utilities for logging, DI, feature flags.
8. UI/UX pass: scan PlannerApp/Views and PlannerApp/Components for accessibility, theming (PlannerApp/Styling, PlannerApp/Accessibility), performance (large lists), and platform adaptations (macOS vs iOS).
9. Testing gaps: map critical flows (task CRUD, goal progress, sync) to tests; propose new XCTests/UI tests; consider e2e harness in PlannerApp/Tests/e2e/test_plannerapp_wqc.py if used.
10. CI gaps: suggest updating CI destination to iPhone 17, enable lint/format as blockers, add test matrix (iOS + macOS), cache DerivedData.
11. Produce recommendations: frontend (navigation, state management, accessibility, animations), backend (SwiftData schema migrations, CloudKit retries, background tasks), DX (modularization, preview coverage, fixtures, dependency injection).

**Verification**
- iOS tests: xcodebuild test -project PlannerApp/PlannerApp.xcodeproj -scheme PlannerApp -destination 'platform=iOS Simulator,name=iPhone 17'
- macOS tests: xcodebuild test -project PlannerApp/PlannerApp.xcodeproj -scheme PlannerApp -destination 'platform=macOS'
- Lint/format: make lint && make format
- (Optional) Validate pipeline parity with .github/workflows/ci.yml

If you want, I can execute the tests now on iPhone 17 and report failures before drafting detailed improvement recs.
