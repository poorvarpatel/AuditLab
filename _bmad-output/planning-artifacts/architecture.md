---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
lastStep: 8
status: 'complete'
completedAt: '2026-03-02'
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/planning-artifacts/ux-design-specification.md
  - docs/index.md
  - docs/project-overview.md
  - docs/architecture.md
  - docs/technology-stack.md
  - docs/architecture-patterns.md
  - docs/data-models-app.md
  - docs/state-management-app.md
  - docs/source-tree-analysis.md
  - docs/project-structure.md
  - docs/development-guide.md
  - docs/deployment-configuration.md
  - docs/ui-component-inventory-app.md
  - docs/asset-inventory-app.md
  - docs/api-contracts-app.md
  - docs/existing-documentation-inventory.md
workflowType: 'architecture'
project_name: 'AuditLab'
user_name: 'Hajoonkim'
date: '2026-03-02'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional Requirements:**
- **Library & document management (7):** Add/remove/view PDFs, persist library, document detail, parse-failure feedback, cascade delete from folders/queue.
- **Folders & organization (9):** Create/rename/delete folders; add/remove document–folder links; many-to-many (one doc in many folders); persist; enforce uniqueness and referential integrity.
- **Queue management (6):** Add doc or folder (snapshot), remove, reorder, view queue, persist across restarts.
- **Playback & speech (9):** Start/pause/resume; voice selection (persisted); rate/pitch; transcript and figure context; store/restore position; restore state after app termination.
- **History (5):** View, search by document, filter by date/folder; show timestamp, position, duration; resume from entry.
- **Settings & preferences (5):** Persist voice, rate, pitch; appearance (system/light/dark); clear history (with confirmation); app version.
- **Accessibility (6):** Labels on all interactive elements; focus order; state-change announcements; Dynamic Type; tap targets; VoiceOver-only navigability.
- **Error handling & resilience (4):** Graceful PDF parse failure (no crash); preserve existing data; handle large PDFs without blocking; async parsing.

**Non-Functional Requirements:**
- **Performance:** Off-main-thread PDF parsing; bounded memory for large PDFs; responsive History with 10k+ entries; loading/feedback within defined time.
- **Reliability:** Persistence across restart; recovery from abnormal termination; schema migration without data loss; no crashes under normal use.
- **Accessibility:** WCAG 2.1 AA–aligned; VoiceOver, Dynamic Type, tap targets, system accessibility settings.
- **Security & privacy:** All data on-device; no transmission; no analytics; sandbox-only storage.
- **Usability:** Intentional empty/loading states; native SwiftUI and HIG; no unexplained blank screens.

**Scale & Complexity:**
- **Primary domain:** Mobile (iOS), single target, offline-first, no backend.
- **Complexity level:** Low.
- **Architectural components (estimated):** Persistence (Core Data + migration), PDF service (parsing), Speech service (TTS + playback state), ViewModels/state (library, queue, folders, settings, history), Views (tabs + player + settings), and optional resume/History query layer.

### Technical Constraints & Dependencies

- **Platform:** iOS 26.1+; Swift/SwiftUI; PDFKit, AVFoundation, Core Data; Combine/async-await as needed.
- **Persistence:** Core Data as single source of truth for documents, folders, queue, history, and app state; UserDefaults only where appropriate (e.g. trivial UI prefs). Many-to-many Document–Folder in Core Data; migration from current in-memory/UserDefaults state.
- **No backend, no push, no cloud:** All features work offline; no user accounts or sync.
- **Architecture:** Clear separation of Views, ViewModels (or equivalent), Persistence, Speech service, PDF service; no business logic in views.

### Cross-Cutting Concerns Identified

- **Persistence & migration:** Core Data model design, many-to-many, and migration strategy affect library, folders, queue, history, and settings.
- **Accessibility:** Labels, focus order, announcements, and layout affect every screen and component.
- **Offline-first / local-only:** No network layer; all contracts are in-process (e.g. PDFParser, SpchPlayer, stores).
- **Error handling & resilience:** Bad PDF handling and large-file behavior affect PDF service and UI feedback paths.
- **State consistency:** Library, queue, folders, playback position, and settings must stay consistent across restarts and after errors.

## Starter Template Evaluation

### Primary Technology Domain

