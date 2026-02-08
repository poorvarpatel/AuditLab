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

  func add(_ r: PaperRec) {
    if recs.contains(where: { $0.id == r.id }) { return }
    recs.insert(r, at: 0)
  }
}
