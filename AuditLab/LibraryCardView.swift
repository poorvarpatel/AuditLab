//
//  LibraryCardView.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/7/26.
//

import SwiftUI

struct LibraryCardView: View {
  let rec: PaperRec
  let status: PaperStatus
  let onPlay: () -> Void
  let onDelete: () -> Void

  var body: some View {
    VStack(spacing: 0) {

      // Top content
      VStack(alignment: .leading, spacing: 10) {
        HStack(alignment: .top) {
          iconBox()

          Spacer()

          Button(action: onDelete) {
            Image(systemName: "trash")
              .font(.system(size: 16, weight: .regular))
              .foregroundStyle(.secondary)
              .padding(6)
          }
          .buttonStyle(.plain)
        }

        Text(rec.title)
          .font(.system(size: 28, weight: .semibold, design: .serif))
          .foregroundStyle(.primary)
          .lineLimit(2)
          .truncationMode(.tail)

        Text(authLine())
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(.secondary)
          .lineLimit(1)

        Text(pubLine())
          .font(.system(size: 15))
          .foregroundStyle(.secondary)
          .lineLimit(1)

        Spacer(minLength: 6)
      }
      .padding(18)

      // Bottom status bar
      bottomBar()
    }
    .background(
      RoundedRectangle(cornerRadius: 22)
        .fill(Color(.systemBackground))
        .shadow(color: Color.black.opacity(0.06), radius: 18, x: 0, y: 10)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 22)
        .stroke(Color.black.opacity(0.06), lineWidth: 1)
    )
  }

  private func iconBox() -> some View {
    ZStack {
      RoundedRectangle(cornerRadius: 14)
        .fill(Color.blue.opacity(0.12))
        .frame(width: 44, height: 44)

      Image(systemName: "doc.text")
        .font(.system(size: 20, weight: .semibold))
        .foregroundStyle(Color.blue)
    }
  }

  private func bottomBar() -> some View {
    HStack {
      HStack(spacing: 8) {
        statusIcon()
        Text(statusText())
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(statusColor())
      }

      Spacer()

      if status == .ready {
        Button(action: onPlay) {
          HStack(spacing: 8) {
            Image(systemName: "play.circle.fill")
            Text("Play")
              .font(.system(size: 16, weight: .semibold))
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 10)
        }
        .buttonStyle(.borderedProminent)
        .tint(.blue)
      } else {
        Text(statusRightText())
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(.secondary)
      }
    }
    .padding(.horizontal, 18)
    .padding(.vertical, 14)
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 22))
  }

  private func statusIcon() -> some View {
    Image(systemName: status == .ready ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
      .foregroundStyle(statusColor())
  }

  private func statusColor() -> Color {
    status == .ready ? .green : .red
  }

  private func statusText() -> String {
    status == .ready ? "Ready" : "Error"
  }

  private func statusRightText() -> String {
    status == .ready ? "" : "Wait…"
  }

  private func authLine() -> String {
    if rec.auths.isEmpty { return "Unknown Authors" }
    return rec.auths.joined(separator: ", ")
  }

  private func pubLine() -> String {
    let d = rec.date ?? "—"
    return "Published \(d)"
  }
}

// For v0: hardcode status, later tie to parse state
enum PaperStatus: Equatable {
  case ready
  case error
}
