//
//  FigurePanelView.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/7/26.
//

internal import SwiftUI

struct FigurePanelView: View {
  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 22)
        .fill(Color(.secondarySystemBackground))

      VStack(spacing: 10) {
        Image(systemName: "speaker.wave.2.fill")
          .font(.system(size: 34))
          .foregroundStyle(.secondary)

        Text("Listening Mode")
          .font(.title3.weight(.semibold))

        Text("Diagrams will appear here when\nmentioned.")
          .multilineTextAlignment(.center)
          .foregroundStyle(.secondary)
      }
      .padding()
    }
  }
}
