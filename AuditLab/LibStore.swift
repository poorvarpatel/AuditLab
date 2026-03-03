//
//  LibStore.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/7/26.
//

import Foundation
import Combine
import CoreData

/// User-facing error when adding a document fails.
struct AddDocumentError: Error {
  let message: String
}

@MainActor
final class LibStore: ObservableObject {
  @Published var recs: [PaperRec] = []
  /// True while addDocument(from:) is parsing and persisting. One loading state per add operation (NFR-P3).
  @Published var isAddingDocument = false
  /// User-facing error message when add fails. Clear on next add attempt.
  @Published var addError: String?

  private let repository: DocumentRepositoryProtocol
  // Store parsed ReadPacks in memory (later: persist to disk)
  private var packs: [String: ReadPack] = [:]

  init(repository: DocumentRepositoryProtocol) {
    self.repository = repository
    loadRecs()
  }

  /// Adds a PDF from the document picker. Parsing runs off main thread (NFR-P1); state updates on main.
  /// Only one add runs at a time; if already adding, this call is ignored (one loading state per operation).
  func addDocument(from url: URL) {
    guard !isAddingDocument else { return }
    addError = nil
    isAddingDocument = true

    let repo = repository
    Task.detached(priority: .userInitiated) { [weak self] in
      let result = await Self.parseAndPersist(url: url, repository: repo)
      await MainActor.run {
        self?.isAddingDocument = false
        switch result {
        case .success(let packWithDocId):
          self?.storePack(packWithDocId)
          self?.loadRecs()
        case .failure(let err):
          self?.addError = err.message
        }
      }
    }
  }

  /// Parses PDF off main thread and persists via repository. Returns pack for store or error message.
  private static func parseAndPersist(url: URL, repository: DocumentRepositoryProtocol) async -> Result<ReadPack, AddDocumentError> {
    let needsSecurityScope = url.startAccessingSecurityScopedResource()
    defer { if needsSecurityScope { url.stopAccessingSecurityScopedResource() } }

    let pack: ReadPack
    do {
      pack = try await PDFParser.parse(url: url)
    } catch {
      return .failure(AddDocumentError(message: "Couldn't read this PDF. It may be corrupted or unsupported."))
    }

    let docId = UUID()
    let title = pack.meta.title.isEmpty ? (url.deletingPathExtension().lastPathComponent) : pack.meta.title

    var bookmarkData: Data?
    do {
      bookmarkData = try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
    } catch {
      #if DEBUG
      print("[LibStore] bookmarkData failed for \(url.lastPathComponent): \(error); persisting with nil fileReference.")
      #endif
    }

    do {
      try repository.addDocument(identity: docId, title: title, addedAt: Date(), fileReference: bookmarkData)
    } catch {
      return .failure(AddDocumentError(message: "Couldn't save the document. Please try again."))
    }

    let packWithDocId = ReadPack(id: docId.uuidString, meta: pack.meta, secs: pack.secs, sents: pack.sents, figs: pack.figs)
    return .success(packWithDocId)
  }

  private func loadRecs() {
    do {
      let documents = try repository.fetchDocuments()
      recs = documents.map { documentToPaperRec($0) }
    } catch {
      recs = []
      #if DEBUG
      print("[LibStore] loadRecs failed: \(error)")
      #endif
    }
  }

  private func documentToPaperRec(_ doc: Document) -> PaperRec {
    PaperRec(
      id: doc.identity?.uuidString ?? UUID().uuidString,
      title: doc.title ?? "",
      auths: [],
      date: nil,
      addedAt: doc.addedAt ?? Date(),
      isRead: false
    )
  }

  /// Adds a document. Use `documentIdentity` and `pack` when adding from import so the pack is stored under the document id for getPack(id:).
  func add(_ r: PaperRec, documentIdentity: UUID? = nil, pack associatedPack: ReadPack? = nil) {
    let identity = documentIdentity ?? UUID()
    if recs.contains(where: { $0.id == identity.uuidString }) { return }
    do {
      try repository.addDocument(identity: identity, title: r.title, addedAt: r.addedAt, fileReference: nil)
      loadRecs()
      if let pack = associatedPack {
        let packWithDocId = ReadPack(id: identity.uuidString, meta: pack.meta, secs: pack.secs, sents: pack.sents, figs: pack.figs)
        storePack(packWithDocId)
      }
    } catch {
      addError = "Couldn't add the document. Please try again."
      #if DEBUG
      print("[LibStore] add failed: \(error)")
      #endif
    }
  }

  func delete(_ r: PaperRec) {
    do {
      let documents = try repository.fetchDocuments()
      guard let doc = documents.first(where: { $0.identity?.uuidString == r.id }) else { return }
      try repository.deleteDocument(doc)
      loadRecs()
    } catch {
      #if DEBUG
      print("[LibStore] delete failed: \(error)")
      #endif
    }
  }

  /// Marks a document as read (in-memory only; no persistence in this story).
  func markRead(id: String) {
    if let idx = recs.firstIndex(where: { $0.id == id }) {
      recs[idx].isRead = true
    }
  }

  func storePack(_ pack: ReadPack) {
    packs[pack.id] = pack
  }

  func getPack(id: String) -> ReadPack? {
    packs[id] ?? DemoData.pack(id: id)
  }

  /// Returns the Document for a given paper id if it exists in the repository (for use by FoldStore/QueueStore when they need Document reference).
  func document(byId id: String) -> Document? {
    (try? repository.fetchDocuments())?.first { $0.identity?.uuidString == id }
  }
}
