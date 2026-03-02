# Technology Stack

**Generated:** 2026-03-02 (Deep Scan – Step 3)

## Part: app (AuditLab)

| Category | Technology | Version / Justification |
|----------|------------|-------------------------|
| Language | Swift | From Xcode project; SwiftUI, modern concurrency |
| UI Framework | SwiftUI | Declarative UI; `internal import SwiftUI` |
| Concurrency | Combine, @MainActor | ObservableObject, @Published; MainActor for UI |
| PDF | PDFKit (UIKit) | PDF parsing in `PDFParser.swift` |
| Speech | AVFoundation (AVSpeechSynthesizer) | Text-to-speech in `SpchPlayer.swift` |
| Platform | iOS | SDKROOT = iphoneos; IPHONEOS_DEPLOYMENT_TARGET = 26.1 |
| Build | Xcode | project.pbxproj; FileSystemSynchronizedRootGroup (Xcode 26) |
| Persistence | UserDefaults | App settings (skipAsk, figBg, wps); in-memory for library/queue (later: persist) |

## Architecture pattern (app)

- **Pattern:** SwiftUI single-window app with shared observable stores.
- **Entry:** `AuditLabApp.swift` → `RootView` (TabView: Library, Queue, History, Settings).
- **Data flow:** EnvironmentObject injection (LibStore, QueueStore, AppSet, FoldStore); no backend API.
