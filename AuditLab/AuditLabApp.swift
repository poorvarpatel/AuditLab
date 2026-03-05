//
//  AuditLabApp.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/7/26.
//

internal import SwiftUI

@main
struct AuditLabApp: App {
  @StateObject private var lib: LibStore
  @StateObject private var q: QueueStore
  @StateObject private var set = AppSet()
  @StateObject private var folds: FoldStore
  @StateObject private var bus: NotifBus

  init() {
    let controller = PersistenceController()
    let repository = DocumentRepository(persistenceController: controller)
    _lib = StateObject(wrappedValue: LibStore(repository: repository))
    _q = StateObject(wrappedValue: QueueStore(repository: repository))
    _folds = StateObject(wrappedValue: FoldStore(repository: repository))
    _bus = StateObject(wrappedValue: NotifBus())
  }

  var body: some Scene {
    WindowGroup {
      RootView()
        .environmentObject(lib)
        .environmentObject(q)
        .environmentObject(set)
        .environmentObject(folds)
        .environmentObject(bus)
    }
  }
}