**Native iOS (Swift/SwiftUI)** — single-target mobile app, offline-first, no backend. Not a cross-platform framework (React Native, Expo, Flutter); the stack is Swift, SwiftUI, Xcode, and system frameworks (PDFKit, AVFoundation, Core Data).

### Starter Options Considered

- **Apple Xcode “SwiftUI App” template:** The standard for new iOS projects (File → New → Project → iOS App, Interface: SwiftUI). Provides `@main` App, WindowGroup, and SwiftUI lifecycle. No CLI; project creation is via Xcode only.
- **Brownfield existing project (AuditLab):** The codebase already uses this foundation—SwiftUI, ObservableObject stores, PDFKit, AVFoundation, UserDefaults. No “create” command applies; the foundation is the current Xcode project plus the architectural decisions we are making (Core Data, persistence layer, service boundaries).

For native iOS there are no community CLI starters analogous to create-next-app or create-expo-app; the canonical foundation is the Xcode/SwiftUI project. UX requirements (HIG, system components, offline-only, VoiceOver) align with this stack.

### Selected Starter: Existing project + defined architecture (Core Data + layers)

**Rationale for Selection:**

The project is brownfield; we are not generating a new app from a template. The “starter” is the **established foundation**: native Swift/SwiftUI in Xcode, iOS 26.1+, with PDFKit and AVFoundation. The PRD and project context require moving to **Core Data** and a **clear layer split** (Views, ViewModels or equivalent, Persistence, PDF service, Speech service). So the effective “starter” is: retain the current Xcode/SwiftUI base and adopt Core Data plus the layered architecture we define in the next step. No separate initialization command; the first implementation story is introducing the Core Data model and migration (or the first concrete architectural step agreed in step 4).

**Initialization Command:**

Not applicable — brownfield. First implementation story will be: add Core Data model and migration (or equivalent first architectural step from step 4).

**Architectural Decisions Provided by Starter:**

**Language & Runtime:** Swift 6 (or current project Swift version); SwiftUI; iOS 26.1+ deployment target. Concurrency: async/await and/or Combine as already used.

**Styling Solution:** SwiftUI system components and semantic colors only; no custom design system. HIG and system appearance (light/dark); no theme/accent controls (per UX spec).

**Build Tooling:** Xcode; native iOS build (iphoneos). No external package manager required for MVP.

**Testing Framework:** No test target in scanned project; add Unit Testing Bundle / UI Testing Bundle in Xcode as needed (per PRD quality goals).

**Code Organization:** To be defined in step 4 (Views, ViewModels or equivalent, Persistence, PDF service, Speech service; no business logic in views).

**Development Experience:** Xcode; Cmd+B / Cmd+R; simulator or device. No hot-reload beyond SwiftUI previews.

**Note:** Project initialization using a CLI starter is N/A. The first implementation story should be the first architectural step (e.g. Core Data model and migration) as decided in the next step.

## Core Architectural Decisions

### Decision Priority Analysis

**Critical Decisions (Block Implementation):**
- Core Data as single persistence store; entities Document, Folder, HistoryItem; many-to-many Document–Folder.
- Layered architecture: Views, ViewModels (or equivalent), Persistence layer, PDF service, Speech service; no business logic in views.
- Migration path from current in-memory/UserDefaults to Core Data.

**Important Decisions (Shape Architecture):**
- Parsed content (ReadPack): in-memory/cache keyed by document for MVP; optional TranscriptChunk in Core Data later if needed for resume/search.
- State management: ObservableObject or Observation; ViewModels call Persistence and services.
- Tab-based root (Library, Queue, History, Settings); NavigationStack for drill-down.

**Deferred Decisions (Post-MVP):**
- TranscriptChunk in Core Data (defer until resume/search needs justify).
- CI/CD pipeline (optional; Xcode Archive sufficient for MVP).

### Data Architecture

- **Persistence store:** Core Data. Single stack; main context for UI, background context for import/parsing where appropriate.
- **Entities:** Document, Folder, HistoryItem. Many-to-many between Document and Folder (relationship or join entity per model design). Optional: TranscriptChunk post-MVP.
- **Migration:** Lightweight migration from current state (no existing Core Data store); seed or migrate from in-memory/UserDefaults in a one-time migration step.
- **Parsed content:** ReadPack (sections, sentences, figures) remains in-memory/cache keyed by document ID; not stored in Core Data for MVP to avoid schema churn. Persist playback position (e.g. sentence or offset) in HistoryItem or related entity.
- **Caching:** In-memory cache for parsed ReadPack; eviction policy as needed for large libraries (e.g. LRU or limit by count).

