# Project Structure

**Generated:** 2026-03-02 (Deep Scan – Step 1)

## Repository type

**Monolith** – Single cohesive application (native Swift/SwiftUI, Xcode).

## Root directory

`/Users/hajoonkim/git/clone/michaelamici/AuditLab` (project root).

## Detected layout

- **AuditLab/** – Application source: Swift/SwiftUI views, stores, types, and app entry.
- **AuditLab.xcodeproj/** – Xcode project (iOS/macOS target).
- **docs/** – Project knowledge and generated documentation (this file).
- **_bmad/**, **_bmad-output/**, **.cursor/** – Tooling and config (excluded from app documentation).

No separate client/server or multiple app parts; one Xcode target, one codebase.

## Key indicators

| Indicator        | Present |
|-----------------|--------|
| Xcode project   | Yes (`AuditLab.xcodeproj`) |
| Swift sources   | Yes (`AuditLab/*.swift`) |
| Assets          | Yes (`AuditLab/Assets.xcassets`) |
| package.json    | No |
| Podfile / Cargo | No |

---

# Project Parts Metadata

## Part 1: app (AuditLab)

| Field            | Value |
|------------------|--------|
| **part_id**      | app |
| **display_name** | AuditLab |
| **project_type_id** | mobile |
| **root_path**    | `/Users/hajoonkim/git/clone/michaelamici/AuditLab` |
| **Rationale**    | Native Swift/SwiftUI app with UI, state stores, and assets; documented using **mobile** requirements (UI, state, assets, no backend API in repo). |

## Documentation requirements (from CSV – mobile)

- **requires_api_scan:** true (will scan for any API/client usage in app).
- **requires_data_models:** true (local models/stores).
- **requires_state_management:** true (LibStore, QueueStore, AppSet, FoldStore).
- **requires_ui_components:** true (SwiftUI views).
- **requires_deployment_config:** true (Xcode/signing/Fastlane if present).
- **requires_asset_inventory:** true (Assets.xcassets, images).

Critical directories for scan: `AuditLab/` (app), `Assets.xcassets/`; entry: `AuditLabApp.swift`.
