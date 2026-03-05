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
  @Published var isAddingDocument = false
  @Published var addError: String?

  private let repository: DocumentRepositoryProtocol
  private var packs: [String: ReadPack] = [:]
  private var contextObserver: AnyCancellable?

  nonisolated deinit {}

  init(repository: DocumentRepositoryProtocol) {
    self.repository = repository
    // Initial load — viewContext is empty, so fetch from the store.
    reloadFromContext()

    // React to viewContext merges from background saves. The viewContext posts
    // NSManagedObjectContextObjectsDidChange on the main queue after
    // automaticallyMergesChangesFromParent processes a sibling save.
    // No manual re-fetch after writes needed — this single observer handles it.
    contextObserver = NotificationCenter.default
      .publisher(for: .NSManagedObjectContextObjectsDidChange, object: repository.viewContext)
      .sink { [weak self] _ in self?.reloadFromContext() }
  }

  // MARK: - Reactive reload

  func reloadFromContext() {
    do {
      let documents = try repository.fetchDocuments()
      recs = documents.map { documentToPaperRec($0) }
    } catch {
      recs = []
      #if DEBUG
      print("[LibStore] reloadFromContext failed: \(error)")
      #endif
    }
  }

  // MARK: - Mutations (fire-and-forget; UI updates via observer)

  func addDocument(from url: URL, cleanupURL: URL? = nil) {
    guard !isAddingDocument else { return }
    addError = nil
    isAddingDocument = true

    let repo = repository
    Task.detached(priority: .userInitiated) { [weak self] in
      let result = await Self.parseAndPersist(url: url, repository: repo)
      if let cleanupURL {
        try? FileManager.default.removeItem(at: cleanupURL)
      }
      await MainActor.run {
        self?.isAddingDocument = false
        switch result {
        case .success(let packWithDocId):
          self?.storePack(packWithDocId)
        case .failure(let err):
          self?.addError = err.message
        }
      }
    }
  }

  func add(_ r: PaperRec, documentIdentity: UUID? = nil, pack associatedPack: ReadPack? = nil) {
    let identity = documentIdentity ?? UUID()
    if recs.contains(where: { $0.id == identity.uuidString }) { return }
    do {
      try repository.addDocument(identity: identity, title: r.title, addedAt: r.addedAt, fileReference: nil)
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
    } catch {
      #if DEBUG
      print("[LibStore] delete failed: \(error)")
      #endif
    }
  }

  func markRead(id: String) {
    if let idx = recs.firstIndex(where: { $0.id == id }) {
      recs[idx].isRead = true
    }
  }

  // MARK: - Pack cache

  func storePack(_ pack: ReadPack) {
    packs[pack.id] = pack
    Self.persistPackToDisk(pack)
  }

  func getPack(id: String) -> ReadPack? {
    if let cached = packs[id] { return cached }
    if let loaded = Self.loadPackFromDisk(id: id) {
      packs[id] = loaded
      return loaded
    }
    return nil
  }

  func document(byId id: String) -> Document? {
    (try? repository.fetchDocuments())?.first { $0.identity?.uuidString == id }
  }

  // MARK: - Private

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

  // MARK: - Pack disk persistence

  private static var packsDirectory: URL {
    let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    return appSupport.appendingPathComponent("ReadPacks", isDirectory: true)
  }

  private static func persistPackToDisk(_ pack: ReadPack) {
    let dir = packsDirectory
    do {
      try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
      let data = try JSONEncoder().encode(pack)
      try data.write(to: dir.appendingPathComponent("\(pack.id).json"), options: .atomic)
    } catch {
      #if DEBUG
      print("[LibStore] persistPackToDisk failed: \(error)")
      #endif
    }
  }

  private static func loadPackFromDisk(id: String) -> ReadPack? {
    let url = packsDirectory.appendingPathComponent("\(id).json")
    guard let data = try? Data(contentsOf: url) else { return nil }
    return try? JSONDecoder().decode(ReadPack.self, from: data)
  }
}
