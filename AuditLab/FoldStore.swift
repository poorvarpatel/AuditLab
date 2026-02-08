//
//  FoldStore.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/8/26.
//

import Foundation
import Combine

@MainActor
final class FoldStore: ObservableObject {
  @Published var folds: [FoldRec] = []

  func addNew(name: String = "New Folder") {
    folds.insert(FoldRec(name: name), at: 0)
  }

  func rename(_ id: String, to newName: String) {
    guard let i = folds.firstIndex(where: { $0.id == id }) else { return }
    folds[i].name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  func addPaper(_ pid: String, to foldId: String) {
    guard let i = folds.firstIndex(where: { $0.id == foldId }) else { return }
    if !folds[i].pids.contains(pid) { folds[i].pids.append(pid) }
  }
  
  func removePaper(_ pid: String, from foldId: String) {
    guard let i = folds.firstIndex(where: { $0.id == foldId }) else { return }
    folds[i].pids.removeAll { $0 == pid }
  }
  
  func deleteFolder(_ id: String) {
    folds.removeAll { $0.id == id }
  }
  
  func moveFolder(from source: Int, to destination: Int) {
    guard source < folds.count, destination < folds.count else { return }
    let fold = folds.remove(at: source)
    folds.insert(fold, at: destination)
  }
}
