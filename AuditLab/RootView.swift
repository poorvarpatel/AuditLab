//
//  RootView.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/7/26.
//

internal import SwiftUI

struct RootView: View {
  @EnvironmentObject var lib: LibStore
  /// Used by UI tests: seed library when launch argument -TEST_SEED_LIBRARY is set (no-op in production).
  @State private var testSeedDone = false

  var body: some View {
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
    .onAppear {
      #if DEBUG
      guard !testSeedDone else { return }
      if ProcessInfo.processInfo.arguments.contains("-TEST_EMPTY_LIBRARY") {
        lib.clearAllDocumentsForTesting()
        testSeedDone = true
        return
      }
      if ProcessInfo.processInfo.arguments.contains("-TEST_SEED_LIBRARY") {
        lib.add(PaperRec(id: UUID().uuidString, title: "Test Paper A", auths: [], date: nil, addedAt: Date(), isRead: false))
        lib.add(PaperRec(id: UUID().uuidString, title: "Test Paper B", auths: [], date: nil, addedAt: Date(), isRead: false))
        testSeedDone = true
      }
      #endif
    }
  }
}
