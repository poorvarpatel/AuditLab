//
//  FoldRec.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/8/26.
//

import Foundation

struct FoldRec: Identifiable, Hashable {
  let id: String
  var name: String
  var pids: [String] // paper IDs

  init(id: String = UUID().uuidString, name: String, pids: [String] = []) {
    self.id = id
    self.name = name
    self.pids = pids
  }
}
