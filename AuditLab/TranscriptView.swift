//
//  TranscriptView.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/7/26.
//

internal import SwiftUI
import Combine

struct TranscriptView: View {
  @ObservedObject var sp: SpchPlayer
  @EnvironmentObject var set: AppSet

  @State private var userScr: Bool = false

  var body: some View {
    VStack(spacing: 10) {
      if let h = sp.headTxt {
        Text(h)
          .font(.title3.weight(.semibold))
          .multilineTextAlignment(.center)
          .padding(.vertical, 18)
      } else {
        ScrollViewReader { proxy in
          ScrollView {
            VStack(alignment: .leading, spacing: 12) {
              ForEach(lines(), id: \.id) { row in
                Text(row.text)
                  .font(.system(size: 17))
                  .padding(.vertical, 6)
                  .padding(.horizontal, 10)
                  .background(row.isCur ? Color.yellow.opacity(0.35) : Color.clear)
                  .clipShape(RoundedRectangle(cornerRadius: 10))
                  .id(row.id)
                  .onTapGesture {
                    if !row.isCur { tapLine(row.idx) }
                  }
              }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .gesture(
              DragGesture().onChanged { _ in
                if !userScr { userScr = true }
              }
            )
          }
          .onChange(of: sp.curSent) {
            guard !userScr else { return }
            withAnimation(.easeInOut(duration: 0.18)) {
              if let p = sp.pack {
                let id = p.sents[sp.curSent].id
                proxy.scrollTo(id, anchor: .center)
              }
            }
          }
        }

        if userScr {
          Button("Return to Reading") {
            userScr = false
          }
          .buttonStyle(.borderedProminent)
          .padding(.bottom, 6)
        }
      }
    }
  }

  private struct Row {
    var id: String
    var idx: Int
    var text: String
    var isCur: Bool
  }

  private func lines() -> [Row] {
    guard let p = sp.pack else { return [] }
    let i = sp.curSent
    let rng = (i-2...i+2)
    return rng.compactMap { j in
      guard j >= 0 && j < p.sents.count else { return nil }
      return Row(
        id: p.sents[j].id,
        idx: j,
        text: p.sents[j].text,
        isCur: j == i
      )
    }
  }

  private func tapLine(_ idx: Int) {
    guard set.skipAsk else {
      // no confirm
      skipTo(idx)
      return
    }
    // confirm modal handled in PlayerView (via binding); we just post intent
    NotifBus.shared.wantSkip = idx
  }

  private func skipTo(_ idx: Int) {
    // We implement "skip" as jump by sentences (stop + seek to target)
    let cur = sp.curSent
    let d = Double(idx - cur)
    // 1 sentence ~ (words/wps). We'll just jump by tokens directly:
    sp.jumpSec(d >= 0 ? 0.1 : -0.1) // tiny nudge to re-align token
    // then hard align token (direct method not exposed here in v1)
  }
}

// Simple shared bus for skip intent (keeps identifiers short)
final class NotifBus: ObservableObject {
  static let shared = NotifBus()
  @Published var wantSkip: Int? = nil
  private init() {}
}
