//
//  QueueStore.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/7/26.
//

import Foundation
import Combine

final class QueueStore: ObservableObject {
  @Published var items: [QItem] = []
  @Published var idx: Int = 0

  // Folder “inject” mode (display folder name + prev/current/next)
  @Published var modeLab: String? = nil
  private var saved: [QItem]? = nil
  private var savedIdx: Int? = nil

  func add(_ it: QItem) {
    if !items.contains(it) { items.append(it) }
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

  func clr() {
    items.removeAll()
    idx = 0
    modeLab = nil
    saved = nil
    savedIdx = nil
  }

  func cur() -> QItem? {
    guard !items.isEmpty, idx >= 0, idx < items.count else { return nil }
    return items[idx]
  }

  func next() {
    guard !items.isEmpty else { return }
    idx = min(items.count - 1, idx + 1)
  }

  func prev() {
    guard !items.isEmpty else { return }
    idx = max(0, idx - 1)
  }

  // Temporarily replace queue with a folder play list
  func inject(folder name: String, arr: [QItem]) {
    saved = items
    savedIdx = idx
    items = arr
    idx = 0
    modeLab = name
  }

  func endInject() {
    guard let s = saved, let si = savedIdx else { return }
    items = s
    idx = min(max(0, si), max(0, items.count - 1))
    modeLab = nil
    saved = nil
    savedIdx = nil
  }
}
