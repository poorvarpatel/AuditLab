//
//  StoreWiringTests.swift
//  AuditLabTests
//
//  Verify LibStore, FoldStore, and QueueStore load and mutate via DocumentRepository (Story 1.4).
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
        controller.viewContext.reset()
        repo = nil
        controller = nil
        super.tearDown()
    }

    // MARK: - LibStore

    func testLibStoreAddAndLoadFromRepository() throws {
        let lib = LibStore(repository: repo)
        XCTAssertTrue(lib.recs.isEmpty)

        let rec = PaperRec(id: "ignored", title: "Test Paper", auths: [], date: nil, addedAt: Date(), isRead: false)
        lib.add(rec)

        let docs = try repo.fetchDocuments()
        XCTAssertEqual(docs.count, 1)
        XCTAssertEqual(docs.first?.title, "Test Paper")
        XCTAssertEqual(lib.recs.count, 1)
        XCTAssertEqual(lib.recs.first?.title, "Test Paper")
    }

    func testLibStoreDeleteRemovesFromRepository() throws {
        let lib = LibStore(repository: repo)
        let rec = PaperRec(id: "ignored", title: "To Delete", auths: [], date: nil, addedAt: Date(), isRead: false)
        lib.add(rec)
        XCTAssertEqual(try repo.fetchDocuments().count, 1)

        let recToDelete = lib.recs.first!
        lib.delete(recToDelete)

        XCTAssertEqual(try repo.fetchDocuments().count, 0)
        XCTAssertTrue(lib.recs.isEmpty)
    }

    // MARK: - FoldStore

    func testFoldStoreAddNewAndLoadFromRepository() throws {
        let folds = FoldStore(repository: repo)
        XCTAssertTrue(folds.folds.isEmpty)

        folds.addNew(name: "My Folder")

        let folderList = try repo.fetchFolders()
        XCTAssertEqual(folderList.count, 1)
        XCTAssertEqual(folderList.first?.name, "My Folder")
        XCTAssertEqual(folds.folds.count, 1)
        XCTAssertEqual(folds.folds.first?.name, "My Folder")
    }

    func testFoldStoreRenamePersistsViaRepository() throws {
        try repo.addFolder(identity: UUID(), name: "Old Name", createdAt: Date())
        let folds = FoldStore(repository: repo)
        XCTAssertEqual(folds.folds.count, 1)
        let folderId = folds.folds.first!.id

        folds.rename(folderId, to: "New Name")

        let folderList = try repo.fetchFolders()
        XCTAssertEqual(folderList.first?.name, "New Name")
        XCTAssertEqual(folds.folds.first?.name, "New Name")
    }

    func testFoldStoreAddPaperAndRemovePaper() throws {
        try repo.addDocument(identity: UUID(), title: "Doc", addedAt: Date(), fileReference: nil)
        try repo.addFolder(identity: UUID(), name: "F", createdAt: Date())
        let folds = FoldStore(repository: repo)
        let doc = try repo.fetchDocuments().first!
        let folder = try repo.fetchFolders().first!
        let docId = doc.identity!.uuidString
        let folderId = folder.identity!.uuidString

        folds.addPaper(docId, to: folderId)

        XCTAssertEqual(try repo.fetchDocumentsInFolder(folder).count, 1)
        XCTAssertEqual(folds.folds.first(where: { $0.id == folderId })?.pids.count, 1)

        folds.removePaper(docId, from: folderId)

        XCTAssertEqual(try repo.fetchDocumentsInFolder(folder).count, 0)
        XCTAssertTrue(folds.folds.first(where: { $0.id == folderId })?.pids.isEmpty ?? true)
    }

    func testFoldStoreDeleteFolderRemovesFromRepository() throws {
        try repo.addFolder(identity: UUID(), name: "Gone", createdAt: Date())
        let folds = FoldStore(repository: repo)
        let folderId = folds.folds.first!.id

        folds.deleteFolder(folderId)

        XCTAssertEqual(try repo.fetchFolders().count, 0)
        XCTAssertTrue(folds.folds.isEmpty)
    }

    // MARK: - QueueStore

    func testQueueStoreAddAndLoadFromRepository() throws {
        let q = QueueStore(repository: repo)
        XCTAssertTrue(q.items.isEmpty)

        let item = QItem(paperId: "p1", secOn: ["s1"], incApp: true, incSum: false)
        q.add(item)

        let entries = try repo.fetchQueueEntries()
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.paperId, "p1")
        XCTAssertEqual(q.items.count, 1)
        XCTAssertEqual(q.items.first?.paperId, "p1")
    }

    func testQueueStoreRmRemovesFromRepository() throws {
        let q = QueueStore(repository: repo)
        let item = QItem(paperId: "p1", secOn: [], incApp: true, incSum: true)
        q.add(item)
        XCTAssertEqual(try repo.fetchQueueEntries().count, 1)

        q.rm(q.items.first!)

        XCTAssertEqual(try repo.fetchQueueEntries().count, 0)
        XCTAssertTrue(q.items.isEmpty)
    }

    func testQueueStoreClrRemovesAllFromRepository() throws {
        let q = QueueStore(repository: repo)
        q.add(QItem(paperId: "a", secOn: [], incApp: true, incSum: true))
        q.add(QItem(paperId: "b", secOn: [], incApp: true, incSum: true))
        XCTAssertEqual(try repo.fetchQueueEntries().count, 2)

        q.clr()

        XCTAssertEqual(try repo.fetchQueueEntries().count, 0)
        XCTAssertTrue(q.items.isEmpty)
    }

    func testQueueStoreMovePersistsOrder() throws {
        let q = QueueStore(repository: repo)
        q.add(QItem(paperId: "first", secOn: [], incApp: true, incSum: true))
        q.add(QItem(paperId: "second", secOn: [], incApp: true, incSum: true))
        q.add(QItem(paperId: "third", secOn: [], incApp: true, incSum: true))

        q.move(fromOffsets: IndexSet(integer: 0), toOffset: 3)

        let entries = try repo.fetchQueueEntries()
        XCTAssertEqual(entries.map(\.paperId), ["second", "third", "first"])
    }

    // MARK: - Restart persistence (Task 6 optional)

    /// Verifies data survives "restart" (new controller with same store URL).
    func testLibStoreDataSurvivesRestart() throws {
        let storeURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".sqlite")
        defer { try? FileManager.default.removeItem(at: storeURL) }

        let ctrl1 = PersistenceController(storeURL: storeURL)
        let repo1 = DocumentRepository(persistenceController: ctrl1)
        let lib1 = LibStore(repository: repo1)

        let rec = PaperRec(id: "restart-test", title: "Survives Restart", auths: [], date: nil, addedAt: Date(), isRead: false)
        lib1.add(rec)
        XCTAssertEqual(lib1.recs.count, 1)
        XCTAssertEqual(lib1.recs.first?.title, "Survives Restart")

        let ctrl2 = PersistenceController(storeURL: storeURL)
        let repo2 = DocumentRepository(persistenceController: ctrl2)
        let lib2 = LibStore(repository: repo2)

        XCTAssertEqual(lib2.recs.count, 1)
        XCTAssertEqual(lib2.recs.first?.title, "Survives Restart")
    }
}
