//
//  FoldStore.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/8/26.
//

import Foundation
import Combine
import CoreData

@MainActor
final class FoldStore: ObservableObject {
  @Published var folds: [FoldRec] = []

  private let repository: DocumentRepositoryProtocol

  init(repository: DocumentRepositoryProtocol) {
    self.repository = repository
    loadFolds()
  }

  private func loadFolds() {
    do {
      let folderList = try repository.fetchFolders()
      var result: [FoldRec] = []
      for folder in folderList {
        let docs = try repository.fetchDocumentsInFolder(folder)
        let pids = docs.compactMap { $0.identity?.uuidString }
        result.append(FoldRec(
          id: folder.identity?.uuidString ?? UUID().uuidString,
          name: folder.name ?? "",
          pids: pids
        ))
      }
      folds = result
    } catch {
      folds = []
      #if DEBUG
      print("[FoldStore] loadFolds failed: \(error)")
      #endif
    }
  }

  private func folder(byId id: String) -> Folder? {
    (try? repository.fetchFolders())?.first { $0.identity?.uuidString == id }
  }

  private func document(byId id: String) -> Document? {
    (try? repository.fetchDocuments())?.first { $0.identity?.uuidString == id }
  }

  func addNew(name: String = "New Folder") {
    let identity = UUID()
    do {
      try repository.addFolder(identity: identity, name: name, createdAt: Date())
      loadFolds()
    } catch {
      #if DEBUG
      print("[FoldStore] addNew failed: \(error)")
      #endif
    }
  }

  func rename(_ id: String, to newName: String) {
    guard let folder = folder(byId: id) else { return }
    let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
    do {
      try repository.updateFolderName(folder, name: trimmed)
      loadFolds()
    } catch {
      #if DEBUG
      print("[FoldStore] rename failed: \(error)")
      #endif
    }
  }

  func addPaper(_ pid: String, to foldId: String) {
    guard let doc = document(byId: pid), let folder = folder(byId: foldId) else { return }
    do {
      try repository.addDocumentToFolder(document: doc, folder: folder)
      loadFolds()
    } catch {
      #if DEBUG
      print("[FoldStore] addPaper failed: \(error)")
      #endif
    }
  }

  func removePaper(_ pid: String, from foldId: String) {
    guard let doc = document(byId: pid), let folder = folder(byId: foldId) else { return }
    do {
      try repository.removeDocumentFromFolder(document: doc, folder: folder)
      loadFolds()
    } catch {
      #if DEBUG
      print("[FoldStore] removePaper failed: \(error)")
      #endif
    }
  }

  func deleteFolder(_ id: String) {
    guard let folder = folder(byId: id) else { return }
    do {
      try repository.deleteFolder(folder)
      loadFolds()
    } catch {
      #if DEBUG
      print("[FoldStore] deleteFolder failed: \(error)")
      #endif
    }
  }

  /// Reorders folds in the published array (UI order only; Core Data has no folder order).
  func moveFolder(from source: Int, to destination: Int) {
    guard source < folds.count, destination < folds.count else { return }
    let fold = folds.remove(at: source)
    folds.insert(fold, at: destination)
  }
}
