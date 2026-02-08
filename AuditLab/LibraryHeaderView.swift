//
//  LibraryHeaderView.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/7/26.
//

import SwiftUI

struct LibraryHeaderView: View {
  let onAdd: () -> Void

  var body: some View {
    HStack(alignment: .top) {
      VStack(alignment: .leading, spacing: 8) {
        Text("My Library")
          .font(.system(size: 44, weight: .bold, design: .serif))

        Text("Manage and listen to\nyour academic papers.")
          .font(.system(size: 18, weight: .medium))
          .foregroundStyle(.secondary)
      }

      Spacer()

      Button(action: onAdd) {
        HStack(spacing: 10) {
          Image(systemName: "plus")
          Text("Add Paper")
            .font(.system(size: 18, weight: .semibold))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
      }
      .buttonStyle(.borderedProminent)
      .tint(.blue)
      .clipShape(Capsule())
      .shadow(color: Color.blue.opacity(0.18), radius: 14, x: 0, y: 10)
    }
    .padding(.horizontal, 18)
    .padding(.top, 10)
  }
}
