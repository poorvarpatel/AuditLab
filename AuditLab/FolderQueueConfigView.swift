//
//  FolderQueueConfigView.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/8/26.
//

internal import SwiftUI

struct FolderQueueConfigView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject var lib: LibStore
  @EnvironmentObject var folds: FoldStore
  @EnvironmentObject var q: QueueStore
  
  let config: FolderQueueConfig
  let folderId: String
  
  @State private var selectedPaperIds: Set<String> = []
  
  private var folder: FoldRec? {
    folds.folds.first(where: { $0.id == folderId })
  }
  
  private var papers: [PaperRec] {
    guard let folder = folder else { return [] }
    return lib.recs.filter { folder.pids.contains($0.id) }
  }
  
  private var unreadPapers: [PaperRec] {
    papers.filter { !$0.isRead }
  }
  
  private var readPapers: [PaperRec] {
    papers.filter { $0.isRead }
  }
  
  var body: some View {
    NavigationStack {
      List {
        Section {
          Button {
            selectedPaperIds = Set(papers.map { $0.id })
          } label: {
            Label("Select All", systemImage: "checkmark.circle")
          }
          
          Button {
            selectedPaperIds.removeAll()
          } label: {
            Label("Deselect All", systemImage: "circle")
          }
          
          Button {
            selectedPaperIds = Set(unreadPapers.map { $0.id })
          } label: {
            Label("Unread Only", systemImage: "book.closed")
          }
          
          Button {
            selectedPaperIds = Set(readPapers.map { $0.id })
          } label: {
            Label("Read Only", systemImage: "book")
          }
        }
        
        Section("Papers") {
          ForEach(papers) { paper in
            HStack {
              VStack(alignment: .leading, spacing: 4) {
                Text(paper.title)
                  .font(.system(size: 16, weight: .semibold))
                  .lineLimit(2)
                
                if !paper.auths.isEmpty {
                  Text(paper.auths.joined(separator: ", "))
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }
                
                if paper.isRead {
                  Text("Read")
                    .font(.caption)
                    .foregroundStyle(.green)
                }
              }
              
              Spacer()
              
              if selectedPaperIds.contains(paper.id) {
                Image(systemName: "checkmark.circle.fill")
                  .foregroundStyle(.blue)
              } else {
                Image(systemName: "circle")
                  .foregroundStyle(.secondary)
              }
            }
            .contentShape(Rectangle())
            .onTapGesture {
              if selectedPaperIds.contains(paper.id) {
                selectedPaperIds.remove(paper.id)
              } else {
                selectedPaperIds.insert(paper.id)
              }
            }
          }
        }
      }
      .navigationTitle("Select Papers")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Cancel") { dismiss() }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
          Button("Add to Queue") {
            addToQueue()
            dismiss()
          }
          .disabled(selectedPaperIds.isEmpty)
        }
      }
      .onAppear {
        // Pre-select unread papers by default
        selectedPaperIds = Set(unreadPapers.map { $0.id })
      }
    }
  }
  
  private func addToQueue() {
    // Sort papers to play unread first
    let unreadIds = unreadPapers.map { $0.id }.filter { selectedPaperIds.contains($0) }
    let readIds = readPapers.map { $0.id }.filter { selectedPaperIds.contains($0) }
    let orderedIds = unreadIds + readIds
    
    // Create QItems for selected papers
    let queueItems = orderedIds.compactMap { paperId -> QItem? in
      // For now use demo pack - later we'll load actual paper
      let pack = DemoData.pack()
      var qitem = DemoData.qitem(for: pack)
      qitem.paperId = paperId // Use actual paper ID
      return qitem
    }
    
    // Add folder marker and papers to queue (they'll be stored in the map)
    q.addFolder(folderId, papers: queueItems)
  }
}
