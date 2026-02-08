//
//  AppSet.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/7/26.
//

import Foundation
import Combine

final class AppSet: ObservableObject {
  @Published var skipAsk: Bool {
    didSet { UserDefaults.standard.set(skipAsk, forKey: "skipAsk") }
  }

  @Published var figBg: Bool {
    didSet { UserDefaults.standard.set(figBg, forKey: "figBg") }
  }

  @Published var wps: Double {
    didSet { UserDefaults.standard.set(wps, forKey: "wps") }
  }

  init() {
    self.skipAsk = UserDefaults.standard.object(forKey: "skipAsk") as? Bool ?? true
    self.figBg = UserDefaults.standard.object(forKey: "figBg") as? Bool ?? true
    self.wps = UserDefaults.standard.object(forKey: "wps") as? Double ?? 2.8
  }
}