### Authentication & Security

- **Authentication:** None. No user accounts; fully offline.
- **Authorization:** N/A.
- **Data:** All data on-device; app sandbox only. No network transmission; no analytics or third-party data sharing. Document in architecture: “on-device only, sandbox.”

### API & Communication Patterns

- **Remote API:** None. No HTTP/REST/GraphQL.
- **Local contracts:** Persistence behind a clear interface (repository or service type) used by ViewModels. PDF parsing (PDFParser) and Speech (SpchPlayer) used as services; ViewModels or stores coordinate them. Error handling: async throws or Result; user-facing errors surfaced via state (e.g. alert or banner).

### Frontend Architecture

- **State management:** ObservableObject (or SwiftUI Observation) for ViewModels/stores. ViewModels hold UI state and call Persistence layer and PDF/Speech services; views bind to ViewModel state only.
- **Structure:** Tab-based root (Library, Queue, History, Settings); NavigationStack for drill-down; sheets for player and modals as needed. No business logic in views; no oversized view files.
- **Data flow:** One-way: Persistence → ViewModel → View. User actions → ViewModel → Persistence or service → state update → view refresh.

### Infrastructure & Deployment

- **Hosting:** N/A (client-only app).
- **Build & distribution:** Single iOS target; Xcode build and signing; Archive → Distribute App for App Store / Ad Hoc. No backend to deploy.
- **CI/CD:** Optional; not required for MVP. Add later if desired (e.g. xcodebuild + archive).
- **Environments:** Debug/Release only; no backend envs.

### Decision Impact Analysis

**Implementation Sequence:**
1. Add Core Data model (Document, Folder, HistoryItem; many-to-many Document–Folder).
2. Implement persistence layer (repository/service) and migration from current state.
3. Refactor stores/ViewModels to use persistence layer instead of in-memory/UserDefaults for library, queue, folders.
4. Persist playback position and history; add History search/filter.
5. Add unit tests for parsing and persistence; accessibility and error-handling polish.

**Cross-Component Dependencies:**
- Persistence layer must be in place before ViewModels can be refactored off in-memory state.
- PDF service (parsing) and Speech service (playback) remain largely as-is; they consume/produce data that persistence and ViewModels coordinate.
- Many-to-many and referential integrity in Core Data affect folder and library UI behavior; delete rules must be defined (e.g. cascade or nullify).

## Implementation Patterns & Consistency Rules

### Pattern Categories Defined

**Critical Conflict Points Identified:** Naming (Core Data, Swift types, files), structure (where views/stores/persistence live), state and error handling (how agents expose loading/errors), and process (parsing off main thread, user-facing messages). Without these rules, agents could mix naming styles, scatter types, or handle errors inconsistently.

### Naming Patterns

**Core Data / Persistence Naming:**
- **Entity names:** PascalCase, singular (e.g. `Document`, `Folder`, `HistoryItem`). Matches Swift type names and Core Data convention.
- **Attribute names:** camelCase (e.g. `addedAt`, `lastPlayedPosition`, `documentId`). No snake_case in the model.
- **Relationship names:** camelCase, describe the relationship (e.g. `documents`, `folders`, `folderItems` for many-to-many). Inverse relationships named consistently (e.g. `document` / `folder` for the “many” side of a join).
- **Model file:** Single `.xcdatamodeld` (or one per version); entity names in the model must match types used in code (e.g. NSManagedObject subclasses or fetch request entity names).

**Code Naming (Swift):**
- **Types (classes, structs, enums):** PascalCase (e.g. `Document`, `ReadPack`, `SpchPlayer`).
- **Files:** One primary type per file; file name = type name: `TypeName.swift` (e.g. `LibStore.swift`, `FolderDetailView.swift`).
- **Properties and variables:** camelCase (e.g. `lastPlayedPosition`, `isLoading`).
- **Functions/methods:** camelCase, verb or verb phrase (e.g. `addDocument`, `fetchFolders`, `parse(url:)`). Boolean getters: `is...`, `has...`, `can...`.
- **Constants:** camelCase for instance/static; `lowercase` or `kConstantName` only if the project already uses it (prefer camelCase).

