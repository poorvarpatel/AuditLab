//
//  LibraryView.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/7/26.
//

import SwiftUI

struct LibraryView: View {
  @EnvironmentObject var lib: LibStore
  @EnvironmentObject var q: QueueStore
  @EnvironmentObject var set: AppSet

  @State private var sp: SpchPlayer? = nil
  @State private var showPlayer = false

  var body: some View {
    ZStack {
      Color(.systemGroupedBackground).ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: 18) {
          LibraryHeaderView {
            addDemo()
          }

          LazyVGrid(columns: cols(), spacing: 18) {
            ForEach(lib.recs) { r in
              LibraryCardView(
                rec: r,
                status: status(for: r),
                onPlay: { play(r) },
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
        PlayerView(sp: sp)
          .environmentObject(set)
      } else {
        Text("No player loaded")
          .padding()
      }
    }
  }

  private func cols() -> [GridItem] {
    [GridItem(.adaptive(minimum: 320), spacing: 18)]
  }

  private func status(for r: PaperRec) -> PaperStatus {
    .ready
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

  private func addDemo() {
    let p = DemoData.pack()
    let r = DemoData.rec(for: p)
    lib.add(r)
  }
}
