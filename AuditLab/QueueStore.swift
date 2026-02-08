//
//  QueueStore.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/7/26.
//

import Foundation
import Combine
internal import SwiftUI

@MainActor
final class QueueStore: ObservableObject {
  @Published var items: [QItem] = []
  @Published var idx: Int = 0
  
  // Folder playback state
  @Published var activeFolderId: String? = nil
  @Published var folderPapers: [QItem] = [] // papers currently being played from folder
  @Published var folderIdx: Int = 0
  
  func add(_ it: QItem) {
    if !items.contains(it) { items.append(it) }
  }
  
  func addFolder(_ folderId: String, papers: [QItem]) {
    // Add a special marker item for folder
    let marker = QItem(paperId: "folder:\(folderId)", secOn: [], incApp: false, incSum: false)
    items.append(marker)
  }
  
  func addMany(_ arr: [QItem]) {
    for it in arr { add(it) }
  }
  
  func rm(_ it: QItem) {
    if let i = items.firstIndex(of: it) {
      items.remove(at: i)
      if idx >= items.count { idx = max(0, items.count - 1) }
    }
  }
  
  func move(from source: IndexSet, to destination: Int) {
    items.move(fromOffsets: source, toOffset: destination)
  }
  
  func clr() {
    items.removeAll()
    idx = 0
    activeFolderId = nil
    folderPapers.removeAll()
    folderIdx = 0
  }
  
  func cur() -> QItem? {
    // If in folder playback mode, return current folder paper
    if activeFolderId != nil {
      guard !folderPapers.isEmpty, folderIdx >= 0, folderIdx < folderPapers.count else { return nil }
      return folderPapers[folderIdx]
    }
    
    // Otherwise return current queue item
    guard !items.isEmpty, idx >= 0, idx < items.count else { return nil }
    return items[idx]
  }
  
  func next() {
    // If in folder mode, advance within folder
    if activeFolderId != nil {
      if folderIdx < folderPapers.count - 1 {
        folderIdx += 1
      } else {
        // Finished folder, exit folder mode and advance main queue
        endFolderPlayback()
        if idx < items.count - 1 {
          idx += 1
        }
      }
    } else {
      // Normal queue advance
      guard !items.isEmpty else { return }
      if idx < items.count - 1 {
        idx += 1
        // Check if next item is a folder
        checkAndStartFolder()
      }
    }
  }
  
  func prev() {
    if activeFolderId != nil {
      if folderIdx > 0 {
        folderIdx -= 1
      } else {
        // At start of folder, go back to previous queue item
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
    folderPapers.removeAll()
    folderIdx = 0
  }
  
  private func checkAndStartFolder() {
    guard let current = cur() else { return }
    if current.paperId.hasPrefix("folder:") {
      let folderId = String(current.paperId.dropFirst(7))
      // This will be triggered by the player to load folder papers
    }
  }
}
