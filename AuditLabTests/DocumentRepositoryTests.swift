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

    func testUpdateFolderName() throws {
        let id = UUID()
        try repo.addFolder(identity: id, name: "Original", createdAt: Date())
        let folder = try repo.fetchFolders().first!
        try repo.updateFolderName(folder, name: "Renamed")
        let folders = try repo.fetchFolders()
        XCTAssertEqual(folders.first?.name, "Renamed")
        XCTAssertEqual(folders.first?.identity, id)
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

    // MARK: - History

    func testSaveHistoryEntryAndFetch() throws {
        let playedAt = Date()
        try repo.saveHistoryEntry(document: nil, playedAt: playedAt, lastSentenceId: "sent-1", durationSeconds: 120.5)

        let entries = try repo.fetchHistoryEntries(byDocument: nil, byFolder: nil, from: nil, to: nil)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.lastSentenceId, "sent-1")
        XCTAssertEqual(entries.first?.durationSeconds, 120.5)
        XCTAssertNotNil(entries.first?.playedAt)
    }

    func testFetchHistoryEntriesWhenEmpty() throws {
        let entries = try repo.fetchHistoryEntries(byDocument: nil, byFolder: nil, from: nil, to: nil)
        XCTAssertTrue(entries.isEmpty)
    }

    func testFetchHistoryEntriesByDocument() throws {
        try repo.addDocument(identity: UUID(), title: "Doc A", addedAt: Date(), fileReference: nil)
        try repo.addDocument(identity: UUID(), title: "Doc B", addedAt: Date(), fileReference: nil)
        let docA = try repo.fetchDocuments().first { $0.title == "Doc A" }!
        let docB = try repo.fetchDocuments().first { $0.title == "Doc B" }!

        try repo.saveHistoryEntry(document: docA, playedAt: Date(), lastSentenceId: nil, durationSeconds: 10)
        try repo.saveHistoryEntry(document: docB, playedAt: Date(), lastSentenceId: nil, durationSeconds: 20)
        try repo.saveHistoryEntry(document: docA, playedAt: Date(), lastSentenceId: "s2", durationSeconds: 30)

        let forA = try repo.fetchHistoryEntries(byDocument: docA, byFolder: nil, from: nil, to: nil)
        let forB = try repo.fetchHistoryEntries(byDocument: docB, byFolder: nil, from: nil, to: nil)
        XCTAssertEqual(forA.count, 2)
        XCTAssertEqual(forB.count, 1)
        XCTAssertEqual(forB.first?.durationSeconds, 20)
    }

    func testFetchHistoryEntriesByDateRange() throws {
        let cal = Calendar(identifier: .gregorian)
        let start = cal.date(bySettingHour: 10, minute: 0, second: 0, of: Date())!
        let mid = cal.date(byAdding: .hour, value: 1, to: start)!
        let end = cal.date(byAdding: .hour, value: 2, to: start)!
        let after = cal.date(byAdding: .hour, value: 3, to: start)!

        try repo.saveHistoryEntry(document: nil, playedAt: start, lastSentenceId: nil, durationSeconds: 1)
        try repo.saveHistoryEntry(document: nil, playedAt: mid, lastSentenceId: nil, durationSeconds: 2)
        try repo.saveHistoryEntry(document: nil, playedAt: end, lastSentenceId: nil, durationSeconds: 3)
        try repo.saveHistoryEntry(document: nil, playedAt: after, lastSentenceId: nil, durationSeconds: 4)

        let inRange = try repo.fetchHistoryEntries(byDocument: nil, byFolder: nil, from: mid, to: end)
        XCTAssertEqual(inRange.count, 2)
        XCTAssertTrue(inRange.allSatisfy { $0.playedAt.map { $0 >= mid && $0 <= end } ?? false })
    }

    func testFetchHistoryEntriesOrderedByPlayedAtDescending() throws {
        let base = Date()
        try repo.saveHistoryEntry(document: nil, playedAt: base, lastSentenceId: "a", durationSeconds: 1)
        try repo.saveHistoryEntry(document: nil, playedAt: base.addingTimeInterval(10), lastSentenceId: "b", durationSeconds: 2)
        try repo.saveHistoryEntry(document: nil, playedAt: base.addingTimeInterval(-5), lastSentenceId: "c", durationSeconds: 3)

        let entries = try repo.fetchHistoryEntries(byDocument: nil, byFolder: nil, from: nil, to: nil)
        XCTAssertEqual(entries.count, 3)
        let playedAts = entries.compactMap(\.playedAt)
        XCTAssertEqual(playedAts, playedAts.sorted(by: >))
        XCTAssertEqual(entries.first?.lastSentenceId, "b")
        XCTAssertEqual(entries.last?.lastSentenceId, "c")
    }

    func testDeleteDocument_nullifiesHistoryItemDocument() throws {
        try repo.addDocument(identity: UUID(), title: "Doc", addedAt: Date(), fileReference: nil)
        let doc = try repo.fetchDocuments().first!
        try repo.saveHistoryEntry(document: doc, playedAt: Date(), lastSentenceId: "s1", durationSeconds: 100)

        var history = try repo.fetchHistoryEntries(byDocument: nil, byFolder: nil, from: nil, to: nil)
        XCTAssertEqual(history.count, 1)
        XCTAssertNotNil(history.first?.document)

        try repo.deleteDocument(doc)
        controller.viewContext.refreshAllObjects()

        history = try repo.fetchHistoryEntries(byDocument: nil, byFolder: nil, from: nil, to: nil)
        XCTAssertEqual(history.count, 1)
        XCTAssertNil(history.first?.document)
    }

    func testFetchHistoryEntriesByFolder() throws {
        try repo.addDocument(identity: UUID(), title: "Doc", addedAt: Date(), fileReference: nil)
        try repo.addFolder(identity: UUID(), name: "Folder A", createdAt: Date())
        try repo.addFolder(identity: UUID(), name: "Folder B", createdAt: Date())
        let doc = try repo.fetchDocuments().first!
        let folderA = try repo.fetchFolders().first { $0.name == "Folder A" }!
        let folderB = try repo.fetchFolders().first { $0.name == "Folder B" }!
        try repo.addDocumentToFolder(document: doc, folder: folderA)

        try repo.saveHistoryEntry(document: doc, playedAt: Date(), lastSentenceId: "s1", durationSeconds: 10)

        let inA = try repo.fetchHistoryEntries(byDocument: nil, byFolder: folderA, from: nil, to: nil)
        let inB = try repo.fetchHistoryEntries(byDocument: nil, byFolder: folderB, from: nil, to: nil)
        XCTAssertEqual(inA.count, 1)
        XCTAssertEqual(inB.count, 0)
    }


    func testSaveHistoryEntryRejectsNegativeDuration() throws {
        XCTAssertThrowsError(try repo.saveHistoryEntry(document: nil, playedAt: Date(), lastSentenceId: nil, durationSeconds: -1)) { error in
            guard case DocumentRepositoryError.invalidDuration = error else {
                return XCTFail("Expected DocumentRepositoryError.invalidDuration, got \(error)")
            }
        }
    }
}
