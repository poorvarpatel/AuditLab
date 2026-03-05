//
//  StoreWiringTests.swift
//  AuditLabTests
//
//  Verify LibStore, FoldStore, and QueueStore persist via DocumentRepository
//  and that reloadFromContext() correctly maps Core Data objects to published models.
//
//  Strategy: call store mutation → verify the repository has the data →
//  call reloadFromContext() → verify the @Published property reflects it.
//  This is deterministic and synchronous — no run-loop spinning.
//

import XCTest
import CoreData
@testable import AuditLab

@MainActor
final class StoreWiringTests: XCTestCase {

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

    // MARK: - LibStore

    func testAddPersistsAndReloads() throws {
        let lib = LibStore(repository: repo)
        XCTAssertTrue(lib.recs.isEmpty)

        let rec = PaperRec(id: "ignored", title: "Test Paper", auths: [], date: nil, addedAt: Date(), isRead: false)
        lib.add(rec)

        let docs = try repo.fetchDocuments()
        XCTAssertEqual(docs.count, 1)
        XCTAssertEqual(docs.first?.title, "Test Paper")

        lib.reloadFromContext()
        XCTAssertEqual(lib.recs.count, 1)
        XCTAssertEqual(lib.recs.first?.title, "Test Paper")
    }

    func testDeletePersistsAndReloads() throws {
        let lib = LibStore(repository: repo)
        lib.add(PaperRec(id: "x", title: "Gone", auths: [], date: nil, addedAt: Date(), isRead: false))
        lib.reloadFromContext()
        XCTAssertEqual(lib.recs.count, 1)

        lib.delete(lib.recs.first!)

        XCTAssertEqual(try repo.fetchDocuments().count, 0)

        lib.reloadFromContext()
        XCTAssertTrue(lib.recs.isEmpty)
    }

    // MARK: - FoldStore

    func testAddFolderPersistsAndReloads() throws {
        let folds = FoldStore(repository: repo)
        XCTAssertTrue(folds.folds.isEmpty)

        folds.addNew(name: "My Folder")

        let folders = try repo.fetchFolders()
        XCTAssertEqual(folders.count, 1)
        XCTAssertEqual(folders.first?.name, "My Folder")

        folds.reloadFromContext()
        XCTAssertEqual(folds.folds.count, 1)
        XCTAssertEqual(folds.folds.first?.name, "My Folder")
    }

    func testAddAndRemovePaperFromFolder() throws {
        try repo.addDocument(identity: UUID(), title: "Doc", addedAt: Date(), fileReference: nil)
        try repo.addFolder(identity: UUID(), name: "F", createdAt: Date())

        let folds = FoldStore(repository: repo)
        folds.reloadFromContext()

        let doc = try repo.fetchDocuments().first!
        let folder = try repo.fetchFolders().first!
        let docId = doc.identity!.uuidString
        let folderId = folder.identity!.uuidString

        folds.addPaper(docId, to: folderId)
        folds.reloadFromContext()

        XCTAssertEqual(try repo.fetchDocumentsInFolder(folder).count, 1)
        XCTAssertEqual(folds.folds.first(where: { $0.id == folderId })?.pids.count, 1)

        folds.removePaper(docId, from: folderId)
        folds.reloadFromContext()

        XCTAssertEqual(try repo.fetchDocumentsInFolder(folder).count, 0)
        XCTAssertTrue(folds.folds.first(where: { $0.id == folderId })?.pids.isEmpty ?? true)
    }

    func testDeleteFolderPersistsAndReloads() throws {
        try repo.addFolder(identity: UUID(), name: "Gone", createdAt: Date())

        let folds = FoldStore(repository: repo)
        folds.reloadFromContext()
        let folderId = folds.folds.first!.id

        folds.deleteFolder(folderId)
        folds.reloadFromContext()

        XCTAssertEqual(try repo.fetchFolders().count, 0)
        XCTAssertTrue(folds.folds.isEmpty)
    }

    // MARK: - QueueStore

    func testAddQueueEntryPersistsAndReloads() throws {
        let q = QueueStore(repository: repo)
        XCTAssertTrue(q.items.isEmpty)

        q.add(QItem(paperId: "p1", secOn: ["s1"], incApp: true, incSum: false))

        let entries = try repo.fetchQueueEntries()
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.paperId, "p1")

        q.reloadFromContext()
        XCTAssertEqual(q.items.count, 1)
        XCTAssertEqual(q.items.first?.paperId, "p1")
    }

    func testRemoveQueueEntryPersistsAndReloads() throws {
        let q = QueueStore(repository: repo)
        q.add(QItem(paperId: "p1", secOn: [], incApp: true, incSum: true))
        q.reloadFromContext()
        XCTAssertEqual(q.items.count, 1)

        q.rm(q.items.first!)
        q.reloadFromContext()

        XCTAssertEqual(try repo.fetchQueueEntries().count, 0)
        XCTAssertTrue(q.items.isEmpty)
    }

    func testClearQueuePersistsAndReloads() throws {
        let q = QueueStore(repository: repo)
        q.add(QItem(paperId: "a", secOn: [], incApp: true, incSum: true))
        q.add(QItem(paperId: "b", secOn: [], incApp: true, incSum: true))
        q.reloadFromContext()
        XCTAssertEqual(q.items.count, 2)

        q.clr()
        q.reloadFromContext()

        XCTAssertEqual(try repo.fetchQueueEntries().count, 0)
        XCTAssertTrue(q.items.isEmpty)
    }

    func testMoveQueueEntryPersistsOrder() throws {
        let q = QueueStore(repository: repo)
        q.add(QItem(paperId: "first", secOn: [], incApp: true, incSum: true))
        q.add(QItem(paperId: "second", secOn: [], incApp: true, incSum: true))
        q.add(QItem(paperId: "third", secOn: [], incApp: true, incSum: true))
        q.reloadFromContext()
        XCTAssertEqual(q.items.map(\.paperId), ["first", "second", "third"])

        q.move(fromOffsets: IndexSet(integer: 0), toOffset: 3)
        q.reloadFromContext()

        XCTAssertEqual(q.items.map(\.paperId), ["second", "third", "first"])

        let entries = try repo.fetchQueueEntries()
        XCTAssertEqual(entries.map(\.paperId), ["second", "third", "first"])
    }
}
