//
//  FolderDetailView.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/8/26.
//

internal import SwiftUI

struct FolderDetailView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject var lib: LibStore
  @EnvironmentObject var folds: FoldStore
  @EnvironmentObject var q: QueueStore
  @EnvironmentObject var set: AppSet
  
  let folderId: String
  
  @State private var showAddPapers = false
  @State private var showPlayer = false
  @State private var sp: SpchPlayer? = nil
  @State private var showRenameAlert = false
  @State private var renameText = ""
  @State private var showFolderQueueConfig = false
  
  private var folder: FoldRec? {
    folds.folds.first(where: { $0.id == folderId })
  }
  
  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        if let folder = folder {
          // Papers in folder
          if papersInFolder(folder).isEmpty {
            emptyState()
          } else {
            ScrollView {
              LazyVStack(spacing: 12) {
                ForEach(papersInFolder(folder)) { rec in
                  PaperRowView(
                    rec: rec,
                    onPlay: { play(rec) },
                    onRemove: { removeFromFolder(rec, folder: folder) },
                    onAddToFolder: { /* TODO */ }
                  )
                }
              }
              .padding()
            }
          }
        } else {
          Text("Folder not found")
            .foregroundStyle(.secondary)
        }
      }
      .navigationTitle(folder?.name ?? "Folder")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .principal) {
          if let fold = folder {
            Text(fold.name)
              .font(.headline)
              .onLongPressGesture {
                renameText = fold.name
                showRenameAlert = true
              }
          }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
          Menu {
            Button {
              showAddPapers = true
            } label: {
              Label("Add Papers", systemImage: "doc.badge.plus")
            }
            
            Button {
              addFolderToQueue()
            } label: {
              Label("Add to Queue", systemImage: "text.badge.plus")
            }
          } label: {
            Image(systemName: "ellipsis.circle")
          }
        }
        
        ToolbarItem(placement: .topBarLeading) {
          Button("Done") { dismiss() }
        }
      }
      .alert("Rename Folder", isPresented: $showRenameAlert) {
        TextField("Folder name", text: $renameText)
        Button("Cancel", role: .cancel) { }
        Button("Save") {
          if !renameText.isEmpty {
            folds.rename(folderId, to: renameText)
          }
        }
      } message: {
        Text("Enter a new name for this folder")
      }
      .sheet(isPresented: $showAddPapers) {
        if folder != nil {
          AddPapersToFolderView(folderId: folderId)
            .environmentObject(lib)
            .environmentObject(folds)
        }
      }
      .sheet(isPresented: $showPlayer) {
        if let sp {
          PlayerView(sp: sp).environmentObject(set)
        }
      }
      .sheet(isPresented: $showFolderQueueConfig) {
        if let fold = folder {
          FolderQueueConfigView(
            config: FolderQueueConfig(folderId: fold.id, selectedPaperIds: []),
            folderId: fold.id
          )
          .environmentObject(lib)
          .environmentObject(folds)
          .environmentObject(q)
        }
      }
    }
  }
  
  private func addFolderToQueue() {
    showFolderQueueConfig = true
  }
  
  private func papersInFolder(_ folder: FoldRec) -> [PaperRec] {
    lib.recs.filter { folder.pids.contains($0.id) }
  }
  
  private func emptyState() -> some View {
    VStack(spacing: 16) {
      Image(systemName: "folder")
        .font(.system(size: 60))
        .foregroundStyle(.secondary)
      
      Text("No papers in this folder")
        .font(.title3.weight(.semibold))
      
      Text("Tap + to add papers")
        .foregroundStyle(.secondary)
      
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.top, 60)
  }
  
  private func play(_ rec: PaperRec) {
    if sp == nil { sp = SpchPlayer(set: set) }
    guard let sp else { return }
    
    let p = DemoData.pack()
    let it = DemoData.qitem(for: p)
    
    q.add(it)
    q.idx = max(0, q.items.count - 1)
    
    sp.load(p, q: it)
    showPlayer = true
  }
  
  private func removeFromFolder(_ rec: PaperRec, folder: FoldRec) {
    folds.removePaper(rec.id, from: folder.id)
  }
}

struct PaperRowView: View {
  let rec: PaperRec
  let onPlay: () -> Void
  let onRemove: () -> Void
  let onAddToFolder: () -> Void
  
  var body: some View {
    HStack(spacing: 12) {
      // Icon
      Image(systemName: "doc.text.fill")
        .font(.system(size: 24))
        .foregroundStyle(.blue)
        .frame(width: 40)
      
      // Title + authors
      VStack(alignment: .leading, spacing: 4) {
        Text(rec.title)
          .font(.system(size: 16, weight: .semibold))
          .lineLimit(2)
        
        if !rec.auths.isEmpty {
          Text(rec.auths.joined(separator: ", "))
            .font(.system(size: 14))
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }
      
      Spacer()
      
      // Actions menu
      Menu {
        Button {
          onPlay()
        } label: {
          Label("Play", systemImage: "play.fill")
        }
        
        Button {
          // Add to queue - will pass this up
        } label: {
          Label("Add to Queue", systemImage: "text.badge.plus")
        }
        
        Button {
          onAddToFolder()
        } label: {
          Label("Add to Folder", systemImage: "folder.badge.plus")
        }
        
        Button(role: .destructive) {
          onRemove()
        } label: {
          Label("Remove from Folder", systemImage: "folder.badge.minus")
        }
      } label: {
        Image(systemName: "ellipsis.circle")
          .font(.system(size: 20))
          .foregroundStyle(.secondary)
      }
    }
    .padding()
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
}

struct AddPapersToFolderView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject var lib: LibStore
  @EnvironmentObject var folds: FoldStore
  
  let folderId: String
  
  private var folder: FoldRec? {
    folds.folds.first(where: { $0.id == folderId })
  }
  
  var body: some View {
    NavigationStack {
      List {
        if let folder = folder {
          ForEach(unclaimedPapers(folder)) { rec in
            Button {
              folds.addPaper(rec.id, to: folder.id)
              dismiss()
            } label: {
              HStack {
                VStack(alignment: .leading, spacing: 4) {
                  Text(rec.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                  
                  if !rec.auths.isEmpty {
                    Text(rec.auths.joined(separator: ", "))
                      .font(.system(size: 14))
                      .foregroundStyle(.secondary)
                      .lineLimit(1)
                  }
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                  .foregroundStyle(.blue)
              }
            }
          }
        }
      }
      .navigationTitle("Add Papers")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Cancel") { dismiss() }
        }
      }
    }
  }
  
  private func unclaimedPapers(_ folder: FoldRec) -> [PaperRec] {
    // Papers can be in multiple folders, so show all papers not yet in this folder
    lib.recs.filter { !folder.pids.contains($0.id) }
  }
}
