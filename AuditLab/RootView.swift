//
//  RootView.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/7/26.
//

import SwiftUI

struct RootView: View {
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
  }
}
