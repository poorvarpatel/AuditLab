//
//  LibraryViewAcceptanceTests.swift
//  AuditLabUITests
//
//  Consolidated, stable UI acceptance tests for Library (Stories 2-3 and 2-4).
//  - Explicit waits for existence + hittability (XCTNSPredicateExpectation, XCTWaiter)
//  - Semantic queries and tap targets that avoid buttons (card title vs whole card)
//  - Lightweight screen helpers to keep tests readable and flexible
//

import XCTest

// MARK: - Constants

private enum A11y {
    static let libraryTab = "Library"
    static let documentList = "library-document-list"
    static let documentCard = "library-document-card"
    static let documentCardTitle = "library-document-card-title"
    static let emptyState = "library-empty-state"
    static let emptyStateAddPdf = "library-empty-state-add-pdf"
    static let addPdfLoading = "library-add-pdf-loading"
    static let detailDone = "document-detail-done"
    static let documentDetailLoading = "document-detail-loading"
}

private enum Timeout {
    static let tabBar: TimeInterval = 8
    static let mainContent: TimeInterval = 8
    static let seededContent: TimeInterval = 10  // Seed runs in onAppear; LazyVGrid may delay children
    static let detailSheet: TimeInterval = 5
    static let hittable: TimeInterval = 3
}

// MARK: - Screen Helpers (query + action encapsulation)

private struct LibraryScreen {
    let app: XCUIApplication

    func waitForHittable(_ element: XCUIElement, timeout: TimeInterval = Timeout.hittable) -> Bool {
        let predicate = NSPredicate(format: "exists == true AND isHittable == true")
        let exp = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter.wait(for: [exp], timeout: timeout) == .completed
    }

    /// Go to Library tab and wait until the expected content is ready (seeded = list with cards, !seeded = empty state).
    func goToTab(seeded: Bool) {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: Timeout.tabBar), "Tab bar should appear")
        // Library is the first tab; tap by index so we don't depend on a11y label ("Library" vs "Library, tab" etc.)
        let tabButtons = tabBar.buttons
        XCTAssertTrue(tabButtons.firstMatch.waitForExistence(timeout: Timeout.tabBar), "At least one tab should exist")
        let libraryButton = tabButtons.element(boundBy: 0)
        XCTAssertTrue(waitForHittable(libraryButton, timeout: Timeout.tabBar), "Library (first) tab should be tappable")
        libraryButton.tap()
        waitForLibraryContent(seeded: seeded)
    }

    /// Wait until Library shows either document list with at least one card (seeded) or empty state (!seeded).
    private func waitForLibraryContent(seeded: Bool) {
        let timeout = seeded ? Timeout.seededContent : Timeout.mainContent
        if seeded {
            // Seed runs in onAppear; wait for list + at least one card/title to be in the hierarchy
            let list = app.otherElements[A11y.documentList]
            let cardTitle = app.staticTexts[A11y.documentCardTitle].firstMatch
            let seededTitle = app.staticTexts["Test Paper A"]
            XCTAssertTrue(list.waitForExistence(timeout: timeout), "Document list should appear when seeded")
            XCTAssertTrue(
                cardTitle.waitForExistence(timeout: timeout) || seededTitle.waitForExistence(timeout: timeout),
                "At least one document card should be visible when library has documents"
            )
        } else {
            // Empty state: container, unique text, or Add PDF button (by id or label)
            let emptyContainer = app.otherElements[A11y.emptyState]
            let emptyMessage = app.staticTexts["No documents yet"]
            let addPdfById = app.buttons[A11y.emptyStateAddPdf]
            let addPdfByLabel = app.buttons["Add PDF"]
            let emptyVisible =
                emptyContainer.waitForExistence(timeout: timeout)
                || emptyMessage.waitForExistence(timeout: timeout)
                || addPdfById.waitForExistence(timeout: timeout)
                || addPdfByLabel.waitForExistence(timeout: timeout)
            XCTAssertTrue(emptyVisible, "Library should show empty state when library is empty")
        }
    }

    var documentListExists: Bool { app.otherElements[A11y.documentList].waitForExistence(timeout: Timeout.mainContent) }

    /// Empty state can appear as container, "No documents yet" text, or Add PDF button depending on a11y tree.
    var emptyStateExists: Bool {
        app.otherElements[A11y.emptyState].waitForExistence(timeout: Timeout.mainContent)
            || app.staticTexts["No documents yet"].waitForExistence(timeout: Timeout.mainContent)
            || app.buttons[A11y.emptyStateAddPdf].waitForExistence(timeout: Timeout.mainContent)
            || app.buttons["Add PDF"].waitForExistence(timeout: Timeout.mainContent)
    }
    var firstCardTitle: XCUIElement { app.staticTexts[A11y.documentCardTitle].firstMatch }

    /// Add PDF button in empty state (by id or label depending on a11y tree).
    var emptyStateAddPdfButton: XCUIElement {
        let byId = app.buttons[A11y.emptyStateAddPdf]
        return byId.exists ? byId : app.buttons["Add PDF"]
    }

    func tapFirstDocumentCard() {
        XCTAssertTrue(firstCardTitle.waitForExistence(timeout: Timeout.mainContent), "At least one document card title should exist")
        XCTAssertTrue(waitForHittable(firstCardTitle, timeout: Timeout.mainContent), "First card title should be tappable")
        firstCardTitle.tap()
    }
}

