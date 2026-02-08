//
//  AuditLabApp.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/7/26.
//

import SwiftUI

@main
struct AuditLabApp: App {
  @StateObject private var set = AppSet()
  @StateObject private var lib = LibStore()
  @StateObject private var q = QueueStore()

  var body: some Scene {
    WindowGroup {
      RootView()
        .environmentObject(set)
        .environmentObject(lib)
        .environmentObject(q)
    }
  }
}
