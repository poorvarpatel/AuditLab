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

  func rename(_ id: UUID, to newName: String) {
    guard let i = folds.firstIndex(where: { $0.id == id }) else { return }
    folds[i].name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  func addPaper(_ pid: UUID, to foldId: UUID) {
    guard let i = folds.firstIndex(where: { $0.id == foldId }) else { return }
    if !folds[i].pids.contains(pid) { folds[i].pids.append(pid) }
  }
}

