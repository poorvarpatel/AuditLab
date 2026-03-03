//
//  DocumentRepository.swift
//  AuditLab
//
//  Repository for Document and Folder CRUD. Uses PersistenceController contexts; all mutations persist (save).
//

import CoreData

protocol DocumentRepositoryProtocol {
    func addDocument(identity: UUID, title: String, addedAt: Date, fileReference: Data?) throws
    func fetchDocuments() throws -> [Document]
    func deleteDocument(_ document: Document) throws
    func addFolder(identity: UUID, name: String, createdAt: Date) throws
    func fetchFolders() throws -> [Folder]
    func deleteFolder(_ folder: Folder) throws
    func addDocumentToFolder(document: Document, folder: Folder) throws
    func removeDocumentFromFolder(document: Document, folder: Folder) throws
    func fetchDocumentsInFolder(_ folder: Folder) throws -> [Document]
    func fetchFoldersForDocument(_ document: Document) throws -> [Folder]
}

final class DocumentRepository: DocumentRepositoryProtocol {

    private let viewContext: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.viewContext) {
        self.viewContext = context
    }

    func addDocument(identity: UUID, title: String, addedAt: Date, fileReference: Data?) throws {
        let doc = Document(context: viewContext)
        doc.identity = identity
        doc.title = title
        doc.addedAt = addedAt
        doc.fileReference = fileReference
        try viewContext.save()
    }

    func fetchDocuments() throws -> [Document] {
        let request = Document.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Document.addedAt, ascending: false)]
        return try viewContext.fetch(request)
    }

    func deleteDocument(_ document: Document) throws {
        viewContext.delete(document)
        try viewContext.save()
    }

    func addFolder(identity: UUID, name: String, createdAt: Date) throws {
        let folder = Folder(context: viewContext)
        folder.identity = identity
        folder.name = name
        folder.createdAt = createdAt
        try viewContext.save()
    }

    func fetchFolders() throws -> [Folder] {
        let request = Folder.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Folder.createdAt, ascending: false)]
        return try viewContext.fetch(request)
    }

    func deleteFolder(_ folder: Folder) throws {
        viewContext.delete(folder)
        try viewContext.save()
    }

    func addDocumentToFolder(document: Document, folder: Folder) throws {
        let existing = try fetchDocumentFolder(document: document, folder: folder)
        if existing != nil { return }
        let link = DocumentFolder(context: viewContext)
        link.document = document
        link.folder = folder
        try viewContext.save()
    }

    func removeDocumentFromFolder(document: Document, folder: Folder) throws {
        guard let link = try fetchDocumentFolder(document: document, folder: folder) else { return }
        viewContext.delete(link)
        try viewContext.save()
    }

    func fetchDocumentsInFolder(_ folder: Folder) throws -> [Document] {
        guard let documentFolders = folder.documentFolders as? Set<DocumentFolder> else { return [] }
        return documentFolders.compactMap { $0.document }.sorted { ($0.addedAt ?? .distantPast) > ($1.addedAt ?? .distantPast) }
    }

    func fetchFoldersForDocument(_ document: Document) throws -> [Folder] {
        guard let documentFolders = document.documentFolders as? Set<DocumentFolder> else { return [] }
        return documentFolders.compactMap { $0.folder }.sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
    }

    private func fetchDocumentFolder(document: Document, folder: Folder) throws -> DocumentFolder? {
        let request = DocumentFolder.fetchRequest()
        request.predicate = NSPredicate(format: "document == %@ AND folder == %@", document, folder)
        request.fetchLimit = 1
        return try viewContext.fetch(request).first
    }
}
