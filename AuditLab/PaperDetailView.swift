//
//  PaperDetailView.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/7/26.
//

internal import SwiftUI

struct PaperDetailView: View {
  @Environment(\.dismiss) private var dis
  @EnvironmentObject var q: QueueStore

  let rec: PaperRec

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 14) {
        Text(rec.title)
          .font(.title3.weight(.semibold))
          .lineLimit(2)

        Text(sub())
          .foregroundStyle(.secondary)

        Spacer()

        Button("Add to Queue") {
          let p = DemoData.pack() // temp: later we load by rec.id
          let it = DemoData.qitem(for: p)
          q.add(it)
          dis()
        }
        .buttonStyle(.borderedProminent)

        Button("Play Now") {
          let p = DemoData.pack()
          let it = DemoData.qitem(for: p)
          q.add(it)
          q.idx = max(0, q.items.count - 1)
          // Player opens from Queue tab for now
          dis()
        }
        .buttonStyle(.bordered)
      }
      .padding(16)
      .navigationTitle("Paper")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") { dis() }
        }
      }
    }
  }

  private func sub() -> String {
    var out: [String] = []
    if rec.auths.count > 0 && rec.auths.count <= 2 { out.append(rec.auths.joined(separator: ", ")) }
    if let d = rec.date { out.append(d) }
    return out.joined(separator: " • ")
  }
}
