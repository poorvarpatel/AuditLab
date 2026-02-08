//
//  RootView.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/7/26.
//

import SwiftUI

struct RootView: View {
  @Environment(\.horizontalSizeClass) private var hsc
  @State private var sel: Side = .lib

  var body: some View {
    if hsc == .regular {
      NavigationSplitView {
        List {
          sideRow(.lib, "Library", "books.vertical")
          sideRow(.queue, "Queue", "list.bullet")
          sideRow(.hist, "History", "clock")
          sideRow(.set, "Settings", "gearshape")
        }
        .navigationTitle("AuditLab")
      } detail: {
        switch sel {
        case .lib: LibraryView()
        case .queue: QueueView()
        case .hist: HistView()
        case .set: SetView()
        }
      }
    } else {
      TabView {
        LibraryView()
          .tabItem { Label("Library", systemImage: "books.vertical") }

        QueueView()
          .tabItem { Label("Queue", systemImage: "list.bullet") }

        HistView()
          .tabItem { Label("History", systemImage: "clock") }

        SetView()
          .tabItem { Label("Settings", systemImage: "gearshape") }
      }
    }
  }

  @ViewBuilder
  private func sideRow(_ s: Side, _ title: String, _ icon: String) -> some View {
    Button {
      sel = s
    } label: {
      HStack {
        Image(systemName: icon)
        Text(title)
        Spacer()
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .listRowBackground(sel == s ? Color.blue.opacity(0.12) : Color.clear)
  }

  private enum Side { case lib, queue, hist, set }
}
