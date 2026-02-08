//
//  FoldRec.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/8/26.
//

import Foundation

struct FoldRec: Identifiable, Hashable {
  let id: String = UUID().uuidString
  var name: String
  var pids: [String] = [] // paper IDs
}
