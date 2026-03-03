//
//  DocumentRepository.swift
//  AuditLab
//
//  Repository for Document and Folder CRUD. Uses PersistenceController contexts; all mutations persist (save).
//  viewContext is READONLY (fetches only). All writes use a background context.
//

import CoreData

enum DocumentRepositoryError: Error {
    case invalidObjectType(expectedEntity: String)
}

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

    func addQueueEntry(identity: UUID, paperId: String, orderIndex: Int32, secOn: Set<String>, incApp: Bool, incSum: Bool, document: Document?) throws
    func fetchQueueEntries() throws -> [QueueEntry]
    func deleteQueueEntry(_ entry: QueueEntry) throws
    func deleteAllQueueEntries() throws
    func updateQueueOrder(entries: [QueueEntry]) throws

    func saveSettings(voiceIdentifier: String?, speechRate: Double, appearance: String, skipAsk: Bool, figBg: Bool) throws
    func fetchSettings() throws -> AppSettings?
}

final class DocumentRepository: DocumentRepositoryProtocol {

    private let persistenceController: PersistenceController

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    private var viewContext: NSManagedObjectContext {
        persistenceController.viewContext
    }

    // MARK: - Document

    func addDocument(identity: UUID, title: String, addedAt: Date, fileReference: Data?) throws {
        let ctx = persistenceController.newBackgroundContext()
        try ctx.performAndWait {
            let doc = Document(context: ctx)
            doc.identity = identity
            doc.title = title
            doc.addedAt = addedAt
            doc.fileReference = fileReference
            try ctx.save()
        }
    }

