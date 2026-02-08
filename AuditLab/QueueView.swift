//
//  QueueView.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/8/26.
//

internal import SwiftUI

struct QueueView: View {
  @EnvironmentObject var q: QueueStore
  @EnvironmentObject var lib: LibStore
  @EnvironmentObject var folds: FoldStore
  @EnvironmentObject var set: AppSet
  
  @StateObject private var sp: SpchPlayer
  @State private var showPlayer = false
  @State private var selectedFolderConfig: FolderQueueConfig? = nil
  @State private var showFolderConfig = false
  
  init() {
    _sp = StateObject(wrappedValue: SpchPlayer(set: AppSet()))
  }
  
  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        if q.items.isEmpty {
          emptyState()
        } else {
          List {
            ForEach(Array(q.items.enumerated()), id: \.element.id) { index, item in
              QueueItemRow(
                item: item,
                isCurrent: index == q.idx,
                onTap: { },
                onDelete: { q.rm(item) }
              )
            }
            .onDelete { indexSet in
              for i in indexSet {
                q.items.remove(at: i)
              }
              if q.idx >= q.items.count {
                q.idx = max(0, q.items.count - 1)
              }
            }
            .onMove { source, destination in
              q.items.move(fromOffsets: source, toOffset: destination)
            }
          }
          .listStyle(.plain)
          
          // Play button
          Button {
            guard let item = q.cur() else { return }
            playQueueItem(item)
          } label: {
            HStack {
              Image(systemName: "play.circle.fill")
                .font(.system(size: 20))
              Text("Open Player")
                .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
          }
          .buttonStyle(.borderedProminent)
          .padding()
        }
      }
      .navigationTitle("Queue")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          EditButton()
        }
      }
      .sheet(isPresented: $showPlayer) {
        PlayerView(sp: sp)
          .environmentObject(set)
      }
      .sheet(isPresented: $showFolderConfig) {
        if let config = selectedFolderConfig {
          FolderQueueConfigView(config: config, folderId: config.folderId)
            .environmentObject(lib)
            .environmentObject(folds)
        }
      }
    }
  }
  
  private func emptyState() -> some View {
    VStack(spacing: 16) {
      Image(systemName: "list.bullet")
        .font(.system(size: 60))
        .foregroundStyle(.secondary)
      
      Text("Queue is empty")
        .font(.title3.weight(.semibold))
      
      Text("Add papers from your library")
        .foregroundStyle(.secondary)
      
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.top, 60)
  }
  
  private func playQueueItem(_ item: QItem) {
    // Check if this is a folder
    if item.paperId.hasPrefix("folder:") {
      let folderId = String(item.paperId.dropFirst(7))
      let folderPapers = q.getFolderPapers(folderId)
      
      if !folderPapers.isEmpty {
        q.startFolderPlayback(folderId, papers: folderPapers)
        if let firstPaper = folderPapers.first {
          let pack = loadPack(paperId: firstPaper.paperId)
          sp.load(pack, q: firstPaper)
          showPlayer = true
        }
      }
    } else {
      // Regular paper
      let pack = loadPack(paperId: item.paperId)
      sp.load(pack, q: item)
      showPlayer = true
    }
  }
  
  private func loadPack(paperId: String) -> ReadPack {
    // Load by ID - for demo papers this works, later will load from storage
    return DemoData.pack(id: paperId)
  }
}

struct QueueItemRow: View {
  let item: QItem
  let isCurrent: Bool
  let onTap: () -> Void
  let onDelete: () -> Void
  
  @EnvironmentObject var lib: LibStore
  @EnvironmentObject var folds: FoldStore
  @EnvironmentObject var q: QueueStore
  
  @State private var isExpanded = false
  
  private var isFolder: Bool {
    item.paperId.hasPrefix("folder:")
  }
  
  private var folderId: String? {
    guard isFolder else { return nil }
    return String(item.paperId.dropFirst(7))
  }
  
  private var folder: FoldRec? {
    guard let id = folderId else { return nil }
    return folds.folds.first(where: { $0.id == id })
  }
  
