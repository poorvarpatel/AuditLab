//
//  StoreWiringTests.swift
//  AuditLabTests
//
//  Verify LibStore, FoldStore, and QueueStore load and mutate via DocumentRepository (Story 1.4).
//

import XCTest
import CoreData
import UIKit
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

    /// Story 2.1: Add PDF via document picker flow. Parsing off main; repository receives new Document; loading state set then cleared.
    func testLibStoreAddDocumentFromURL() async throws {
        let lib = LibStore(repository: repo)
        XCTAssertTrue(lib.recs.isEmpty)
        XCTAssertFalse(lib.isAddingDocument)

        let pdfURL = try createMinimalTestPDF()
        defer { try? FileManager.default.removeItem(at: pdfURL) }

        lib.addDocument(from: pdfURL)
        XCTAssertTrue(lib.isAddingDocument)

        // Wait for async add to complete (parsing + persistence)
        var waitCount = 0
        while lib.isAddingDocument && waitCount < 100 {
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
            waitCount += 1
        }
        XCTAssertFalse(lib.isAddingDocument, "Loading should clear within ~5s")

        let docs = try repo.fetchDocuments()
        XCTAssertEqual(docs.count, 1)
        XCTAssertEqual(lib.recs.count, 1)
        XCTAssertFalse(lib.recs.first?.title.isEmpty ?? true)
        XCTAssertNil(lib.addError)
    }

    /// Story 2.1 / Code review: Parse failure shows user-facing error and clears loading state.
    func testLibStoreAddDocumentFromURLParseFailure() async throws {
        let lib = LibStore(repository: repo)
        let notPDF = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".pdf")
        try "not a pdf".write(to: notPDF, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: notPDF) }

        lib.addDocument(from: notPDF)
        var waitCount = 0
        while lib.isAddingDocument && waitCount < 100 {
            try await Task.sleep(nanoseconds: 50_000_000)
            waitCount += 1
        }
        XCTAssertFalse(lib.isAddingDocument)
        XCTAssertTrue(lib.recs.isEmpty)
        XCTAssertNotNil(lib.addError)
        XCTAssertTrue(lib.addError?.contains("Couldn't read") ?? false)
    }

    /// Story 2.1 / Code review: Repository (persistence) failure shows distinct message and clears loading state.
    func testLibStoreAddDocumentFromURLPersistenceFailure() async throws {
        let failingRepo = ThrowingDocumentRepository(failAddDocument: true)
        let lib = LibStore(repository: failingRepo)
        let pdfURL = try createMinimalTestPDF()
        defer { try? FileManager.default.removeItem(at: pdfURL) }

        lib.addDocument(from: pdfURL)
        var waitCount = 0
        while lib.isAddingDocument && waitCount < 100 {
            try await Task.sleep(nanoseconds: 50_000_000)
            waitCount += 1
        }
        XCTAssertFalse(lib.isAddingDocument)
        XCTAssertTrue(lib.recs.isEmpty)
        XCTAssertNotNil(lib.addError)
        XCTAssertTrue(lib.addError?.contains("Couldn't save") ?? false)
    }

    /// Second add while first is in progress is ignored (one loading state per operation).
    func testLibStoreAddDocumentFromURLConcurrentAddIgnored() async throws {
        let lib = LibStore(repository: repo)
        let pdfURL = try createMinimalTestPDF()
        defer { try? FileManager.default.removeItem(at: pdfURL) }

        lib.addDocument(from: pdfURL)
        XCTAssertTrue(lib.isAddingDocument)
        lib.addDocument(from: pdfURL)
        lib.addDocument(from: pdfURL)
        // Still one add in flight
        XCTAssertTrue(lib.isAddingDocument)

        var waitCount = 0
        while lib.isAddingDocument && waitCount < 100 {
            try await Task.sleep(nanoseconds: 50_000_000)
            waitCount += 1
        }
        // Only one document from the first add
        XCTAssertEqual(lib.recs.count, 1)
    }

    private func createMinimalTestPDF() throws -> URL {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        let data = renderer.pdfData { context in
            context.beginPage()
            let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12)]
            "Test PDF Title".draw(at: CGPoint(x: 100, y: 700), withAttributes: attributes)
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".pdf")
        try data.write(to: url)
        return url
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

// MARK: - Mock for persistence-failure tests

private final class ThrowingDocumentRepository: DocumentRepositoryProtocol {
    var failAddDocument: Bool

    init(failAddDocument: Bool = false) {
        self.failAddDocument = failAddDocument
    }

    func addDocument(identity: UUID, title: String, addedAt: Date, fileReference: Data?) throws {
        if failAddDocument {
            throw NSError(domain: "StoreWiringTests", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock persistence failure"])
        }
    }

    func fetchDocuments() throws -> [Document] { [] }
    func deleteDocument(_ document: Document) throws {}
    func addFolder(identity: UUID, name: String, createdAt: Date) throws {}
    func fetchFolders() throws -> [Folder] { [] }
    func updateFolderName(_ folder: Folder, name: String) throws {}
    func deleteFolder(_ folder: Folder) throws {}
    func addDocumentToFolder(document: Document, folder: Folder) throws {}
    func removeDocumentFromFolder(document: Document, folder: Folder) throws {}
    func fetchDocumentsInFolder(_ folder: Folder) throws -> [Document] { [] }
    func fetchFoldersForDocument(_ document: Document) throws -> [Folder] { [] }
    func addQueueEntry(identity: UUID, paperId: String, orderIndex: Int32, secOn: Set<String>, incApp: Bool, incSum: Bool, document: Document?) throws {}
    func fetchQueueEntries() throws -> [QueueEntry] { [] }
    func deleteQueueEntry(_ entry: QueueEntry) throws {}
    func deleteAllQueueEntries() throws {}
    func updateQueueOrder(entries: [QueueEntry]) throws {}
    func saveSettings(voiceIdentifier: String?, speechRate: Double, appearance: String, skipAsk: Bool, figBg: Bool) throws {}
    func fetchSettings() throws -> AppSettings? { nil }
    func saveHistoryEntry(document: Document?, playedAt: Date, lastSentenceId: String?, durationSeconds: Double) throws {}
    func fetchHistoryEntries(byDocument: Document?, byFolder: Folder?, from startDate: Date?, to endDate: Date?) throws -> [HistoryItem] { [] }
}
