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

// Queue item: can be a single paper or a folder
enum QueueItemType: Codable, Equatable {
  case paper(PaperQueueConfig)
  case folder(FolderQueueConfig)
}

// Configuration for a single paper in queue
struct PaperQueueConfig: Codable, Identifiable, Equatable {
  var id: String { paperId }
  var paperId: String
  var secOn: Set<String>
  var incApp: Bool
  var incSum: Bool
}

// Configuration for a folder in queue
struct FolderQueueConfig: Codable, Identifiable, Equatable {
  var id: String { folderId }
  var folderId: String
  var selectedPaperIds: [String] // which papers from folder to play
  var isExpanded: Bool = false // UI state for showing papers
}

// New queue item that can be paper or folder
struct QueueItem: Identifiable, Equatable {
  let id: String
  let type: QueueItemType
  
  init(paper: PaperQueueConfig) {
    self.id = "paper_\(paper.paperId)"
    self.type = .paper(paper)
  }
  
  init(folder: FolderQueueConfig) {
    self.id = "folder_\(folder.folderId)"
    self.type = .folder(folder)
  }
}

// Legacy QItem for compatibility - will phase out
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
  var isRead: Bool = false // track read status
}