  private var paper: PaperRec? {
    guard !isFolder else { return nil }
    return lib.recs.first(where: { $0.id == item.paperId })
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      if isFolder {
        folderRow()
        if isExpanded {
          folderPapersView()
        }
      } else {
        paperRow()
      }
    }
  }
  
  private func folderRow() -> some View {
    let paperCount = folderId.map { q.getFolderPapers($0).count } ?? 0
    
    return HStack(spacing: 12) {
      // Current indicator
      if isCurrent {
        Circle()
          .fill(Color.blue)
          .frame(width: 8, height: 8)
      } else {
        Circle()
          .fill(Color.clear)
          .frame(width: 8, height: 8)
      }
      
      // Folder icon
      Image(systemName: isExpanded ? "folder.fill.badge.minus" : "folder.fill.badge.plus")
        .foregroundStyle(.blue)
      
      // Folder info
      VStack(alignment: .leading, spacing: 4) {
        Text(folder?.name ?? "Unknown Folder")
          .font(.system(size: 16, weight: isCurrent ? .semibold : .regular))
          .lineLimit(1)
        
        Text("\(paperCount) papers")
          .font(.system(size: 14))
          .foregroundStyle(.secondary)
      }
      
      Spacer()
      
      if isCurrent {
        Text("Now")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.blue)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(Color.blue.opacity(0.1))
          .clipShape(Capsule())
      }
      
      // Expand/collapse button
      Image(systemName: "chevron.right")
        .rotationEffect(.degrees(isExpanded ? 90 : 0))
        .foregroundStyle(.secondary)
    }
    .padding(.vertical, 4)
    .contentShape(Rectangle())
    .onTapGesture {
      withAnimation {
        isExpanded.toggle()
      }
    }
  }
  
  private func folderPapersView() -> some View {
    let papers = folderId.flatMap { q.getFolderPapers($0) } ?? []
    
    return VStack(alignment: .leading, spacing: 8) {
      ForEach(Array(papers.enumerated()), id: \.element.id) { index, folderItem in
        HStack(spacing: 12) {
          // Indentation
          Color.clear.frame(width: 28)
          
          // Current indicator for folder papers
          if q.activeFolderId == folderId && index == q.folderIdx {
            Circle()
              .fill(Color.green)
              .frame(width: 6, height: 6)
          } else {
            Circle()
              .fill(Color.clear)
              .frame(width: 6, height: 6)
          }
          
          let folderPaper = lib.recs.first(where: { $0.id == folderItem.paperId })
          
          VStack(alignment: .leading, spacing: 2) {
            Text(folderPaper?.title ?? folderItem.paperId)
              .font(.system(size: 14))
              .lineLimit(1)
            
            if let p = folderPaper, !p.auths.isEmpty {
              Text(p.auths.joined(separator: ", "))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
          }
          
          Spacer()
        }
        .padding(.vertical, 4)
      }
    }
    .padding(.leading, 8)
  }
  
  private func paperRow() -> some View {
    HStack(spacing: 12) {
      // Current indicator
      if isCurrent {
        Circle()
          .fill(Color.blue)
          .frame(width: 8, height: 8)
      } else {
        Circle()
          .fill(Color.clear)
          .frame(width: 8, height: 8)
      }
      
      // Paper info
      VStack(alignment: .leading, spacing: 4) {
        Text(paper?.title ?? item.paperId)
          .font(.system(size: 16, weight: isCurrent ? .semibold : .regular))
          .lineLimit(2)
        
        if let p = paper, !p.auths.isEmpty {
          Text(p.auths.joined(separator: ", "))
            .font(.system(size: 14))
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }
      
      Spacer()
      
      if isCurrent {
        Text("Now")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.blue)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(Color.blue.opacity(0.1))
          .clipShape(Capsule())
      }
    }
    .padding(.vertical, 4)
    .contentShape(Rectangle())
    .onTapGesture {
      onTap()
    }
  }
}
