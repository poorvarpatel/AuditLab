//
//  DocumentRepositoryTests.swift
//  AuditLabTests
//

import XCTest
import CoreData
@testable import AuditLab

final class DocumentRepositoryTests: XCTestCase {

    private var controller: PersistenceController!
    private var repo: DocumentRepository!

    override func setUp() {
        super.setUp()
        controller = PersistenceController(inMemory: true)
        repo = DocumentRepository(persistenceController: controller)
    }

    override func tearDown() {
        controller.viewContext.reset()
        repo = nil
        controller = nil
        super.tearDown()
    }

    func testAddAndFetchDocument() throws {
        let id = UUID()
        try repo.addDocument(identity: id, title: "Test Doc", addedAt: Date(), fileReference: nil)

        let docs = try repo.fetchDocuments()
        XCTAssertEqual(docs.count, 1)
        XCTAssertEqual(docs.first?.title, "Test Doc")
        XCTAssertEqual(docs.first?.identity, id)
    }

    func testAddAndFetchFolder() throws {
        let id = UUID()
        try repo.addFolder(identity: id, name: "Test Folder", createdAt: Date())

        let folders = try repo.fetchFolders()
        XCTAssertEqual(folders.count, 1)
        XCTAssertEqual(folders.first?.name, "Test Folder")
        XCTAssertEqual(folders.first?.identity, id)
    }

    func testAddDocumentToFolder() throws {
        try repo.addDocument(identity: UUID(), title: "D", addedAt: Date(), fileReference: nil)
        try repo.addFolder(identity: UUID(), name: "F", createdAt: Date())

        let doc = try repo.fetchDocuments().first!
        let folder = try repo.fetchFolders().first!

        try repo.addDocumentToFolder(document: doc, folder: folder)

        let docsInFolder = try repo.fetchDocumentsInFolder(folder)
        let foldersForDoc = try repo.fetchFoldersForDocument(doc)
        XCTAssertEqual(docsInFolder.count, 1)
        XCTAssertEqual(foldersForDoc.count, 1)
    }

    func testDeleteDocument() throws {
        try repo.addDocument(identity: UUID(), title: "Gone", addedAt: Date(), fileReference: nil)
        let doc = try repo.fetchDocuments().first!
        try repo.deleteDocument(doc)
        XCTAssertEqual(try repo.fetchDocuments().count, 0)
    }

    func testNoDuplicateLink() throws {
        try repo.addDocument(identity: UUID(), title: "D", addedAt: Date(), fileReference: nil)
        try repo.addFolder(identity: UUID(), name: "F", createdAt: Date())

        let doc = try repo.fetchDocuments().first!
        let folder = try repo.fetchFolders().first!

        try repo.addDocumentToFolder(document: doc, folder: folder)
        try repo.addDocumentToFolder(document: doc, folder: folder)

        XCTAssertEqual(try repo.fetchDocumentsInFolder(folder).count, 1)
    }

    // MARK: - Queue

    func testAddAndFetchQueueEntriesInOrder() throws {
        try repo.addQueueEntry(identity: UUID(), paperId: "p1", orderIndex: 0, secOn: ["s1"], incApp: true, incSum: false, document: nil)
        try repo.addQueueEntry(identity: UUID(), paperId: "p2", orderIndex: 1, secOn: [], incApp: false, incSum: true, document: nil)
        try repo.addQueueEntry(identity: UUID(), paperId: "p3", orderIndex: 2, secOn: ["a", "b"], incApp: true, incSum: true, document: nil)

        let entries = try repo.fetchQueueEntries()
        XCTAssertEqual(entries.count, 3)
        XCTAssertEqual(entries.map(\.paperId), ["p1", "p2", "p3"])
        XCTAssertEqual(entries[0].orderIndex, 0)
        XCTAssertEqual(entries[1].orderIndex, 1)
        XCTAssertEqual(entries[2].orderIndex, 2)
    }

    func testDeleteQueueEntry() throws {
        try repo.addQueueEntry(identity: UUID(), paperId: "a", orderIndex: 0, secOn: [], incApp: true, incSum: true, document: nil)
        try repo.addQueueEntry(identity: UUID(), paperId: "b", orderIndex: 1, secOn: [], incApp: true, incSum: true, document: nil)
        try repo.addQueueEntry(identity: UUID(), paperId: "c", orderIndex: 2, secOn: [], incApp: true, incSum: true, document: nil)

        let entries = try repo.fetchQueueEntries()
        try repo.deleteQueueEntry(entries[1])

        let after = try repo.fetchQueueEntries()
        XCTAssertEqual(after.count, 2)
        XCTAssertEqual(after.map(\.paperId), ["a", "c"])
        XCTAssertEqual(after[0].orderIndex, 0)
        XCTAssertEqual(after[1].orderIndex, 2)
    }

