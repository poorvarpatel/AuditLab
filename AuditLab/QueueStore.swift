//
//  QueueStore.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/7/26.
//

import Foundation
import Combine
import CoreData
internal import SwiftUI

@MainActor
final class QueueStore: ObservableObject {
  @Published private(set) var entries: [QueueEntry] = []
  @Published var idx: Int = 0

  private let repository: DocumentRepositoryProtocol
  private var contextObserver: AnyCancellable?

  var items: [QItem] {
    entries.map { entryToQItem($0) }
  }

  // Folder playback state (in-memory)
  @Published var activeFolderId: String? = nil
  @Published var folderPapers: [QItem] = []
  @Published var folderIdx: Int = 0
  private var folderPapersMap: [String: [QItem]] = [:]

  nonisolated deinit {}

  init(repository: DocumentRepositoryProtocol) {
    self.repository = repository
    reloadFromContext()

    contextObserver = NotificationCenter.default
      .publisher(for: .NSManagedObjectContextObjectsDidChange, object: repository.viewContext)
      .sink { [weak self] _ in self?.reloadFromContext() }
  }

  // MARK: - Reactive reload

  func reloadFromContext() {
    do {
      entries = try repository.fetchQueueEntries()
      if idx >= items.count { idx = max(0, items.count - 1) }
    } catch {
      entries = []
      idx = 0
      #if DEBUG
      print("[QueueStore] reloadFromContext failed: \(error)")
      #endif
    }
  }

  // MARK: - Mutations (fire-and-forget; UI updates via observer)

  func add(_ it: QItem) {
    guard !items.contains(it) else { return }
    let nextIndex = Int32((try? repository.fetchQueueEntries().count) ?? 0)
    do {
      try repository.addQueueEntry(
        identity: UUID(),
        paperId: it.paperId,
        orderIndex: nextIndex,
        secOn: it.secOn,
        incApp: it.incApp,
        incSum: it.incSum,
        document: nil
      )
    } catch {
      #if DEBUG
      print("[QueueStore] add failed: \(error)")
      #endif
    }
  }

  func addFolder(_ folderId: String, papers: [QItem]) {
    folderPapersMap[folderId] = papers
    let nextIndex = Int32((try? repository.fetchQueueEntries().count) ?? 0)
    let marker = QItem(paperId: "folder:\(folderId)", secOn: [], incApp: false, incSum: false)
    do {
      try repository.addQueueEntry(
        identity: UUID(),
        paperId: marker.paperId,
        orderIndex: nextIndex,
        secOn: marker.secOn,
        incApp: marker.incApp,
        incSum: marker.incSum,
        document: nil
      )
    } catch {
      #if DEBUG
      print("[QueueStore] addFolder failed: \(error)")
      #endif
    }
  }

  func getFolderPapers(_ folderId: String) -> [QItem] {
    folderPapersMap[folderId] ?? []
  }

  func addMany(_ arr: [QItem]) {
    for it in arr { add(it) }
  }

  func rm(_ it: QItem) {
    guard let i = items.firstIndex(of: it), i < entries.count else { return }
    let entry = entries[i]
    do {
      try repository.deleteQueueEntry(entry)
    } catch {
      #if DEBUG
      print("[QueueStore] rm failed: \(error)")
      #endif
    }
  }

  func remove(atOffsets offsets: IndexSet) {
    let ctx = repository.viewContext
    var toRemove: [QueueEntry] = []
    for i in offsets where i < entries.count {
      toRemove.append(entries[i])
    }
    
    do {
      for entry in toRemove {
        ctx.delete(entry)
      }
      try ctx.save()
    } catch {
      #if DEBUG
      print("[QueueStore] remove(atOffsets:) failed: \(error)")
      #endif
    }
  }

  func move(fromOffsets source: IndexSet, toOffset destination: Int) {
    var reordered = entries
    reordered.move(fromOffsets: source, toOffset: destination)
    do {
      try repository.updateQueueOrder(entries: reordered)
    } catch {
      #if DEBUG
      print("[QueueStore] move failed: \(error)")
      #endif
    }
  }

  func move(from source: IndexSet, to destination: Int) {
    move(fromOffsets: source, toOffset: destination)
  }

  func clr() {
    do {
      try repository.deleteAllQueueEntries()
      activeFolderId = nil
      folderPapers = []
      folderPapersMap = [:]
      folderIdx = 0
    } catch {
      #if DEBUG
      print("[QueueStore] clr failed: \(error)")
      #endif
    }
  }

  // MARK: - Playback navigation

  func cur() -> QItem? {
    if activeFolderId != nil {
      guard !folderPapers.isEmpty, folderIdx >= 0, folderIdx < folderPapers.count else { return nil }
      return folderPapers[folderIdx]
    }
    guard !items.isEmpty, idx >= 0, idx < items.count else { return nil }
    return items[idx]
  }

  func next() {
    if activeFolderId != nil {
      if folderIdx < folderPapers.count - 1 {
        folderIdx += 1
      } else {
        endFolderPlayback()
        if idx < items.count - 1 {
          idx += 1
        } else {
          idx = items.count
        }
      }
    } else {
      guard !items.isEmpty else { return }
      if idx < items.count - 1 {
        idx += 1
      } else {
        idx = items.count
      }
    }
  }

  func prev() {
    if activeFolderId != nil {
      if folderIdx > 0 {
        folderIdx -= 1
      } else {
        endFolderPlayback()
        if idx > 0 {
          idx -= 1
        }
      }
    } else {
      guard !items.isEmpty else { return }
      idx = max(0, idx - 1)
    }
  }

  func startFolderPlayback(_ folderId: String, papers: [QItem]) {
    activeFolderId = folderId
    folderPapers = papers
    folderIdx = 0
  }

  func endFolderPlayback() {
    activeFolderId = nil
    folderPapers = []
    folderIdx = 0
  }

  // MARK: - Private

  private func entryToQItem(_ entry: QueueEntry) -> QItem {
    QItem(
      paperId: entry.paperId ?? "",
      secOn: DocumentRepository.decodeSecOn(entry.secOn),
      incApp: entry.incApp ?? true,
      incSum: entry.incSum ?? true
    )
  }
}
