//
//  LibraryViewStory23IntegrationTests.swift
//  AuditLabTests
//
//  ATDD Integration tests for Story 2-3: View Library as List or Grid.
//  Covers AC1 (list/grid with title) and AC2 (empty state) via LibStore and persistence.
//  Uses real in-memory Core Data — no mocks.
//

import XCTest
import CoreData
@testable import AuditLab

@MainActor
final class LibraryViewStory23IntegrationTests: XCTestCase {

    private var controller: PersistenceController!
    private var repo: DocumentRepository!
    private var lib: LibStore!

    override func setUp() {
        super.setUp()
        controller = PersistenceController(inMemory: true)
        repo = DocumentRepository(persistenceController: controller)
        lib = LibStore(repository: repo)
    }

    override func tearDown() {
        lib = nil
        repo = nil
        controller = nil
        super.tearDown()
    }

    // MARK: - AC1: Documents shown in list/grid with title

    /// Given one document in library, LibStore.recs reflects it with correct title.
    func testLibraryWithOneDocumentShowsOneRecordWithTitle() throws {
        // GIVEN: One document in persistence
        let id = UUID()
        try repo.addDocument(identity: id, title: "My First Paper", addedAt: Date(), fileReference: nil)
        lib.reloadFromContext()

        // THEN: recs has one item with that title
        XCTAssertEqual(lib.recs.count, 1)
        XCTAssertEqual(lib.recs.first?.title, "My First Paper")
    }

    /// Given multiple documents, LibStore.recs reflects all with titles.
    func testLibraryWithMultipleDocumentsShowsAllWithTitles() throws {
        try repo.addDocument(identity: UUID(), title: "Paper A", addedAt: Date(), fileReference: nil)
        try repo.addDocument(identity: UUID(), title: "Paper B", addedAt: Date(), fileReference: nil)
        try repo.addDocument(identity: UUID(), title: "Paper C", addedAt: Date(), fileReference: nil)
        lib.reloadFromContext()

        XCTAssertEqual(lib.recs.count, 3)
        let titles = Set(lib.recs.map(\.title))
        XCTAssertEqual(titles, ["Paper A", "Paper B", "Paper C"])
    }

    /// Document with empty title still appears in recs (fallback is app responsibility).
    func testDocumentWithEmptyTitleStillAppearsInRecs() throws {
        try repo.addDocument(identity: UUID(), title: "", addedAt: Date(), fileReference: nil)
        lib.reloadFromContext()

        XCTAssertEqual(lib.recs.count, 1)
        XCTAssertEqual(lib.recs.first?.title, "")
    }

    /// LibStore.recs reflects persisted documents after reload (data integrity).
    func testLibStoreRecsReflectsPersistedDocumentsAfterReload() throws {
        let id = UUID()
        try repo.addDocument(identity: id, title: "Persisted Doc", addedAt: Date(), fileReference: nil)

        lib.reloadFromContext()
        XCTAssertEqual(lib.recs.count, 1)
        XCTAssertEqual(lib.recs.first?.id, id.uuidString)
        XCTAssertEqual(lib.recs.first?.title, "Persisted Doc")
    }

    // MARK: - AC2: Empty state (data side)

    /// Empty library: recs is empty so UI can show empty state.
    func testEmptyLibraryRecsIsEmpty() throws {
        lib.reloadFromContext()
        XCTAssertTrue(lib.recs.isEmpty)
    }

    /// Adding a document to empty library removes empty state (recs non-empty).
    /// Note: Uses lib.add(PaperRec) only; does not exercise the full add-from-file path (Story 2-3 is display-only).
    func testAddingDocumentToEmptyLibraryMakesRecsNonEmpty() throws {
        XCTAssertTrue(lib.recs.isEmpty)

        lib.add(PaperRec(id: UUID().uuidString, title: "New Doc", auths: [], date: nil, addedAt: Date(), isRead: false))
        lib.reloadFromContext()

        XCTAssertEqual(lib.recs.count, 1)
    }

    /// Deleting last document makes recs empty again (empty state can show).
    func testDeletingLastDocumentMakesRecsEmpty() throws {
        try repo.addDocument(identity: UUID(), title: "Only One", addedAt: Date(), fileReference: nil)
        lib.reloadFromContext()
        XCTAssertEqual(lib.recs.count, 1)

        let rec = lib.recs.first!
        lib.delete(rec)
        lib.reloadFromContext()

        XCTAssertTrue(lib.recs.isEmpty)
    }
}
