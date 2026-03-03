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
        repo = DocumentRepository(context: controller.viewContext)
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
}
