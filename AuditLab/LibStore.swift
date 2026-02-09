//
//  LibStore.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/7/26.
//

import Foundation
import Combine

final class LibStore: ObservableObject {
  @Published var recs: [PaperRec] = []
  
  // Store parsed ReadPacks in memory (later: persist to disk)
  private var packs: [String: ReadPack] = [:]

  func add(_ r: PaperRec) {
    if recs.contains(where: { $0.id == r.id }) { return }
    recs.insert(r, at: 0)
  }
  
  func storePack(_ pack: ReadPack) {
    packs[pack.id] = pack
  }
  
  func getPack(id: String) -> ReadPack? {
    return packs[id] ?? DemoData.pack(id: id)
  }
}