**No API naming:** No REST/GraphQL; local-only. Any future local “API” surface (e.g. persistence service methods) use Swift method names as above.

### Structure Patterns

**Project Organization:**
- **App target:** All app source under `AuditLab/` (or existing app group). No separate “packages” required for MVP.
- **Grouping:** By layer or by feature. Recommended: **by layer** — e.g. `Views/`, `Stores/` (or `ViewModels/`), `Persistence/`, `Services/` (PDF, Speech), `Models/` (parsed DTOs like ReadPack). Alternatively by feature (Library, Queue, History, Settings) with each feature containing its views and view-specific state; shared persistence and services stay in a common layer. Pick one and document it so agents don’t mix (e.g. “We use layer-based grouping under AuditLab/”).
- **Tests:** Dedicated test target; tests in `*Tests/` group. Naming: `TypeNameTests.swift` for unit tests, `TypeNameUITests.swift` for UI tests. Co-located test files not required; keep tests in the test target.
- **Persistence:** Core Data model (`.xcdatamodeld`) in app target; persistence layer types (repository/service) in `Persistence/` (or equivalent). No persistence logic in views or in stores beyond calling the persistence interface.
- **Assets:** `Assets.xcassets` for images, colors, app icon. User documents and parsed assets follow sandbox paths; no ad-hoc resource folders that bypass the asset catalog for app-provided art.

**File Structure:**
- **Config:** No .env; use Xcode build settings and/or a single config type if needed. UserDefaults keys: camelCase or a small set of constants (e.g. `UserDefaults.Keys.voiceId`).
- **Documentation:** Architecture and high-level docs in `docs/`; code comments for non-obvious behavior. README at repo root for build/run.

### Format Patterns

**No remote API:** N/A for REST/JSON. Any local serialization (e.g. for export or debugging): prefer Swift `Codable`; JSON keys camelCase to match Swift property names unless an external spec requires otherwise.

**Dates:** Store in Core Data as `Date`; use ISO8601 or system formatters when displaying or persisting to strings. Use `Date` in Swift; avoid raw timestamps in the model unless required.

**Errors:** Use Swift `Error` and `throws` or `Result<T, Error>`. User-facing messages: present via ViewModel state (e.g. `alertMessage: String?`, `errorMessage: String?`) and show in an Alert or banner; do not expose raw errors in the UI. Logging: `os.log` or `print` for debug; no required log format, but keep user-facing and developer-facing messages separate.

### Communication Patterns

**No event bus:** No cross-app event system. Use ViewModel state and SwiftUI bindings; coordination via shared stores or dependency injection (e.g. environment objects).

**State updates:** Main thread for UI-bound state. Use `@Published` (ObservableObject) or Observation; update state in response to persistence or service calls. Prefer async/await and `@MainActor` for UI-related work; run parsing and heavy work off the main actor and hop back to main for state updates.

**Action/method naming:** Intent-revealing names: `addDocument`, `removeFromFolder`, `startPlayback`, `clearHistory`. No generic “handleTap” without a more specific public method that does the work.

### Process Patterns

**Error handling:** Parsing and persistence can `throw`; ViewModels catch and set a user-facing message (and optionally log). No silent swallows; every user-facing failure path has a clear message (per PRD). Malformed PDF: show a single, dismissible alert; do not crash.

**Loading states:** One loading indicator per logical operation (e.g. “adding document”, “loading folder”). Prefer a single `isLoading` (or `loadingTask`) per screen/flow so agents don’t add overlapping spinners. Show loading within ~500 ms for long operations (per NFR).

**Validation:** Validate at the boundary (e.g. persistence layer or service) before writing. Validate user input before triggering actions (e.g. folder name non-empty). Surface validation errors the same way as other user-facing errors.

### Enforcement Guidelines

