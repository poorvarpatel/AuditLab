//
//  FoldRec.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/8/26.
//

import Foundation

struct FoldRec: Identifiable, Hashable {
  let id: UUID = UUID()
  var name: String
  var pids: [UUID] = []
}
