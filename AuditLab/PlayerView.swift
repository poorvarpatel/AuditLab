//
//  PlayerView.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/7/26.
//

import SwiftUI

struct PlayerView: View {
  @ObservedObject var sp: SpchPlayer
  @EnvironmentObject var set: AppSet
  @ObservedObject var bus = NotifBus.shared

  @State private var showAsk: Bool = false
  @State private var askIdx: Int = 0
    @State private var showCtrl: Bool = true

    private func ctrlDock() -> some View {
      VStack(spacing: 10) {
        HStack {
          Button {
            withAnimation(.easeInOut(duration: 0.18)) {
              showCtrl.toggle()
            }
          } label: {
            Image(systemName: showCtrl ? "chevron.down" : "chevron.up")
              .font(.system(size: 14, weight: .semibold))
          }
          .buttonStyle(.plain)

          Spacer()

          Text(showCtrl ? "Controls" : "Controls (collapsed)")
            .font(.subheadline)
            .foregroundStyle(.secondary)

          Spacer()

          // keep symmetry
          Color.clear.frame(width: 20, height: 20)
        }

        ctrlRow()

        if showCtrl {
          speedBox()
        }
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 12)
      .background(.thinMaterial)
      .clipShape(RoundedRectangle(cornerRadius: 22))
      .padding(.horizontal, 14)
      .padding(.bottom, 14)
    }


    var body: some View {
      VStack(spacing: 12) {
        header()

        FigurePanelView()
          .frame(height: 320)
          .padding(.horizontal, 14)

        TranscriptView(sp: sp)
          .environmentObject(set)
          .frame(maxHeight: .infinity)

        ctrlDock()
      }
      .padding(.top, 10)
      .onChange(of: bus.wantSkip) {
        guard let v = bus.wantSkip else { return }
        askIdx = v
        showAsk = true
        bus.wantSkip = nil
      }
      .alert("Skip to this sentence?", isPresented: $showAsk) {
        Button("Cancel", role: .cancel) { }
        Button("Skip", role: .destructive) {
          let cur = sp.curSent
          let d = Double(askIdx - cur)
          sp.jumpSec(d >= 0 ? 10 : -10)
        }
      } message: {
        Text("This will move playback to a new spot in the paper.")
      }
    }

    private func header() -> some View {
      VStack(alignment: .leading, spacing: 6) {
        Text(titleTxt())
          .font(.headline)
          .lineLimit(1)
          .truncationMode(.tail)

        Text(metaTxt())
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
      .padding(.horizontal, 14)
    }


  private func ctrlRow() -> some View {
    HStack(spacing: 18) {
      Button("⟲ 10s") { sp.jumpSec(-10) }
        .buttonStyle(.bordered)

      Button(sp.st == .play ? "Pause" : "Play") {
        sp.st == .play ? sp.pause() : sp.play()
      }
      .buttonStyle(.borderedProminent)

      Button("10s ⟳") { sp.jumpSec(10) }
        .buttonStyle(.bordered)
    }
    .padding(.top, 6)
  }

  private func speedBox() -> some View {
    VStack(spacing: 10) {
      HStack {
        Text("Speed")
        Spacer()
        Text(String(format: "%.2fx", sp.spd))
          .monospacedDigit()
      }

      Slider(
        value: Binding(
          get: { sp.spd },
          set: { v in
            // step 0.05
            let s = (v / 0.05).rounded() * 0.05
            sp.setSpd(s)
          }
        ),
        in: 0.25...3.5
      )

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 10) {
            ForEach([0.25,0.5,0.75,1.0,1.5,2.0,2.5,3.0], id: \.self) { v in
              Button(String(format: "%.2gx", v)) { sp.setSpd(v) }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 2)
      }
    }
    .padding(.horizontal, 14)
  }

  private func titleTxt() -> String {
    sp.pack?.meta.title ?? "AuditLab"
  }

  private func metaTxt() -> String {
    guard let m = sp.pack?.meta else { return "" }
    var out: [String] = []
    if m.auths.count > 0 && m.auths.count <= 2 { out.append(m.auths.joined(separator: ", ")) }
    if let d = m.date, !d.isEmpty { out.append(d) }
    return out.joined(separator: " • ")
  }
}
