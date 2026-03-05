//
//  DocumentDeleteCascadeTests.swift
//  AuditLabTests
//
//  Tests for Story 2.5: Remove Document from Library (with Cascade)
//  Verifies cascade delete behavior, referential integrity, and nil document handling.
//

import XCTest
import CoreData
@testable import AuditLab

final class DocumentDeleteCascadeTests: XCTestCase {

    private var controller: PersistenceController!
    private var repo: DocumentRepository!

    override func setUp() {
        super.setUp()
        controller = PersistenceController(inMemory: true)
        repo = DocumentRepository(persistenceController: controller)
    }

    override func tearDown() {
        repo = nil
        controller = nil
        super.tearDown()
    }

    // MARK: - Cascade Delete Tests

    func testDeleteDocument_cascadesDocumentFolderRelationships() throws {
        // Given: Document added to two folders
        try repo.addDocument(identity: UUID(), title: "Test Doc", addedAt: Date(), fileReference: nil)
        try repo.addFolder(identity: UUID(), name: "Folder A", createdAt: Date())
        try repo.addFolder(identity: UUID(), name: "Folder B", createdAt: Date())

        let doc = try repo.fetchDocuments().first!
        let folderA = try repo.fetchFolders().first { $0.name == "Folder A" }!
        let folderB = try repo.fetchFolders().first { $0.name == "Folder B" }!

        try repo.addDocumentToFolder(document: doc, folder: folderA)
        try repo.addDocumentToFolder(document: doc, folder: folderB)

        // Verify document is in both folders
        XCTAssertEqual(try repo.fetchDocumentsInFolder(folderA).count, 1)
        XCTAssertEqual(try repo.fetchDocumentsInFolder(folderB).count, 1)

        // When: Document is deleted
        try repo.deleteDocument(doc)
        controller.viewContext.refreshAllObjects()

        // Then: Document is removed from all folders (cascade delete of DocumentFolder entities)
        XCTAssertEqual(try repo.fetchDocumentsInFolder(folderA).count, 0)
        XCTAssertEqual(try repo.fetchDocumentsInFolder(folderB).count, 0)

        // Verify folders still exist
        XCTAssertEqual(try repo.fetchFolders().count, 2)
    }

    func testDeleteDocument_nullifiesQueueEntryRelationships() throws {
        // Given: Document with queue entries
        let docId = UUID()
        try repo.addDocument(identity: docId, title: "Test Doc", addedAt: Date(), fileReference: nil)
        let doc = try repo.fetchDocuments().first!
        let paperId = doc.identity?.uuidString ?? docId.uuidString

        try repo.addQueueEntry(
            identity: UUID(),
            paperId: paperId,
            orderIndex: 0,
            secOn: [],
            incApp: true,
            incSum: true,
            document: doc
        )
        try repo.addQueueEntry(
            identity: UUID(),
            paperId: paperId,
            orderIndex: 1,
            secOn: [],
            incApp: true,
            incSum: true,
            document: doc
        )

        var entries = try repo.fetchQueueEntries()
        XCTAssertEqual(entries.count, 2)
        XCTAssertNotNil(entries[0].document)
        XCTAssertNotNil(entries[1].document)

        // When: Document is deleted
        try repo.deleteDocument(doc)
        controller.viewContext.refreshAllObjects()

        // Then: Queue entries remain but document reference is nullified
        entries = try repo.fetchQueueEntries()
        XCTAssertEqual(entries.count, 2, "Queue entries should remain after document delete")
        XCTAssertNil(entries[0].document, "QueueEntry.document should be nil after document delete")
        XCTAssertNil(entries[1].document, "QueueEntry.document should be nil after document delete")

        // paperId string should still be present
        XCTAssertEqual(entries[0].paperId, paperId)
        XCTAssertEqual(entries[1].paperId, paperId)
    }

    func testDeleteDocument_nullifiesHistoryItemRelationships() throws {
        // Given: Document with history entries
        try repo.addDocument(identity: UUID(), title: "Test Doc", addedAt: Date(), fileReference: nil)
        let doc = try repo.fetchDocuments().first!

        try repo.saveHistoryEntry(document: doc, playedAt: Date(), lastSentenceId: "sent-1", durationSeconds: 120)
        try repo.saveHistoryEntry(document: doc, playedAt: Date().addingTimeInterval(60), lastSentenceId: "sent-2", durationSeconds: 240)

        var history = try repo.fetchHistoryEntries(byDocument: nil, byFolder: nil, from: nil, to: nil)
        XCTAssertEqual(history.count, 2)
        XCTAssertNotNil(history[0].document)
        XCTAssertNotNil(history[1].document)

        // When: Document is deleted
        try repo.deleteDocument(doc)
        controller.viewContext.refreshAllObjects()

        // Then: History entries remain but document reference is nullified
        history = try repo.fetchHistoryEntries(byDocument: nil, byFolder: nil, from: nil, to: nil)
        XCTAssertEqual(history.count, 2, "History entries should remain after document delete")
        XCTAssertNil(history[0].document, "HistoryItem.document should be nil after document delete")
        XCTAssertNil(history[1].document, "HistoryItem.document should be nil after document delete")

        // Other history data should be preserved
        XCTAssertEqual(history.first { $0.lastSentenceId == "sent-1" }?.durationSeconds, 120)
        XCTAssertEqual(history.first { $0.lastSentenceId == "sent-2" }?.durationSeconds, 240)
    }

