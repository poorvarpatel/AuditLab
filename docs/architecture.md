# Architecture – AuditLab

**Generated:** 2026-03-02 (Deep Scan – Step 8)

## Executive summary

AuditLab is a single-part iOS app (Swift/SwiftUI) for managing a library of papers, a playback queue, and folders. It parses PDFs into structured content (sections, sentences, figures) and plays them back via text-to-speech with a transcript and figure panel. No backend or remote API.

## Technology stack

- **Language:** Swift.
- **UI:** SwiftUI; **Concurrency:** Combine, @MainActor.
- **PDF:** PDFKit; **Speech:** AVFoundation (AVSpeechSynthesizer).
- **Persistence:** UserDefaults (settings); library/queue/folders in-memory (persistence planned).

See [technology-stack.md](./technology-stack.md).

## Architecture pattern

- SwiftUI app with four shared ObservableObject stores (LibStore, QueueStore, FoldStore, AppSet) and a playback engine (SpchPlayer). Tab-based navigation; sheets for player and folder/paper detail. See [architecture-patterns.md](./architecture-patterns.md).

## Data architecture

- **Parsed content:** ReadPack (Meta, Sec, Sent, Fig) from PDFParser.
- **Library:** PaperRec; **Queue:** QItem / QueueItem; **Folders:** FoldRec.
- See [data-models-app.md](./data-models-app.md).

## API design

- No HTTP/REST/GraphQL; local-only. See [api-contracts-app.md](./api-contracts-app.md).

## Component overview

- **Tabs:** Library, Queue, History, Settings.
- **Library:** Header, folder grid, paper grid, file picker, player sheet.
- **Player:** Title, meta, figure panel, transcript, playback controls.
- See [ui-component-inventory-app.md](./ui-component-inventory-app.md).

## Source tree

- Single app target under `AuditLab/`; entry `AuditLabApp.swift`, root UI `RootView`. See [source-tree-analysis.md](./source-tree-analysis.md).

## Development workflow

- Xcode; open AuditLab.xcodeproj, build and run on simulator or device. See [development-guide.md](./development-guide.md).

## Deployment architecture

- iOS app; signing via Xcode; no backend. See [deployment-configuration.md](./deployment-configuration.md).

## Testing strategy

- No test targets in scanned project; add Unit/UI tests in Xcode as needed.