    func testDeleteAllQueueEntries() throws {
        try repo.addQueueEntry(identity: UUID(), paperId: "x", orderIndex: 0, secOn: [], incApp: true, incSum: true, document: nil)
        try repo.deleteAllQueueEntries()
        XCTAssertEqual(try repo.fetchQueueEntries().count, 0)
    }

    func testUpdateQueueOrder() throws {
        try repo.addQueueEntry(identity: UUID(), paperId: "first", orderIndex: 0, secOn: [], incApp: true, incSum: true, document: nil)
        try repo.addQueueEntry(identity: UUID(), paperId: "second", orderIndex: 1, secOn: [], incApp: true, incSum: true, document: nil)
        try repo.addQueueEntry(identity: UUID(), paperId: "third", orderIndex: 2, secOn: [], incApp: true, incSum: true, document: nil)

        let entries = try repo.fetchQueueEntries()
        try repo.updateQueueOrder(entries: entries.reversed())

        let after = try repo.fetchQueueEntries()
        XCTAssertEqual(after.map(\.paperId), ["third", "second", "first"])
        XCTAssertEqual(after[0].orderIndex, 0)
        XCTAssertEqual(after[1].orderIndex, 1)
        XCTAssertEqual(after[2].orderIndex, 2)
    }

    func testSaveSettingsCreatesRow() throws {
        try repo.saveSettings(voiceIdentifier: "com.apple.voice.test", speechRate: 2.8, appearance: "system", skipAsk: true, figBg: true)
        let settings = try repo.fetchSettings()
        XCTAssertNotNil(settings)
        XCTAssertEqual(settings?.voiceIdentifier, "com.apple.voice.test")
        XCTAssertEqual(settings?.speechRate, 2.8)
        XCTAssertEqual(settings?.appearance, "system")
        XCTAssertEqual(settings?.skipAsk, true)
        XCTAssertEqual(settings?.figBg, true)
    }

    func testSaveSettingsUpdatesSameRow() throws {
        try repo.saveSettings(voiceIdentifier: "v1", speechRate: 2.0, appearance: "light", skipAsk: true, figBg: false)
        try repo.saveSettings(voiceIdentifier: "v2", speechRate: 3.0, appearance: "dark", skipAsk: false, figBg: true)

        let settings = try repo.fetchSettings()
        XCTAssertEqual(settings?.voiceIdentifier, "v2")
        XCTAssertEqual(settings?.speechRate, 3.0)
        XCTAssertEqual(settings?.appearance, "dark")
        XCTAssertEqual(settings?.skipAsk, false)
        XCTAssertEqual(settings?.figBg, true)
    }

    func testFetchSettingsReturnsNilWhenEmpty() throws {
        XCTAssertNil(try repo.fetchSettings())
    }

    /// Verifies that the canonical default values (speechRate 2.8, appearance "system") are persisted and returned.
    func testAppSettingsDefaultValuesPersisted() throws {
        try repo.saveSettings(voiceIdentifier: "voice.id", speechRate: 2.8, appearance: "system", skipAsk: true, figBg: true)
        let settings = try repo.fetchSettings()
        XCTAssertEqual(settings?.speechRate, 2.8)
        XCTAssertEqual(settings?.appearance, "system")
    }

    func testSaveSettingsWithNilVoiceIdentifier() throws {
        try repo.saveSettings(voiceIdentifier: nil, speechRate: 2.5, appearance: "dark", skipAsk: false, figBg: true)
        let settings = try repo.fetchSettings()
        XCTAssertNil(settings?.voiceIdentifier)
        XCTAssertEqual(settings?.speechRate, 2.5)
        XCTAssertEqual(settings?.appearance, "dark")
    }

    func testUpdateQueueOrderEmptyArrayIsNoOp() throws {
        try repo.addQueueEntry(identity: UUID(), paperId: "p1", orderIndex: 0, secOn: [], incApp: true, incSum: true, document: nil)
        try repo.updateQueueOrder(entries: [])
        let entries = try repo.fetchQueueEntries()
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].orderIndex, 0)
    }

    func testQueueEntryWithDocumentRelationship_deleteDocument_nullifiesEntry() throws {
        try repo.addDocument(identity: UUID(), title: "Doc", addedAt: Date(), fileReference: nil)
        let doc = try repo.fetchDocuments().first!
        try repo.addQueueEntry(identity: UUID(), paperId: doc.title ?? "", orderIndex: 0, secOn: [], incApp: true, incSum: true, document: doc)

        var entries = try repo.fetchQueueEntries()
        XCTAssertEqual(entries.count, 1)
        try repo.deleteDocument(doc)

        entries = try repo.fetchQueueEntries()
        XCTAssertEqual(entries.count, 1)
        XCTAssertNil(entries.first?.document)
    }
}