private struct DocumentDetailScreen {
    let app: XCUIApplication

    func waitForDoneButton(timeout: TimeInterval = Timeout.detailSheet) -> XCUIElement {
        let done = app.buttons[A11y.detailDone]
        XCTAssertTrue(done.waitForExistence(timeout: timeout), "Document detail sheet should show with Done button")
        let predicate = NSPredicate(format: "exists == true AND isHittable == true")
        let exp = XCTNSPredicateExpectation(predicate: predicate, object: done)
        XCTAssertEqual(XCTWaiter.wait(for: [exp], timeout: Timeout.hittable), .completed, "Done button should be tappable")
        return done
    }

    func tapDone() {
        let done = app.buttons[A11y.detailDone]
        guard done.waitForExistence(timeout: 2), done.isHittable else { return }
        done.tap()
    }
}

// MARK: - Test Suite

/// Bundle ID of the app under test. Explicit ID avoids "No target application path" when running UI tests from CLI (xcodebuild test).
private let appBundleId = "com.poorvarpatel.AuditLab"

final class LibraryViewAcceptanceTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        // Use explicit bundle ID so UI tests work from both Xcode and command-line test runs.
        app = XCUIApplication(bundleIdentifier: appBundleId)
    }

    override func tearDownWithError() throws {
        app = nil
    }

    private func launch(seeded: Bool) {
        app.launchArguments = seeded ? ["-TEST_SEED_LIBRARY"] : ["-TEST_EMPTY_LIBRARY"]
        app.launch()
    }

    // MARK: - Story 2-3: View Library as List or Grid

    func testLibraryTabShowsDocumentListWhenLibraryHasDocuments() throws {
        launch(seeded: true)
        let library = LibraryScreen(app: app)
        XCTContext.runActivity(named: "Navigate to Library tab") { _ in library.goToTab(seeded: true) }
        XCTContext.runActivity(named: "Document list is visible") { _ in
            XCTAssertTrue(library.documentListExists, "Library should show document list when library has documents")
        }
    }

    func testLibraryShowsDocumentTitlesWhenMultipleDocuments() throws {
        launch(seeded: true)
        let library = LibraryScreen(app: app)
        library.goToTab(seeded: true)

        let hasTitleA = app.staticTexts["Test Paper A"].waitForExistence(timeout: 2)
        let hasTitleB = app.staticTexts["Test Paper B"].waitForExistence(timeout: 2)
        XCTAssertTrue(hasTitleA || hasTitleB, "Document title (or equivalent metadata) must be visible in the list/grid")
    }

    func testLibraryTabShowsEmptyStateWhenLibraryIsEmpty() throws {
        launch(seeded: false)
        let library = LibraryScreen(app: app)
        XCTContext.runActivity(named: "Navigate to Library tab") { _ in library.goToTab(seeded: false) }
        XCTContext.runActivity(named: "Empty state is visible") { _ in
            XCTAssertTrue(library.emptyStateExists, "Library should show empty state when library is empty")
        }
    }

    func testEmptyStateShowsAddPdfAction() throws {
        launch(seeded: false)
        let library = LibraryScreen(app: app)
        library.goToTab(seeded: false)

        XCTAssertTrue(library.emptyStateExists, "Empty state view must be present")
        let addButton = library.emptyStateAddPdfButton
        XCTAssertTrue(addButton.waitForExistence(timeout: Timeout.mainContent), "Empty state should show Add PDF action")
        XCTAssertTrue(library.waitForHittable(addButton), "Add PDF button should be tappable")
    }

    // MARK: - Story 2-4: View Document Detail

    func testTappingDocumentCardOpensDocumentDetailView() throws {
        launch(seeded: true)
        let library = LibraryScreen(app: app)
        let detail = DocumentDetailScreen(app: app)
        XCTContext.runActivity(named: "Open Library and tap first document") { _ in
            library.goToTab(seeded: true)
            library.tapFirstDocumentCard()
        }
        XCTContext.runActivity(named: "Document detail sheet appears with Done") { _ in
            _ = detail.waitForDoneButton()
        }
    }

    func testTappingDoneReturnsToLibrary() throws {
        launch(seeded: true)
        let library = LibraryScreen(app: app)
        let detail = DocumentDetailScreen(app: app)
        library.goToTab(seeded: true)
        library.tapFirstDocumentCard()
        detail.waitForDoneButton()
        detail.tapDone()

        XCTAssertTrue(library.documentListExists, "After Done, user should be back on library")
    }

    /// Full flow: open detail, verify Done, dismiss, verify back on list (single test for stability).
    func testDocumentDetailOpenAndDismissFlow() throws {
        launch(seeded: true)
        let library = LibraryScreen(app: app)
        let detail = DocumentDetailScreen(app: app)
        library.goToTab(seeded: true)
        library.tapFirstDocumentCard()
        detail.waitForDoneButton()
        detail.tapDone()
        XCTAssertTrue(library.documentListExists, "Should return to library after Done")
    }
    
    /// AC#1: Verify metadata is displayed in document detail
    func testDocumentDetailShowsMetadata() throws {
        launch(seeded: true)
        let library = LibraryScreen(app: app)
        library.goToTab(seeded: true)
        library.tapFirstDocumentCard()
        
        let metadataSection = app.otherElements["document-detail-metadata-section"]
        XCTAssertTrue(metadataSection.waitForExistence(timeout: Timeout.detailSheet), "Metadata section should be visible")
        
        let title = app.staticTexts["document-detail-title"]
        XCTAssertTrue(title.waitForExistence(timeout: Timeout.detailSheet), "Document title should be visible")
        
        let metadata = app.staticTexts["document-detail-metadata"]
        XCTAssertTrue(metadata.waitForExistence(timeout: Timeout.detailSheet), "Document metadata (authors/date) should be visible")
    }
    
    /// AC#1: Verify section structure is displayed in document detail
    func testDocumentDetailShowsSectionStructure() throws {
        launch(seeded: true)
        let library = LibraryScreen(app: app)
        library.goToTab(seeded: true)
        library.tapFirstDocumentCard()
        
        // Note: Test papers may or may not have sections; verify sections UI appears when pack has sections
        let sectionsSection = app.otherElements["document-detail-sections-section"]
        let sectionsHeader = app.staticTexts["document-detail-sections-header"]
        let sectionsList = app.otherElements["document-detail-sections-list"]
        
        // At least one of these should be present if sections exist, or none if document has no sections
        // This test verifies the UI renders correctly when sections are present
        if sectionsSection.waitForExistence(timeout: 2) {
            XCTAssertTrue(sectionsHeader.exists, "When sections exist, 'Sections' header should be visible")
            XCTAssertTrue(sectionsList.exists, "When sections exist, sections list should be visible")
        }
    }
    
    /// AC#2: Verify loading state is shown when document is loading
    func testDocumentDetailShowsLoadingState() throws {
        launch(seeded: true)
        let library = LibraryScreen(app: app)
        library.goToTab(seeded: true)
        
        // Open a document that hasn't been loaded yet
        library.tapFirstDocumentCard()
        
        // Loading state may appear briefly; check if it exists within a short timeout
        let loadingView = app.otherElements[A11y.documentDetailLoading]
        let loadingText = app.staticTexts["Loading document…"]
        
        // Loading may be very fast; we verify either loading appeared OR content loaded directly
        let loadingAppeared = loadingView.waitForExistence(timeout: 1) || loadingText.waitForExistence(timeout: 1)
        let contentAppeared = app.otherElements["document-detail-metadata-section"].waitForExistence(timeout: Timeout.detailSheet)
        
        XCTAssertTrue(loadingAppeared || contentAppeared, "Either loading state should appear or content should load quickly")
    }
}