**All AI agents MUST:**
- Use the naming conventions above for new Core Data entities/attributes and Swift types/files so the codebase stays consistent.
- Place new types in the agreed structure (by-layer or by-feature); do not add new top-level folders that bypass the chosen organization.
- Use the same error-handling approach: throws/Result at the boundary, user-facing message in ViewModel state, Alert/banner in the view.
- Keep business logic out of views; coordinate in ViewModels/stores and call persistence/services from there.

**Pattern enforcement:** Code review and (when added) unit tests for persistence and parsing. No automated pattern checker required for MVP; document any new pattern in this section when the team agrees.

### Pattern Examples

**Good examples:**
- Entity: `HistoryItem` with attributes `playedAt`, `lastSentenceId`, `durationSeconds`; relationship `document`.
- File: `FolderDetailView.swift` contains `struct FolderDetailView: View`.
- Method: `func add(document: Document, to folder: Folder)` in the persistence layer; ViewModel calls it and updates `@Published` state.
- Error: ViewModel sets `alertMessage = "Couldn't read this PDF. It may be corrupted or unsupported."` and view shows `Alert` with that message.

**Anti-patterns:**
- Core Data entity named `document_folder_link` (use PascalCase and a clear relationship or join entity name).
- Business logic in `LibraryView` that fetches from Core Data or parses PDFs directly (move to ViewModel and persistence/service).
- Silent catch that ignores parsing failure (always set a user-facing message or log and surface).
- Multiple unrelated loading flags on the same screen with no single place that drives the spinner.

## Project Structure & Boundaries

### Complete Project Directory Structure

Layer-based organization under the app target. Current codebase is flat under `AuditLab/`; target structure below is the intended layout for refactor and new code.

```
AuditLab/                                    # Repo root
├── README.md                                # Build, run, high-level overview
├── LICENSE
├── .gitignore
├── AuditLab.xcodeproj/                      # Xcode project (iOS 26.1+)
├── AuditLab/                                # App target (sources + assets)
│   ├── AuditLabApp.swift                    # Entry: @main, WindowGroup, RootView
│   ├── RootView.swift                       # TabView: Library | Queue | History | Settings
│   │
│   ├── Models/                              # DTOs, domain value types (non–Core Data)
│   │   ├── Types.swift                     # ReadPack, Meta, Sec, Sent, Fig, PaperRec, FoldRec, Queue types
│   │   └── (optional) QueueItemTypes.swift # If queue types split out
│   │
│   ├── Views/                               # SwiftUI views only; no business logic
│   │   ├── Library/
│   │   │   ├── LibraryView.swift
│   │   │   ├── LibraryHeaderView.swift
│   │   │   ├── LibraryCardView.swift
│   │   │   ├── FolderGridView.swift
│   │   │   ├── FolderDetailView.swift
│   │   │   ├── FolderQueueConfigView.swift
│   │   │   └── DocumentPicker.swift
│   │   ├── Queue/
│   │   │   └── QueueView.swift
│   │   ├── Player/
│   │   │   ├── PlayerView.swift
│   │   │   ├── TranscriptView.swift
│   │   │   └── FigurePanelView.swift
│   │   ├── History/
│   │   │   └── HistView.swift
│   │   ├── Settings/
│   │   │   └── SetView.swift
│   │   ├── Shared/
│   │   │   └── PaperDetailView.swift       # If shared; else under Library or Player
│   │   └── (optional) ScratchView.swift    # Place as appropriate
│   │
│   ├── Stores/                              # ViewModels / ObservableObject state (UI-facing)
│   │   ├── LibStore.swift
│   │   ├── QueueStore.swift
│   │   ├── FoldStore.swift
│   │   └── AppSet.swift                    # Settings state; may keep UserDefaults for trivial prefs
│   │
│   ├── Persistence/                         # Core Data and persistence abstraction
│   │   ├── AuditLab.xcdatamodeld           # Core Data model (Document, Folder, HistoryItem)
│   │   ├── PersistenceController.swift     # Or equivalent: stack, main/background contexts
│   │   ├── DocumentRepository.swift        # Or single Repository type for documents/folders/history
│   │   └── (optional) Migration steps      # One-time migration from in-memory/UserDefaults
│   │
│   ├── Services/                            # PDF parsing, speech, caching
│   │   ├── PDFParser.swift                 # PDF → ReadPack (off main thread)
│   │   ├── SpchPlayer.swift                # AVSpeechSynthesizer playback
│   │   └── (optional) ReadPackCache.swift  # In-memory cache for parsed packs
│   │
│   ├── Resources/                           # Optional: non–asset-catalog resources
│   │   └── (none required for MVP)
│   │
│   ├── Assets.xcassets/                     # App icon, AccentColor, images
│   │   ├── AppIcon.appiconset
│   │   └── AccentColor.colorset
│   │
│   └── DemoData.swift                       # Dev/demo only; exclude from production if desired
│
├── AuditLabTests/                           # Unit test target
│   ├── Persistence/
│   │   └── DocumentRepositoryTests.swift   # Or equivalent persistence tests
│   ├── Services/
│   │   └── PDFParserTests.swift
│   └── (optional) Helpers/
│
├── AuditLabUITests/                         # UI test target (optional for MVP)
│   └── (e.g. CriticalPathTests.swift)
│
├── docs/                                    # Project knowledge, architecture, dev guide
│   ├── index.md
│   ├── project-overview.md
│   ├── architecture.md
│   └── ...
├── _bmad/                                   # Tooling (excluded from app)
└── _bmad-output/                            # Planning/outputs (excluded from app)
```

