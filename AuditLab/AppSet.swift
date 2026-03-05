//
//  AppSet.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/7/26.
//

import Foundation
import Combine

final class AppSet: ObservableObject {
  /// When true, tapping a sentence in the transcript shows a confirmation dialog before skipping.
  @Published var confirmBeforeSkip: Bool {
    didSet { UserDefaults.standard.set(confirmBeforeSkip, forKey: "skipAsk") }
  }

  @Published var figBg: Bool {
    didSet { UserDefaults.standard.set(figBg, forKey: "figBg") }
  }

  @Published var wps: Double {
    didSet { UserDefaults.standard.set(wps, forKey: "wps") }
  }

  init() {
    self.confirmBeforeSkip = UserDefaults.standard.object(forKey: "skipAsk") as? Bool ?? true
    self.figBg = UserDefaults.standard.object(forKey: "figBg") as? Bool ?? true
    self.wps = UserDefaults.standard.object(forKey: "wps") as? Double ?? 2.8
  }
}
