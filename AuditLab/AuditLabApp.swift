//
//  AuditLabApp.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/7/26.
//

internal import SwiftUI

@main
struct AuditLabApp: App {
  private let persistenceController = PersistenceController.shared

  @StateObject private var lib: LibStore
  @StateObject private var q: QueueStore
  @StateObject private var set = AppSet()
  @StateObject private var folds: FoldStore

  init() {
    let repo = DocumentRepository(persistenceController: persistenceController)
    _lib = StateObject(wrappedValue: LibStore(repository: repo))
    _q = StateObject(wrappedValue: QueueStore(repository: repo))
    _folds = StateObject(wrappedValue: FoldStore(repository: repo))
  }

  var body: some Scene {
    WindowGroup {
      RootView()
        .environmentObject(lib)
        .environmentObject(q)
        .environmentObject(set)
        .environmentObject(folds)
    }
  }
}
