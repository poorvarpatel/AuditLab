//
//  SetView.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/7/26.
//

internal import SwiftUI

struct SetView: View {
  @EnvironmentObject var set: AppSet

  var body: some View {
    NavigationStack {
      Form {
        Section("Playback") {
          Toggle("Confirm skip", isOn: $set.skipAsk)
          HStack {
            Text("Words/sec est")
            Spacer()
            Text(String(format: "%.2f", set.wps)).monospacedDigit()
          }
          Slider(value: $set.wps, in: 1.5...4.0)
        }

        Section("Figures") {
          Toggle("Figure notifs when off-app", isOn: $set.figBg)
        }
      }
      .navigationTitle("Settings")
    }
  }
}
