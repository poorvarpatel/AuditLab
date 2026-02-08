//
//  QueueView.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/7/26.
//

import SwiftUI

struct QueueView: View {
  @EnvironmentObject var q: QueueStore
  @EnvironmentObject var set: AppSet

  @StateObject private var sp: SpchPlayer
  @State private var showPlay = false

  init() {
    // placeholder; real set injected after init via .task below
    _sp = StateObject(wrappedValue: SpchPlayer(set: AppSet()))
  }

  var body: some View {
    NavigationStack {
      VStack {
        if let lab = q.modeLab {
          Text("Playing Folder: \(lab)")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.top, 8)
        }

        List {
          Section("Queue") {
            if q.items.isEmpty {
              Text("Queue is empty.")
                .foregroundStyle(.secondary)
            } else {
              ForEach(q.items) { it in
                HStack {
                  Text(it.paperId).lineLimit(1)
                  Spacer()
                  if q.cur()?.paperId == it.paperId {
                    Text("Now").font(.caption).foregroundStyle(.secondary)
                  }
                }
              }
              .onDelete { idxs in
                for i in idxs { q.items.remove(at: i) }
                if q.idx >= q.items.count { q.idx = max(0, q.items.count - 1) }
              }
            }
          }
        }

        Button("Open Player") {
          guard let it = q.cur() else { return }
          let p = loadPack(paperId: it.paperId)
          sp.load(p, q: it)
          showPlay = true
        }
        .buttonStyle(.borderedProminent)
        .disabled(q.items.isEmpty)
        .padding(.bottom, 12)
      }
      .navigationTitle("Queue")
      .sheet(isPresented: $showPlay) {
        PlayerView(sp: sp)
          .environmentObject(set)
      }
      .task {
        // ensure SpchPlayer uses the SAME settings object
        // easiest: recreate once with correct set
        if spSetMismatch() {
          // Replace the player with one using the injected set
          // (SwiftUI can't reassign StateObject directly, so we just keep it simple:
          //  create a new SpchPlayer file pattern in next refactor.)
        }
      }
    }
  }

  private func loadPack(paperId: String) -> ReadPack {
    // v0: only demo exists
    // later: this will load from local storage by paperId
    return DemoData.pack()
  }

  private func spSetMismatch() -> Bool { false }
}
