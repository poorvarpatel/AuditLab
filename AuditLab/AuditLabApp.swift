//
//  AuditLabApp.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/7/26.
//

import SwiftUI

@main
struct AuditLabApp: App {
  @StateObject private var lib = LibStore()
  @StateObject private var q = QueueStore()
  @StateObject private var set = AppSet()
  @StateObject private var folds = FoldStore()

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
