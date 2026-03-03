# Story 1.4: Migration from Current State to Core Data

Status: done

<!-- Note: Assume no prior app usage — no upgrade path. No migration from UserDefaults or in-memory legacy data. -->

## Story

As a user,
I want the app to use Core Data as the source of truth for library, folders, and queue,
So that my data persists across app restarts from day one.

## Acceptance Criteria

1. **Given** the app currently uses in-memory state for library, folders, and queue (no prior users; no existing UserDefaults data to migrate)  
   **When** the story is implemented  
   **Then** the app uses only Core Data (and agreed UserDefaults for trivial prefs if any) as the source of truth for library, folders, and queue  
   **And** LibStore, FoldStore, and QueueStore load from and write to Core Data via the repository (Story 1.1, 1.2)

2. **Given** the user adds documents, folders, or queue items  
   **When** they restart the app  
   **Then** that data appears in the app and persists across subsequent restarts (NFR-R1)

## Tasks / Subtasks

- [x] **Task 1: Wire LibStore to Core Data** (AC: #1, #2)
  - [x] Refactor LibStore to take DocumentRepository (protocol or concrete) via init or environment. Load documents from repository (fetchDocuments) and mutate via repository (addDocument, deleteDocument). Replace in-memory `recs: [PaperRec]` with repository-backed state; retain view-friendly type (e.g. map Document → PaperRec for `recs`) so existing Views need minimal change.
  - [x] Ensure new documents use UUID identity and repository addDocument; fileReference can be nil until document file storage is implemented in a later story.
- [x] **Task 2: Wire FoldStore to Core Data** (AC: #1, #2)
  - [x] Refactor FoldStore to take DocumentRepository. Load folders and document–folder links from repository (fetchFolders, fetchDocumentsInFolder, fetchFoldersForDocument); mutate via addFolder, deleteFolder, addDocumentToFolder, removeDocumentFromFolder. Replace in-memory `folds: [FoldRec]` with repository-backed state; map Folder/Document to FoldRec view type as needed.
- [x] **Task 3: Wire QueueStore to Core Data** (AC: #1, #2)
  - [x] Refactor QueueStore to take DocumentRepository. Load queue from fetchQueueEntries; mutate via addQueueEntry, updateQueueOrder, deleteQueueEntry, deleteAllQueueEntries. Replace in-memory `items: [QItem]` with repository-backed state; map QueueEntry to QItem (or equivalent) for views. Preserve queue order (orderIndex).
- [x] **Task 4: Inject persistence into app** (AC: #1)
  - [x] In AuditLabApp: create PersistenceController (e.g. .shared) and DocumentRepository, then create LibStore, FoldStore, QueueStore with repository injected. Pass Stores into the view hierarchy (environmentObject) as today. No migration step or guard — app simply uses Core Data from first launch.
- [x] **Task 5: Settings and trivial prefs** (AC: #1)
  - [x] AppSet already uses UserDefaults for skipAsk, figBg, wps. Story 1.2 added Core Data AppSettings for voice, speech rate, appearance. Leave that split as-is: Core Data for queue and AppSettings (voice, rate, appearance); UserDefaults only for trivial prefs (skipAsk, figBg, wps). No migration of legacy settings (assume no prior usage).
- [x] **Task 6: Tests and verification** (AC: #1, #2)
  - [x] Unit tests: with in-memory PersistenceController and DocumentRepository, verify Stores correctly load and mutate library, folders, queue via repository (e.g. add document via LibStore → fetch from repository returns it; same for folders and queue). Optionally verify data survives “restart” (new controller with same in-memory store URL).
  - [x] No regression: existing DocumentRepository and persistence tests (Stories 1.1–1.3) must still pass.

## Dev Notes

### Scope: No Upgrade Path

**Assumption:** Nobody has used the app. There is no existing data in UserDefaults or elsewhere to migrate. This story does not implement reading from legacy sources or a one-time migration guard — it only switches the app to use Core Data as the source of truth from first launch.

**Current state:** LibStore has `recs: [PaperRec]` (in-memory). FoldStore has `folds: [FoldRec]` (in-memory). QueueStore has `items: [QItem]` (in-memory). AppSet uses UserDefaults for skipAsk, figBg, wps. Refactor the three Stores to load from and write to DocumentRepository; inject the repository at app startup. No migration runner, no guard, no legacy read path.

**Mapping for views:** Document → PaperRec (identity.uuidString for id, title, addedAt; auths/date from metadata when available). Folder → FoldRec (identity.uuidString, name; pids from fetchDocumentsInFolder). QueueEntry → QItem (paperId, secOn, incApp, incSum). Preserve queue order via orderIndex.

### Epic and Scope

- **Epic 1: Persistent Data Foundation** — This story completes the foundation by wiring the app (Stores) to use Core Data as the single source of truth for library, folders, and queue. No new UI features; existing UI is wired to persistence.
- **Do not change:** Core Data model or repository API. Keep background-context pattern for all writes.
- **Do implement:** Store refactors to use DocumentRepository and injection of PersistenceController/DocumentRepository into the app.

### Project Structure Notes

- **Persistence:** No new persistence types. Use existing PersistenceController and DocumentRepository. No MigrationRunner or migration logic.
- **Stores:** LibStore, FoldStore, QueueStore take DocumentRepository (init or environment), load from repository, mutate via repository; publish view-friendly types (PaperRec, FoldRec, QItem) by mapping from Document, Folder, QueueEntry so Views need minimal change.
- **App entry:** AuditLabApp creates PersistenceController and DocumentRepository, then LibStore, FoldStore, QueueStore with repository injected. No migration step.
- [Source: _bmad-output/planning-artifacts/architecture.md#Project Structure & Boundaries]

### References

- [Source: _bmad-output/planning-artifacts/architecture.md#Data Architecture] — Single Core Data stack; app uses it as source of truth
- [Source: _bmad-output/planning-artifacts/architecture.md#Implementation Sequence] — Refactor stores to use persistence layer
- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.4] — Acceptance criteria and user story
- [Source: _bmad-output/implementation-artifacts/1-2-queue-and-app-settings-persistence.md] — Background context pattern, repository usage
- [Source: _bmad-output/implementation-artifacts/1-3-historyitem-persistence.md] — Repository pattern, PersistenceController
- [Source: _bmad-output/implementation-artifacts/1-1-core-data-model-and-persistence-stack.md] — Core Data model and repository baseline

---

## Technical Requirements

- **Repository only:** All writes to Core Data go through DocumentRepository. Use background context for all writes (existing pattern). No migration code; no direct NSManagedObjectContext insert/save outside repository.
- **Stores:** LibStore, FoldStore, QueueStore use DocumentRepository for all reads and writes. They retain view-friendly types (PaperRec, FoldRec, QItem) by mapping from Document, Folder, QueueEntry when publishing to views.
- **IDs:** Document and Folder use UUID identity. Map to/from string (e.g. identity.uuidString) for view types that use string id. QueueEntry.paperId remains string; document relationship optional.

---

## Architecture Compliance

- **Layered architecture:** Stores are the only callers of repository from UI layer. Views bind to Stores only. [Source: architecture.md#Architectural Boundaries]
- **Single persistence store:** All library, folder, and queue data lives in the same Core Data stack. [Source: architecture.md#Data Architecture]
- **Background context pattern:** All repository writes use background context per DocumentRepository pattern. [Source: architecture.md#Communication Patterns]
- **One-way data flow:** User action → View → Store → DocumentRepository → Core Data. No View → Persistence. [Source: architecture.md#Project Structure & Boundaries]

---

## Library & Framework Requirements

- **Core Data:** Same stack and model as Stories 1.1–1.3. No new frameworks. DocumentRepository and PersistenceController only.
- **UserDefaults:** Only for existing AppSet keys (skipAsk, figBg, wps). No migration or guard keys.
- **Swift:** Swift 6; async/await or performAndWait as in existing repository code.

---

## File Structure Requirements

- **Persistence:** No new files. DocumentRepository and PersistenceController unchanged.
- **Modified (Stores):** `LibStore.swift`, `FoldStore.swift`, `QueueStore.swift` — accept repository (protocol or concrete), load from repository, mutate via repository; retain published view-facing types (map Document/Folder/QueueEntry → PaperRec/FoldRec/QItem).
- **Modified (App):** `AuditLabApp.swift` — create PersistenceController and DocumentRepository, create Stores with repository injected (init or environment). No migration step.
- **Models/Types:** `Types.swift` — PaperRec, FoldRec, QItem remain for view binding; Stores map from Core Data types.
- **Tests:** Add Store/repository wiring tests (in-memory PersistenceController) to verify Stores load and persist via repository. No migration tests. Existing DocumentRepository tests must still pass.

---

## Testing Requirements

- **Unit tests:** With in-memory PersistenceController and DocumentRepository, verify Stores correctly load and mutate data (e.g. LibStore add → repository fetch returns document; FoldStore/QueueStore analogous). Optionally verify persistence across “restart” (new controller, same store URL).
- **No regression:** Existing DocumentRepository and persistence tests (Stories 1.1–1.3) must still pass.

---

## Previous Story Intelligence

**From Story 1.3 (HistoryItem Persistence):**

- **Background context for all writes.** Stores must call repository methods only; repository uses `newBackgroundContext()` and `performAndWait`. No direct context inserts in Stores.
- **PersistenceController:** Use `PersistenceController.shared` (or injected) in app; use in-memory or test store URL in tests.

**From Story 1.2 (Queue and App Settings Persistence):**

- Queue and settings are in Core Data (QueueEntry, AppSettings). QueueStore should use fetchQueueEntries, addQueueEntry, updateQueueOrder, deleteQueueEntry, deleteAllQueueEntries. AppSet: voice, speech rate, appearance in Core Data; skipAsk, figBg, wps in UserDefaults — leave as-is.

**From Story 1.1 (Core Data Model and Persistence Stack):**

- Core Data model has Document, Folder, HistoryItem, many-to-many Document–Folder, QueueEntry, AppSettings. Stores read/write via existing repository methods; no new entities or migration logic.

---

## Project Context Reference

- **Architecture:** `_bmad-output/planning-artifacts/architecture.md`
- **Epics and AC:** `_bmad-output/planning-artifacts/epics.md`
- **Previous stories:** `_bmad-output/implementation-artifacts/1-1-core-data-model-and-persistence-stack.md`, `_bmad-output/implementation-artifacts/1-2-queue-and-app-settings-persistence.md`, `_bmad-output/implementation-artifacts/1-3-historyitem-persistence.md`
- **PRD:** `_bmad-output/planning-artifacts/prd.md`

---

## Story Completion Status

- **Status:** done
- **Scope:** No upgrade path; assume no prior app usage. Story wires app to Core Data only (no migration from UserDefaults or in-memory legacy).

## Senior Developer Review (AI)

- **Review date:** 2026-03-03
- **Outcome:** Approve (after fixes)
- **Findings addressed:** 2 High, 3 Medium. Optional QueueEntry Booleans fixed; persistence errors logged in DEBUG; remove(atOffsets:) resyncs on partial failure; File List updated; repository API extension (updateFolderName) documented in Completion Notes.

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

- LibStore, FoldStore, QueueStore refactored to use DocumentRepository; load and mutate via repository; view types (PaperRec, FoldRec, QItem) retained and mapped from Core Data types.
- PersistenceController.shared and DocumentRepository injected in AuditLabApp; LibStore, FoldStore, QueueStore created with repository and passed as environmentObject.
- updateFolderName added to DocumentRepository (protocol + impl) for FoldStore rename persistence.
- FoldRec given explicit init(id:name:pids:) for loading from Folder.
- LibraryView uses lib.delete(r) and lib.add(rec, documentIdentity:pack:) for import; PlayerView uses lib.markRead(id:). QueueView uses q.remove(atOffsets:) and q.move(fromOffsets:toOffset:).
- StoreWiringTests added (LibStore, FoldStore, QueueStore add/delete/load via repository). testUpdateFolderName added to DocumentRepositoryTests. All existing DocumentRepository tests retained.
- **Code review fixes (2026-03-03):** QueueStore.entryToQItem now uses `entry.incApp ?? true` and `entry.incSum ?? true` for optional Core Data Booleans. All Stores log persistence failures in DEBUG. QueueStore.remove(atOffsets:) resyncs via loadEntries() on partial failure. File List updated with AuditLabUITests, project.pbxproj, and scheme. Repository API was extended with updateFolderName for FoldStore rename (documented deviation from “do not change API”).

### Change Log
- 2026-03-03: Story 1.4 implemented — LibStore, FoldStore, QueueStore wired to Core Data via DocumentRepository; persistence injected in AuditLabApp; Store wiring tests and updateFolderName test added.
- 2026-03-03: Code review — HIGH/MEDIUM fixes applied: optional QueueEntry Booleans, persistence error logging, remove(atOffsets:) resync on failure, File List updated; repository API extension documented.
- 2026-03-03: Code review (second pass) — LibStore @MainActor, load-failure DEBUG logging in all Stores, addDemo documentIdentity+pack, testLibStoreDataSurvivesRestart, File List with PersistenceController and xcdatamodel.

### File List
- AuditLab/AuditLabApp.swift
- AuditLab/LibStore.swift
- AuditLab/FoldStore.swift
- AuditLab/QueueStore.swift
- AuditLab/FoldRec.swift
- AuditLab/LibraryView.swift
- AuditLab/PlayerView.swift
- AuditLab/QueueView.swift
- AuditLab/Persistence/DocumentRepository.swift
- AuditLab/Persistence/PersistenceController.swift
- AuditLab/Persistence/AuditLab.xcdatamodeld/AuditLab.xcdatamodel/contents
- AuditLabTests/DocumentRepositoryTests.swift
- AuditLabTests/StoreWiringTests.swift (new)
- AuditLabUITests/AuditLabSmokeTests.swift (new)
- AuditLab.xcodeproj/project.pbxproj
- AuditLab.xcodeproj/xcshareddata/xcschemes/AuditLab.xcscheme
- _bmad-output/implementation-artifacts/sprint-status.yaml
