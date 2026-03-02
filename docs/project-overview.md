# Project Overview – AuditLab

**Generated:** 2026-03-02 (Deep Scan – Step 9)

## Project name and purpose

- **Name:** AuditLab.
- **Purpose:** iOS app for managing a paper library, building a playback queue (papers and folders), and listening to papers via text-to-speech with transcript and figure display. PDFs are parsed into sections/sentences/figures and played back with configurable speed and skip behavior.

## Executive summary

- Single iOS app (Swift/SwiftUI), one Xcode target. No backend; local PDF parsing and AVSpeechSynthesizer. State: library, queue, folders, and settings (UserDefaults). Classified as **mobile** for documentation requirements.

## Tech stack summary

| Category | Technology |
|----------|------------|
| Language | Swift |
| UI | SwiftUI |
| PDF | PDFKit |
| Speech | AVFoundation |
| Platform | iOS 26.1+ |
| Build | Xcode |

## Architecture type

- **Repository:** Monolith (single part).
- **Architecture:** SwiftUI + ObservableObject stores; tab-based navigation.

## Repository structure

- **app:** `AuditLab/` (sources + Assets.xcassets); `AuditLab.xcodeproj`.
- **docs:** `docs/` (project knowledge and generated docs).
- **Tooling:** `_bmad/`, `_bmad-output/` (excluded from app docs).

## Links to detailed docs

- [Architecture](./architecture.md)
- [Source Tree Analysis](./source-tree-analysis.md)
- [Technology Stack](./technology-stack.md)
- [Data Models](./data-models-app.md)
- [API Contracts](./api-contracts-app.md)
- [State Management](./state-management-app.md)
- [UI Component Inventory](./ui-component-inventory-app.md)
- [Development Guide](./development-guide.md)
- [Deployment Configuration](./deployment-configuration.md)
- [Project Structure](./project-structure.md)