    // MARK: - Referential Integrity Tests

    func testDeleteDocument_maintainsReferentialIntegrity() throws {
        // Given: Document in folders, queue, and history
        try repo.addDocument(identity: UUID(), title: "Test Doc", addedAt: Date(), fileReference: nil)
        try repo.addFolder(identity: UUID(), name: "Folder", createdAt: Date())

        let doc = try repo.fetchDocuments().first!
        let folder = try repo.fetchFolders().first!

        try repo.addDocumentToFolder(document: doc, folder: folder)
        try repo.addQueueEntry(identity: UUID(), paperId: doc.identity!.uuidString, orderIndex: 0, secOn: [], incApp: true, incSum: true, document: doc)
        try repo.saveHistoryEntry(document: doc, playedAt: Date(), lastSentenceId: "s1", durationSeconds: 100)

        // When: Document is deleted
        try repo.deleteDocument(doc)
        controller.viewContext.refreshAllObjects()

        // Then: No orphaned DocumentFolder entities exist
        let request = DocumentFolder.fetchRequest()
        request.predicate = NSPredicate(format: "document == nil OR folder == nil")
        let orphanedLinks = try controller.viewContext.fetch(request)
        XCTAssertEqual(orphanedLinks.count, 0, "No orphaned DocumentFolder entities should exist")

        // And: Document is deleted
        XCTAssertEqual(try repo.fetchDocuments().count, 0)

        // And: Folder still exists
        XCTAssertEqual(try repo.fetchFolders().count, 1)

        // And: Queue entry exists with nil document
        let entries = try repo.fetchQueueEntries()
        XCTAssertEqual(entries.count, 1)
        XCTAssertNil(entries.first?.document)

        // And: History entry exists with nil document
        let history = try repo.fetchHistoryEntries(byDocument: nil, byFolder: nil, from: nil, to: nil)
        XCTAssertEqual(history.count, 1)
        XCTAssertNil(history.first?.document)
    }

    func testDeleteDocument_noOrphanedDocumentFolders() throws {
        // Given: Document in multiple folders
        try repo.addDocument(identity: UUID(), title: "Doc", addedAt: Date(), fileReference: nil)
        try repo.addFolder(identity: UUID(), name: "F1", createdAt: Date())
        try repo.addFolder(identity: UUID(), name: "F2", createdAt: Date())
        try repo.addFolder(identity: UUID(), name: "F3", createdAt: Date())

        let doc = try repo.fetchDocuments().first!
        let folders = try repo.fetchFolders()

        for folder in folders {
            try repo.addDocumentToFolder(document: doc, folder: folder)
        }

        // Verify 3 DocumentFolder entities exist
        let beforeRequest = DocumentFolder.fetchRequest()
        let beforeCount = try controller.viewContext.count(for: beforeRequest)
        XCTAssertEqual(beforeCount, 3)

        // When: Document is deleted
        try repo.deleteDocument(doc)
        controller.viewContext.refreshAllObjects()

        // Then: All DocumentFolder entities are cascade deleted
        let afterRequest = DocumentFolder.fetchRequest()
        let afterCount = try controller.viewContext.count(for: afterRequest)
        XCTAssertEqual(afterCount, 0, "All DocumentFolder entities should be cascade deleted")

        // And: Folders still exist
        XCTAssertEqual(try repo.fetchFolders().count, 3)
    }

    // MARK: - Edge Cases

    func testDeleteDocument_withNoRelationships() throws {
        // Given: Document with no folder, queue, or history relationships
        try repo.addDocument(identity: UUID(), title: "Standalone", addedAt: Date(), fileReference: nil)
        let doc = try repo.fetchDocuments().first!

        // When: Document is deleted
        try repo.deleteDocument(doc)

        // Then: Document is removed without errors
        XCTAssertEqual(try repo.fetchDocuments().count, 0)
    }

    func testDeleteDocument_multipleFoldersAndQueue() throws {
        // Given: Document in 5 folders and queue
        try repo.addDocument(identity: UUID(), title: "Popular Doc", addedAt: Date(), fileReference: nil)
        let doc = try repo.fetchDocuments().first!

        for i in 1...5 {
            try repo.addFolder(identity: UUID(), name: "Folder \(i)", createdAt: Date())
        }

        let folders = try repo.fetchFolders()
        for folder in folders {
            try repo.addDocumentToFolder(document: doc, folder: folder)
        }

        try repo.addQueueEntry(identity: UUID(), paperId: doc.identity!.uuidString, orderIndex: 0, secOn: [], incApp: true, incSum: true, document: doc)

        // When: Document is deleted
        try repo.deleteDocument(doc)
        controller.viewContext.refreshAllObjects()

        // Then: All folder relationships are cascade deleted
        for folder in folders {
            XCTAssertEqual(try repo.fetchDocumentsInFolder(folder).count, 0)
        }

        // And: Queue entry document is nullified
        let entries = try repo.fetchQueueEntries()
        XCTAssertEqual(entries.count, 1)
        XCTAssertNil(entries.first?.document)

        // And: No orphaned DocumentFolder entities
        let request = DocumentFolder.fetchRequest()
        let remaining = try controller.viewContext.count(for: request)
        XCTAssertEqual(remaining, 0)
    }
}
