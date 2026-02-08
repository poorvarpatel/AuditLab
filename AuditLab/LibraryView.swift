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

  @State private var sel: PaperRec? = nil
  @State private var showDet = false

  var body: some View {
    NavigationStack {
      List {
        Section("Papers") {
          ForEach(lib.recs) { r in
            Button {
              sel = r
              showDet = true
            } label: {
              VStack(alignment: .leading, spacing: 4) {
                Text(r.title)
                  .lineLimit(1)
                  .truncationMode(.tail)
                Text(sub(r))
                  .font(.caption)
                  .foregroundStyle(.secondary)
                  .lineLimit(1)
              }
            }
          }
        }
      }
      .navigationTitle("Library")
      .toolbar {
        Button("Add Demo") {
          let p = DemoData.pack()
          let r = DemoData.rec(for: p)
          lib.add(r)

          // For now, auto-add to queue so the Queue tab works immediately
          let it = DemoData.qitem(for: p)
          q.add(it)
        }
      }
      .sheet(isPresented: $showDet) {
        if let r = sel {
          PaperDetailView(rec: r)
        }
      }
    }
  }

  private func sub(_ r: PaperRec) -> String {
    var out: [String] = []
    if r.auths.count > 0 && r.auths.count <= 2 { out.append(r.auths.joined(separator: ", ")) }
    if let d = r.date { out.append(d) }
    return out.joined(separator: " • ")
  }
}