**Note:** Existing flat layout under `AuditLab/*.swift` can remain until refactor; new files should follow the layer folders above. Move files into `Models/`, `Views/`, `Stores/`, `Persistence/`, `Services/` as part of the persistence and refactor work.

### Architectural Boundaries

**API boundaries:** None. No remote API. Local “contract” boundaries: persistence interface (repository/service) used only by Stores; PDF and Speech services used by Stores or by Persistence when needed (e.g. post-import).

**Component boundaries:**
- **Views:** Only bind to Stores (or injected ViewModels); no direct Core Data, no direct PDFParser/SpchPlayer. User actions call Store methods.
- **Stores:** Own UI state; call Persistence (CRUD, fetch) and Services (parse, play). Run on main actor for UI-bound state; dispatch parsing/heavy work off main.
- **Persistence:** Owns Core Data stack and repository type(s); exposes methods like `addDocument`, `fetchFolders`, `addToFolder`, `saveHistoryEntry`. No UI types; no dependency on Views or Stores except via callbacks/completion if needed.
- **Services (PDF, Speech):** Stateless or single-instance; called by Stores. PDFParser: `parse(url:) async throws -> ReadPack`. SpchPlayer: playback control and state; consumed by PlayerView via Store.

**Data boundaries:**
- **Core Data:** Single stack; main context for UI reads/writes; background context for bulk or import if needed. Entity boundary: Document, Folder, HistoryItem (and optional join for many-to-many).
- **In-memory:** ReadPack cache keyed by document ID; owned by a service or Store, not by Views. Queue and folder “snapshots” in memory are derived from Core Data or from Store state that mirrors persistence.
- **UserDefaults:** Trivial UI prefs only (e.g. if not moved to Core Data); keys centralized (e.g. constants or small config type).

### Requirements to Structure Mapping

| FR category | Primary location | Notes |
|-------------|------------------|--------|
| Library & document management | `Stores/LibStore`, `Persistence/`, `Services/PDFParser`, `Views/Library/*` | Add/remove/view in LibStore + Persistence; parsing in PDFParser; UI in Library views. |
| Folders & organization | `Stores/FoldStore`, `Persistence/`, `Views/Library/Folder*` | Many-to-many in Core Data; FoldStore calls persistence; folder UI in Views/Library. |
| Queue management | `Stores/QueueStore`, `Persistence/`, `Views/Queue/` | Queue persisted via Persistence; QueueStore owns order and snapshot; QueueView binds to QueueStore. |
| Playback & speech | `Stores/` (e.g. QueueStore or dedicated), `Services/SpchPlayer`, `Views/Player/*` | SpchPlayer in Services; playback state in Store; PlayerView and transcript/figure in Views/Player. |
| History | `Stores/` (e.g. HistStore or shared), `Persistence/`, `Views/History/` | HistoryItem in Core Data; fetch/search in Persistence; HistView binds to Store. |
| Settings & preferences | `Stores/AppSet`, `Views/Settings/SetView` | AppSet in Stores; UserDefaults or Core Data for prefs; SetView in Views/Settings. |
| Accessibility | All `Views/*` | Labels, order, Dynamic Type in each view; no separate module. |
| Error handling & resilience | `Services/PDFParser` (throws), `Stores/*` (catch → alert state), `Views/*` (Alert/banner) | Parsing errors in PDFParser; Stores set user-facing message; Views show Alert. |

