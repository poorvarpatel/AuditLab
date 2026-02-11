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
    ScrollViewReader { proxy in
      VStack(spacing: 10) {

        // Optional heading, but DO NOT replace the scrollable transcript
        if let h = sp.headTxt {
          Text(h)
            .font(.title3.weight(.semibold))
            .multilineTextAlignment(.center)
            .padding(.vertical, 18)
        }

        ScrollView {
          LazyVStack(alignment: .leading, spacing: 12) {
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
        }
        .frame(maxHeight: .infinity) // <-- makes it reliably scrollable inside the parent VStack
        .simultaneousGesture(
          DragGesture(minimumDistance: 2).onChanged { _ in
            if !userScr { userScr = true }
          }
        )
        .onChange(of: sp.curSent) { _, _ in
          guard !userScr else { return }
          scrollToCurrent(proxy)
        }
        .onChange(of: sp.pack?.id) { _, _ in
          // when a new paper loads, snap to current
          guard !userScr else { return }
          DispatchQueue.main.async { scrollToCurrent(proxy) }
        }

        if userScr {
          Button("Return to Reading") {
            userScr = false
            scrollToCurrent(proxy)   // <-- immediate snap back
          }
          .buttonStyle(.borderedProminent)
          .padding(.bottom, 6)
        }
      }
    }
  }

  private func scrollToCurrent(_ proxy: ScrollViewProxy) {
    guard let p = sp.pack, p.sents.indices.contains(sp.curSent) else { return }
    let id = p.sents[sp.curSent].id
    withAnimation(.easeInOut(duration: 0.18)) {
      proxy.scrollTo(id, anchor: .center)
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
        return p.sents.enumerated().map { j, sent in
            Row(
                id: sent.id,
                idx: j,
                text: sent.text,
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
