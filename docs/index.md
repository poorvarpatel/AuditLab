# Project Documentation Index – AuditLab

**Generated:** 2026-03-02 | **Mode:** initial_scan | **Scan level:** deep

---

## Project Overview

- **Type:** Monolith (single part)
- **Primary language:** Swift
- **Architecture:** SwiftUI app with ObservableObject stores (Library, Queue, Folders, Settings)
- **Part:** app (AuditLab) – mobile (iOS)

### Quick reference

- **Tech stack:** Swift, SwiftUI, PDFKit, AVFoundation, iOS 26.1+, Xcode
- **Entry point:** `AuditLab/AuditLabApp.swift`
- **Architecture pattern:** Tab-based SwiftUI; shared stores; local PDF + TTS playback

---

## Generated documentation

| Document | Description |
|----------|-------------|
| [Project Overview](./project-overview.md) | Name, purpose, tech summary, links |
| [Architecture](./architecture.md) | Executive summary, stack, data, components, dev/deploy |
| [Source Tree Analysis](./source-tree-analysis.md) | Annotated directory tree, entry points |
| [Technology Stack](./technology-stack.md) | Languages, frameworks, versions |
| [Architecture Patterns](./architecture-patterns.md) | State, navigation, async style |
| [Data Models](./data-models-app.md) | ReadPack, PaperRec, Queue, FoldRec, persistence |
| [API Contracts](./api-contracts-app.md) | Local-only; no remote API |
| [State Management](./state-management-app.md) | LibStore, QueueStore, FoldStore, AppSet, SpchPlayer |
| [UI Component Inventory](./ui-component-inventory-app.md) | Views, tabs, player, library |
| [Asset Inventory](./asset-inventory-app.md) | Assets.xcassets, AppIcon, AccentColor |
| [Development Guide](./development-guide.md) | Prerequisites, build, run, common tasks |
| [Deployment Configuration](./deployment-configuration.md) | iOS target, signing, CI/CD notes |
| [Project Structure](./project-structure.md) | Repository type, parts metadata |
| [Existing Documentation Inventory](./existing-documentation-inventory.md) | LICENSE, discovered docs |

**Metadata:** [project-parts.json](./project-parts.json)

---

## Existing documentation

- [LICENSE](../LICENSE) – MIT, Copyright (c) 2026 Poorva Patel

---

## Getting started

1. Open `AuditLab.xcodeproj` in Xcode.
2. Select the AuditLab scheme and an iOS 26.1+ simulator or device.
3. Build and run (Cmd+R).
4. Use **Library** to add PDFs and folders, **Queue** to manage playback order, **History** for past activity, **Settings** for playback options.

For brownfield PRD or AI context, use this index as the primary entry point.