**Cross-cutting:** Persistence used by LibStore, FoldStore, QueueStore, and any History store. PDFParser and SpchPlayer used from Stores. No shared “event bus”; coordination via Store methods and SwiftUI state.

### Integration Points

**Internal communication:**
- **App entry → UI:** `AuditLabApp` creates RootView and injects environment objects (LibStore, QueueStore, FoldStore, AppSet). Persistence controller and services can be created at app init or lazy and passed into Stores.
- **View ↔ Store:** Views read `@EnvironmentObject` or injected Store; call `store.addDocument(...)`, etc. State updates via `@Published` (or Observation) drive view updates.
- **Store ↔ Persistence:** Stores call repository methods (e.g. `persistence.add(document:)`, `persistence.folders()`). Results and errors mapped to Store state.
- **Store ↔ Services:** Stores call `PDFParser.parse(url:)` and SpchPlayer methods; run parsing off main actor, then update Store on main.

**External integrations:** None. Document picker and file access are system APIs; no third-party SDKs for MVP.

**Data flow:** User action → View → Store method → Persistence or Service → (async) result → Store state update → View refresh. One-way; no direct View → Persistence or View → Service.

### File Organization Patterns

**Configuration:** No .env. Xcode project settings (e.g. deployment target, signing). UserDefaults keys in one place (e.g. AppSet or a small `UserDefaults+Keys` extension).

**Source:** Layer-based under `AuditLab/`: Models, Views (grouped by feature: Library, Queue, Player, History, Settings), Stores, Persistence, Services, Assets.xcassets. One primary type per file; file name = type name.

**Tests:** In `AuditLabTests/` (and optional `AuditLabUITests/`). Mirror app layers: `Persistence/*Tests`, `Services/*Tests`. Naming: `TypeNameTests.swift`.

**Assets:** All app-provided images and colors in `Assets.xcassets`. User PDFs and extracted assets in app sandbox; paths managed by Persistence or Services, not hard-coded in Views.

### Development Workflow Integration

**Development:** Open `AuditLab.xcodeproj`; build and run (Cmd+R) on simulator or device. No separate dev server. SwiftUI previews for views where helpful.

**Build:** Xcode builds the app target and (when added) test targets. No external package manager for MVP. Core Data model is part of the app target.

**Deployment:** Archive from Xcode; distribute via App Store or Ad Hoc. Project structure does not include backend or env-specific deploy configs.

## Architecture Validation Results

### Coherence Validation ✅

**Decision compatibility:** Technology choices are consistent: Swift/SwiftUI, iOS 26.1+, Core Data, PDFKit, AVFoundation, no backend. No version conflicts. Patterns (PascalCase/camelCase, layer-based structure, throws/Result for errors, one-way data flow) align with the stack. No contradictory decisions (e.g. “no business logic in views” is supported by Stores and boundaries).

**Pattern consistency:** Implementation patterns support the decisions: Core Data and Swift naming match; structure (Models, Views, Stores, Persistence, Services) supports the layered architecture; communication (View → Store → Persistence/Service, main vs background actor) is coherent. Naming is consistent across entities, types, and files.

**Structure alignment:** The project tree supports all decisions: Persistence holds the Core Data model and repository; Services hold PDFParser and SpchPlayer; Stores and Views are separated. Boundaries (Views no direct persistence/services, Stores as single callers) are respected. Integration points (environment objects, repository interface, async parsing) are structured and one-way.

### Requirements Coverage Validation ✅

**Epic/feature coverage:** No epics; FR categories are the unit. Every FR category (Library, Folders, Queue, Playback, History, Settings, Accessibility, Error handling) is mapped to specific layers and files in Project Structure & Boundaries. Cross-cutting concerns (persistence, accessibility, error handling) are assigned to Persistence, all Views, and Stores/Views respectively.

