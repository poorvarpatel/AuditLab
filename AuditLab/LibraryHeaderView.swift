//
//  LibraryHeaderView.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/7/26.
//

internal import SwiftUI

struct LibraryHeaderView: View {
  var onAddPaper: () -> Void
  var onAddFold: () -> Void

  var body: some View {
    HStack(alignment: .top) {
      VStack(alignment: .leading, spacing: 8) {
        Text("My Library")
          .font(.system(size: 44, weight: .bold, design: .serif))

        Text("Manage and listen to\nyour academic\npapers.")
          .foregroundStyle(.secondary)
      }

      Spacer()

      VStack(alignment: .trailing, spacing: 10) {
        Button(action: onAddPaper) {
          Label("Add Paper", systemImage: "plus")
            .font(.headline)
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
        }
        .buttonStyle(.borderedProminent)
        .clipShape(Capsule())

        Button(action: onAddFold) {
          Image(systemName: "folder.badge.plus")
            .font(.system(size: 14, weight: .semibold))
            .frame(width: 34, height: 34)
        }
        .buttonStyle(.bordered)
        .clipShape(Circle())
        .accessibilityLabel("Add Folder")
      }
    }
    .padding(.horizontal, 18)
    .padding(.top, 10)
  }
}

