//
//  Types.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/7/26.
//

import Foundation

struct ReadPack: Codable, Identifiable {
  var id: String
  var meta: Meta
  var secs: [Sec]
  var sents: [Sent]
  var figs: [Fig]
}

struct Meta: Codable {
  var title: String
  var auths: [String]
  var date: String?
}

struct Sec: Codable, Identifiable {
  var id: String
  var title: String
  var kind: String // "body" "appendix" "bib" "sum"
  var sentIds: [String]
  var defOn: Bool
}

struct Sent: Codable, Identifiable {
  var id: String
  var secId: String
  var text: String
  var figIds: [String]? // ["Figure 1"]
}

struct Fig: Codable, Identifiable {
  var id: String
  var label: String
  var url: String
  var cap: String?
}

// Queue item: what to read for a paper
struct QItem: Codable, Identifiable, Equatable {
  var id: String { paperId }
  var paperId: String
  var secOn: Set<String>
  var incApp: Bool
  var incSum: Bool
}

// Simple library record
struct PaperRec: Codable, Identifiable, Equatable {
  var id: String
  var title: String
  var auths: [String]
  var date: String?
  var addedAt: Date
}

