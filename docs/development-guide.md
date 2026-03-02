# Development Guide – AuditLab

**Generated:** 2026-03-02 (Deep Scan – Step 6)

## Prerequisites

- **Xcode** (26.x per project; LastSwiftUpdateCheck = 2610).
- **macOS** for building iOS app (SDKROOT = iphoneos).
- **iOS deployment target:** 26.1.

## Installation

1. Clone the repository.
2. Open `AuditLab.xcodeproj` in Xcode.
3. Select the AuditLab scheme and a simulator or device (iOS 26.1+).
4. No external package manager (no CocoaPods, SPM dependencies in project).

## Environment

- No `.env` or config files in repo; settings (skipAsk, figBg, wps) stored in UserDefaults.
- **Development team:** Set in project (DEVELOPMENT_TEAM = 3L3LK8HZ46); replace with your team for signing.

## Build

- **Build:** Cmd+B or Product → Build.
- **Run:** Cmd+R or Product → Run.
- **Clean:** Product → Clean Build Folder.

## Testing

- No test target or test file patterns found in app (`*.test.ts` etc. are for other project types).
- Add tests via Xcode: File → New → Target → Unit Testing Bundle / UI Testing Bundle.

## Common tasks

- **Add a new view:** Add SwiftUI view in `AuditLab/`, register in tab or parent view.
- **Change settings keys:** Edit `AppSet.swift` (UserDefaults keys: skipAsk, figBg, wps).
- **Adjust playback:** `SpchPlayer` (speed, tokens); `AppSet.wps` for words-per-second default.
