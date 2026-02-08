//
//  LibraryView.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/7/26.
//

internal import SwiftUI

struct LibraryView: View {
  @EnvironmentObject var lib: LibStore
  @EnvironmentObject var q: QueueStore
  @EnvironmentObject var set: AppSet
  @EnvironmentObject var folds: FoldStore

  @State private var sp: SpchPlayer? = nil
  @State private var showPlayer = false
  @State private var selectedFolderId: String? = nil
  @State private var showFolderDetail = false

  var body: some View {
    ZStack {
      Color(.systemGroupedBackground).ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: 18) {
          LibraryHeaderView(
            onAddPaper: { addDemo() },
            onAddFold: { folds.addNew() }
          )

          // Folders section
          if !folds.folds.isEmpty {
            FolderGridView(onTapFolder: { fold in
              selectedFolderId = fold.id
              showFolderDetail = true
            })
            .padding(.horizontal, 18)
          }

          // Papers section
          LazyVGrid(columns: cols(), spacing: 18) {
            ForEach(lib.recs) { r in
              LibraryCardView(
                rec: r,
                status: .ready,
                onPlay: { play(r) },
                onAddToQueue: { addToQueue(r) },
                onDelete: { delete(r) }
              )
              .frame(minHeight: 220)
            }
          }
          .padding(.horizontal, 18)
          .padding(.bottom, 24)
        }
      }
    }
    .sheet(isPresented: $showPlayer) {
      if let sp {
        PlayerView(sp: sp).environmentObject(set)
      } else {
        Text("No player loaded").padding()
      }
    }
    .sheet(isPresented: $showFolderDetail) {
      if let folderId = selectedFolderId {
        FolderDetailView(folderId: folderId)
          .environmentObject(lib)
          .environmentObject(folds)
          .environmentObject(q)
          .environmentObject(set)
      }
    }
  }

  private func cols() -> [GridItem] {
    [GridItem(.adaptive(minimum: 320), spacing: 18)]
  }

  private func play(_ r: PaperRec) {
    if sp == nil { sp = SpchPlayer(set: set) }
    guard let sp else { return }

    let p = DemoData.pack()
    let it = DemoData.qitem(for: p)

    q.add(it)
    q.idx = max(0, q.items.count - 1)

    sp.load(p, q: it)
    showPlayer = true
  }

  private func delete(_ r: PaperRec) {
    lib.recs.removeAll { $0.id == r.id }
  }
  
  private func addToQueue(_ r: PaperRec) {
    let p = DemoData.pack()
    let it = DemoData.qitem(for: p)
    q.add(it)
  }

  private func addDemo() {
    let p = DemoData.pack()
    let r = DemoData.rec(for: p)
    lib.add(r)
  }
}