    func fetchDocuments() throws -> [Document] {
        let request = Document.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Document.addedAt, ascending: false)]
        return try viewContext.fetch(request)
    }

    func deleteDocument(_ document: Document) throws {
        let objectID = document.objectID
        let ctx = persistenceController.newBackgroundContext()
        try ctx.performAndWait {
            guard let doc = ctx.object(with: objectID) as? Document else {
                throw DocumentRepositoryError.invalidObjectType(expectedEntity: "Document")
            }
            ctx.delete(doc)
            try ctx.save()
        }
    }

    // MARK: - Folder

    func addFolder(identity: UUID, name: String, createdAt: Date) throws {
        let ctx = persistenceController.newBackgroundContext()
        try ctx.performAndWait {
            let folder = Folder(context: ctx)
            folder.identity = identity
            folder.name = name
            folder.createdAt = createdAt
            try ctx.save()
        }
    }

    func fetchFolders() throws -> [Folder] {
        let request = Folder.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Folder.createdAt, ascending: false)]
        return try viewContext.fetch(request)
    }

    func deleteFolder(_ folder: Folder) throws {
        let objectID = folder.objectID
        let ctx = persistenceController.newBackgroundContext()
        try ctx.performAndWait {
            guard let f = ctx.object(with: objectID) as? Folder else {
                throw DocumentRepositoryError.invalidObjectType(expectedEntity: "Folder")
            }
            ctx.delete(f)
            try ctx.save()
        }
    }

    // MARK: - DocumentFolder

    func addDocumentToFolder(document: Document, folder: Folder) throws {
        let docID = document.objectID
        let folderID = folder.objectID
        let ctx = persistenceController.newBackgroundContext()
        try ctx.performAndWait {
            guard let doc = ctx.object(with: docID) as? Document else {
                throw DocumentRepositoryError.invalidObjectType(expectedEntity: "Document")
            }
            guard let f = ctx.object(with: folderID) as? Folder else {
                throw DocumentRepositoryError.invalidObjectType(expectedEntity: "Folder")
            }
            let existing = try fetchDocumentFolder(context: ctx, document: doc, folder: f)
            if existing != nil { return }
            let link = DocumentFolder(context: ctx)
            link.document = doc
            link.folder = f
            try ctx.save()
        }
    }

    func removeDocumentFromFolder(document: Document, folder: Folder) throws {
        let docID = document.objectID
        let folderID = folder.objectID
        let ctx = persistenceController.newBackgroundContext()
        try ctx.performAndWait {
            guard let doc = ctx.object(with: docID) as? Document else {
                throw DocumentRepositoryError.invalidObjectType(expectedEntity: "Document")
            }
            guard let f = ctx.object(with: folderID) as? Folder else {
                throw DocumentRepositoryError.invalidObjectType(expectedEntity: "Folder")
            }
            guard let link = try fetchDocumentFolder(context: ctx, document: doc, folder: f) else { return }
            ctx.delete(link)
            try ctx.save()
        }
    }

    func fetchDocumentsInFolder(_ folder: Folder) throws -> [Document] {
        guard let documentFolders = folder.documentFolders as? Set<DocumentFolder> else { return [] }
        return documentFolders.compactMap { $0.document }.sorted { ($0.addedAt ?? .distantPast) > ($1.addedAt ?? .distantPast) }
    }

    func fetchFoldersForDocument(_ document: Document) throws -> [Folder] {
        guard let documentFolders = document.documentFolders as? Set<DocumentFolder> else { return [] }
        return documentFolders.compactMap { $0.folder }.sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
    }

    private func fetchDocumentFolder(context: NSManagedObjectContext, document: Document, folder: Folder) throws -> DocumentFolder? {
        let request = DocumentFolder.fetchRequest()
        request.predicate = NSPredicate(format: "document == %@ AND folder == %@", document, folder)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    // MARK: - Queue

    /// Adds a queue entry. Writes on a background context. Optionally links to a Document for relationship (nullify on document delete).
    func addQueueEntry(identity: UUID, paperId: String, orderIndex: Int32, secOn: Set<String>, incApp: Bool, incSum: Bool, document: Document? = nil) throws {
        let docID = document?.objectID
        let ctx = persistenceController.newBackgroundContext()
        try ctx.performAndWait {
            let entry = QueueEntry(context: ctx)
            entry.identity = identity
            entry.paperId = paperId
            entry.orderIndex = orderIndex
            entry.secOn = Self.encodeSecOn(secOn)
            entry.incApp = incApp
            entry.incSum = incSum
            if let id = docID {
                entry.document = ctx.object(with: id) as? Document
            }
            try ctx.save()
        }
    }

    /// Returns queue entries sorted by orderIndex ascending. Reads from viewContext (readonly).
    func fetchQueueEntries() throws -> [QueueEntry] {
        let request = QueueEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \QueueEntry.orderIndex, ascending: true)]
        return try viewContext.fetch(request)
    }

    /// Deletes a single queue entry. Writes on a background context.
    func deleteQueueEntry(_ entry: QueueEntry) throws {
        let objectID = entry.objectID
        let ctx = persistenceController.newBackgroundContext()
        try ctx.performAndWait {
            guard let e = ctx.object(with: objectID) as? QueueEntry else {
                throw DocumentRepositoryError.invalidObjectType(expectedEntity: "QueueEntry")
            }
            ctx.delete(e)
            try ctx.save()
        }
    }

    /// Removes all queue entries. Writes on a background context.
    func deleteAllQueueEntries() throws {
        let ctx = persistenceController.newBackgroundContext()
        try ctx.performAndWait {
            let request = QueueEntry.fetchRequest()
            let entries = try ctx.fetch(request)
            entries.forEach { ctx.delete($0) }
            try ctx.save()
        }
    }

    /// Reorders queue entries by assigning orderIndex 0, 1, … to the given array order. Writes on a background context. Empty array is a no-op.
    func updateQueueOrder(entries: [QueueEntry]) throws {
        let objectIDs = entries.map(\.objectID)
        let ctx = persistenceController.newBackgroundContext()
        try ctx.performAndWait {
            for (index, id) in objectIDs.enumerated() {
                guard let entry = ctx.object(with: id) as? QueueEntry else {
                    throw DocumentRepositoryError.invalidObjectType(expectedEntity: "QueueEntry")
                }
                entry.orderIndex = Int32(index)
            }
            try ctx.save()
        }
    }

    private static func encodeSecOn(_ secOn: Set<String>) -> Data? {
        guard !secOn.isEmpty else { return nil }
        return (try? JSONEncoder().encode(Array(secOn)))
    }

    static func decodeSecOn(_ data: Data?) -> Set<String> {
        guard let data = data,
              let arr = try? JSONDecoder().decode([String].self, from: data) else { return [] }
        return Set(arr)
    }

    // MARK: - Settings

    /// Upserts the single AppSettings row (singleton). Writes on a background context. Creates row if none exists.
    func saveSettings(voiceIdentifier: String?, speechRate: Double, appearance: String, skipAsk: Bool, figBg: Bool) throws {
        let ctx = persistenceController.newBackgroundContext()
        try ctx.performAndWait {
            let request = AppSettings.fetchRequest()
            request.fetchLimit = 1
            let existing = try ctx.fetch(request).first
            let settings: AppSettings
            if let s = existing {
                settings = s
            } else {
                settings = AppSettings(context: ctx)
            }
            settings.voiceIdentifier = voiceIdentifier
            settings.speechRate = speechRate
            settings.appearance = appearance
            settings.skipAsk = skipAsk
            settings.figBg = figBg
            try ctx.save()
        }
    }

    /// Returns the single AppSettings row if present, nil otherwise. Reads from viewContext (readonly).
    func fetchSettings() throws -> AppSettings? {
        let request = AppSettings.fetchRequest()
        request.fetchLimit = 1
        return try viewContext.fetch(request).first
    }
}
