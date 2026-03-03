//
//  LibStore.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/7/26.
//

import Foundation
import Combine
import CoreData

@MainActor
final class LibStore: ObservableObject {
  @Published var recs: [PaperRec] = []

  private let repository: DocumentRepositoryProtocol
  // Store parsed ReadPacks in memory (later: persist to disk)
  private var packs: [String: ReadPack] = [:]

  init(repository: DocumentRepositoryProtocol) {
    self.repository = repository
    loadRecs()
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
