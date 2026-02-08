//
//  FolderGridView.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/8/26.
//

internal import SwiftUI

struct FolderGridView: View {
  @EnvironmentObject var folds: FoldStore
  @EnvironmentObject var lib: LibStore
  
  let onTapFolder: (FoldRec) -> Void
  
  let columns = [
    GridItem(.flexible(), spacing: 12),
    GridItem(.flexible(), spacing: 12),
    GridItem(.flexible(), spacing: 12),
    GridItem(.flexible(), spacing: 12)
  ]
  
  var body: some View {
    LazyVGrid(columns: columns, spacing: 12) {
      ForEach(folds.folds) { fold in
        FolderCardView(
          fold: fold,
          paperCount: fold.pids.count,
          readCount: readCount(for: fold),
          onTap: { onTapFolder(fold) }
        )
      }
    }
  }
  
  private func readCount(for fold: FoldRec) -> Int {
    // TODO: track read status in history
    // For now return 0
    return 0
  }
}

struct FolderCardView: View {
  let fold: FoldRec
  let paperCount: Int
  let readCount: Int
  let onTap: () -> Void
  
  var body: some View {
    VStack(spacing: 8) {
      // Folder icon with pie chart background
      ZStack {
        // Pie chart background (semi-transparent)
        if paperCount > 0 {
          Circle()
            .trim(from: 0, to: CGFloat(readCount) / CGFloat(paperCount))
            .stroke(Color.green.opacity(0.3), lineWidth: 3)
            .rotationEffect(.degrees(-90))
            .frame(width: 50, height: 50)
        }
        
        // Folder icon
        Image(systemName: "folder.fill")
          .font(.system(size: 28))
          .foregroundStyle(Color.blue)
      }
      
      // Count badge
      Text("\(paperCount)")
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(.secondary)
      
      // Folder name
      Text(fold.name)
        .font(.system(size: 13, weight: .medium))
        .lineLimit(2)
        .multilineTextAlignment(.center)
        .truncationMode(.tail)
    }
    .frame(height: 100)
    .padding(.vertical, 8)
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .onTapGesture {
      onTap()
    }
  }
}