**Functional requirements coverage:** All 51 FRs fall into the eight categories above; each category has architectural support (Core Data for persistence, many-to-many, queue/history; Stores + Services for parsing and playback; Views for UI and accessibility; error flow via throws and Store alert state). No FR category is missing a supporting decision or location.

**Non-functional requirements coverage:** Performance (off-main-thread parsing, bounded memory, History scale) is addressed in decisions and patterns. Reliability (persistence, recovery, migration) is in Data Architecture and implementation sequence. Accessibility (WCAG, VoiceOver, Dynamic Type) is in patterns and “all Views”. Security (on-device, sandbox) is documented. Usability (empty/loading states, native SwiftUI) is in UX and structure.

### Implementation Readiness Validation ✅

**Decision completeness:** Critical decisions are documented (Core Data, entities, migration, layers, state management, no API/auth). Technology stack and versions are specified. Integration and data flow are defined. No blocking decision is missing.

**Structure completeness:** Project tree is concrete (folder and file names); Views, Stores, Persistence, Services, Models, and test targets are specified. Integration points (App → RootView → Stores, Store ↔ Persistence, Store ↔ Services) and data flow are described. Component boundaries are defined.

**Pattern completeness:** Naming (Core Data, Swift, files), structure (layers, tests, assets), format (dates, errors), communication (no event bus, state updates, actions), and process (error handling, loading, validation) are specified. Examples and anti-patterns are given. Potential conflict points (naming, where logic lives, error surfacing) are addressed.

### Gap Analysis Results

**Critical gaps:** None. No missing decisions that block implementation; patterns and structure are sufficient to start.

**Important gaps (non-blocking):** (1) Core Data delete rules (cascade vs nullify for document/folder/history) can be fixed at implementation when defining the model. (2) Optional ReadPackCache and HistStore naming are noted as optional in structure; agents can introduce them when implementing. (3) Exact migration steps (one-time from in-memory/UserDefaults) can be detailed in the first persistence story.

**Nice-to-have gaps:** CI/CD and UI test layout could be expanded later. Additional examples for Observation vs ObservableObject can be added when the team chooses.

### Validation Issues Addressed

No critical or important validation issues required resolution. Optional refinements (delete rules, cache naming) are left for implementation and do not block completion.

### Architecture Completeness Checklist

**✅ Requirements analysis**

- [x] Project context thoroughly analyzed
- [x] Scale and complexity assessed
- [x] Technical constraints identified
- [x] Cross-cutting concerns mapped

**✅ Architectural decisions**

- [x] Critical decisions documented with versions
- [x] Technology stack fully specified
- [x] Integration patterns defined
- [x] Performance considerations addressed

**✅ Implementation patterns**

- [x] Naming conventions established
- [x] Structure patterns defined
- [x] Communication patterns specified
- [x] Process patterns documented

**✅ Project structure**

- [x] Complete directory structure defined
- [x] Component boundaries established
- [x] Integration points mapped
- [x] Requirements to structure mapping complete

### Architecture Readiness Assessment

**Overall status:** READY FOR IMPLEMENTATION

**Confidence level:** High — coherence, requirements coverage, and implementation readiness are satisfied; no critical gaps.

**Key strengths:**

- Clear layer separation (Views, Stores, Persistence, Services, Models) with explicit boundaries.
- FR and NFR coverage with concrete mapping to folders and files.
- Consistent naming and error/loading patterns that reduce agent conflict.
- Single persistence and data-flow model (Core Data + in-memory cache, one-way flow).

**Areas for future enhancement:**

- Define Core Data delete rules and optional TranscriptChunk when implementing.
- Add unit tests for persistence and parsing; optional UI tests for critical paths.
- Consider CI/CD and README once MVP is stable.

### Implementation Handoff

**AI agent guidelines:**

- Follow all architectural decisions exactly as documented in this file.
- Use implementation patterns consistently (naming, structure, errors, loading).
- Respect project structure and boundaries (no View → Persistence/Service; Store as single caller).
- Refer to this document for all architectural questions; update it when the team agrees on new patterns or structure.

**First implementation priority:** Add Core Data model (Document, Folder, HistoryItem; many-to-many Document–Folder) and persistence layer (stack + repository interface); then implement migration from current in-memory/UserDefaults state. Proceed with refactoring Stores to use the persistence layer and with the implementation sequence in Core Architectural Decisions.
