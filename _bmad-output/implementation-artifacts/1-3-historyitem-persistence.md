# Story 1.3: HistoryItem Persistence

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user,
I want my listening sessions to be stored (document, timestamp, position, duration),
So that history can be displayed and used for resume later.

## Acceptance Criteria

1. **Given** the Core Data model from Story 1.1  
   **When** the story is implemented  
   **Then** HistoryItem entity exists (or is extended) with: playedAt, lastSentenceId or equivalent position, durationSeconds, and relationship to Document  
   **And** the repository exposes methods to: save a history entry (after playback or pause), fetch history entries (optionally by document, date range, or folder)  
   **And** saved history entries persist across app restart and are returned by fetch methods (NFR-R1)

2. **Given** the user has played part of a document  
   **When** a history entry is saved  
   **Then** the entry includes document reference, timestamp, last position (sentence-level or equivalent), and duration (or equivalent)

## Tasks / Subtasks

- [x] **Task 1: Ensure HistoryItem entity in Core Data model** (AC: #1)
  - [x] Verify or add `HistoryItem` in `AuditLab.xcdatamodeld` with attributes: `playedAt` (Date), `lastSentenceId` or equivalent (String, optional), `durationSeconds` (Double or Integer 32), relationship to `Document` (to-one, required; delete rule: Nullify so deleted documents don't cascade-delete history)
  - [x] Ensure entity/attribute naming follows Architecture (PascalCase entities, camelCase attributes)
- [x] **Task 2: Extend repository with history CRUD** (AC: #1, #2)
  - [x] Add to repository protocol: `saveHistoryEntry(documentId:playedAt:lastSentenceId:durationSeconds:)` (or equivalent), `fetchHistoryEntries(byDocumentId:dateRange:folderId:)` (with optional filters)
  - [x] Implement all history methods in `DocumentRepository`; **all writes MUST use background context** (same pattern as Story 1.2); reads from viewContext
  - [x] Save is invoked after playback or pause; fetch supports filtering by document, date range, and optionally folder for future Epic 6
- [x] **Task 3: Unit tests for history persistence** (AC: #1, #2)
  - [x] Test: save history entry → fetch returns it; persist across in-memory store "restart" (new controller, same URL)
  - [x] Test: fetch by document, fetch with date range; fetch when empty returns empty array
  - [x] Test: delete document → history entries for that document (relationship nullify) handled per model delete rule
  - [x] Tests use in-memory PersistenceController; repository uses background context for writes

---

## Dev Notes

### Critical: Same Persistence Patterns as Story 1.2

**Background context for all writes.** The `viewContext` is READONLY. All repository mutations (including new history save/update) MUST use `persistenceController.newBackgroundContext()` and `context.perform { }` / `performAndWait { }`. Reads (fetch history) use `viewContext`. This is already established in Story 1.2; extend the same pattern to history methods.

**Repository:** `DocumentRepository` already holds `PersistenceController` and uses background context for queue and settings. Add history methods following the same pattern (no new init or structural change).

### HistoryItem Design

- **Position representation:** `lastSentenceId` (String) or equivalent (e.g. sentence index, chunk id) so Epic 5/6 can resume at sentence level (FR28, FR27). Architecture: "Persist playback position (e.g. sentence or offset) in HistoryItem or related entity."
- **Duration:** `durationSeconds` (Double or Int32) for "how long they listened" in this session; supports History UI (timestamp, position, duration per FR32).
- **Document relationship:** To-one to `Document`; delete rule **Nullify** so when a document is removed from the library, history entries remain but reference no document (or mark as unavailable in a later story). Per Story 2.5: "historical records (HistoryItem) that reference the document remain but are clearly marked as unavailable or handled per product rule."

### Epic and Scope

- **Epic 1: Persistent Data Foundation** — This story adds history persistence to the Core Data layer. It does NOT wire playback/UI to call save (that's Epic 5/6). It does NOT implement History UI (Epic 6). It only: (1) ensures HistoryItem entity/attributes, (2) adds repository save/fetch for history entries.
- **Do not modify:** Views, playback Stores, HistView, or any UI. Persistence-layer only.
- **Do extend:** DocumentRepository (and protocol) with history methods; Core Data model only if HistoryItem is missing or attributes differ from above.

### Project Structure Notes

- All new/modified files stay in `AuditLab/Persistence/` and `AuditLabTests/` (persistence tests).
- Modified: `AuditLab.xcdatamodeld` (if HistoryItem not already present or needs attribute tweaks), `DocumentRepository.swift` (add history methods).
- Modified: `AuditLabTests/DocumentRepositoryTests.swift` (add history persistence tests).
- [Source: _bmad-output/planning-artifacts/architecture.md#Project Structure & Boundaries]

### References

- [Source: _bmad-output/planning-artifacts/architecture.md#Data Architecture] — HistoryItem, playback position in Core Data
- [Source: _bmad-output/planning-artifacts/architecture.md#Naming Patterns] — PascalCase entities, camelCase attributes
- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.3] — Acceptance criteria and user story
- [Source: _bmad-output/implementation-artifacts/1-2-queue-and-app-settings-persistence.md] — Background context pattern, repository init
- [Source: _bmad-output/implementation-artifacts/1-1-core-data-model-and-persistence-stack.md] — Core Data model and repository baseline

---

## Technical Requirements

- **Core Data:** HistoryItem entity with `playedAt` (Date), `lastSentenceId` (String, optional), `durationSeconds` (Double or Int32), and relationship to Document (to-one; Nullify on delete). If HistoryItem already exists from Story 1.1, verify attributes match; extend only if needed.
- **Repository:** New methods `saveHistoryEntry(...)` and `fetchHistoryEntries(...)` with optional filters (document, date range, folder). All writes on background context; fetches on viewContext. Method signatures use `throws`; no silent error swallowing.
- **Ordering:** Fetch history entries in a defined order (e.g. playedAt descending) so UI can show "most recent first" in Epic 6.

---

## Architecture Compliance

- **Layered architecture:** Changes in Persistence layer only. No Views, Stores, or Services modified. [Source: architecture.md#Architectural Boundaries]
- **Single persistence store:** HistoryItem lives in the same Core Data stack. [Source: architecture.md#Data Architecture]
- **Background context pattern:** Same as Story 1.2 — all writes on background context; viewContext readonly for fetches. [Source: architecture.md#Communication Patterns]
- **One primary type per file:** No new Swift types; only Core Data model and DocumentRepository extensions. [Source: architecture.md#Naming Patterns]

---

## Library & Framework Requirements

- **Core Data:** System framework only. No new dependencies. iOS 26.1+.
- **Swift:** Same as project (Swift 6). Use `performAndWait` or `perform` for background context work in repository.

---

## File Structure Requirements

- **Modified:** `AuditLab/Persistence/AuditLab.xcdatamodeld` — ensure HistoryItem entity and attributes (if not already from 1.1)
- **Modified:** `AuditLab/Persistence/DocumentRepository.swift` — add history save/fetch methods
- **Modified:** `AuditLabTests/DocumentRepositoryTests.swift` — add history persistence tests
- **Do NOT create:** New View/Store/Service files. Do NOT wire playback or History UI to repository in this story.

---

## Testing Requirements

- **Unit tests:** In `DocumentRepositoryTests.swift`. Use in-memory `PersistenceController(inMemory: true)` and same background-context pattern as existing queue/settings tests.
- **History tests:** Save one or more history entries → fetch returns them in expected order; save with document relationship → delete document → history entry handling per delete rule; fetch with optional document filter and date range; fetch when no history returns empty array.
- **No UI or integration tests** in this story.

---

## Previous Story Intelligence

**From Story 1.2 (Queue and App Settings Persistence):**

- **Background context is mandatory.** DocumentRepository holds `PersistenceController`; every write uses `newBackgroundContext()` + `performAndWait` (or `perform`). viewContext is READONLY. This applies to the new history methods as well.
- **Repository pattern:** No init change needed; add new methods to existing DocumentRepository and protocol. Same error handling: `throws`, no force unwraps; use guard/cast and custom error type if needed.
- **Core Data model:** QueueEntry and AppSettings were added in 1.2. HistoryItem was specified in Story 1.1 model — verify it exists with playedAt, lastSentenceId (or equivalent), durationSeconds, and document relationship. If 1.1 omitted it or used different attribute names, add or align in this story.
- **Test pattern:** In-memory store; pass `PersistenceController` to DocumentRepository; verify data written on background is visible via viewContext fetch (automaticallyMergesChangesFromParent).

**From Story 1.1 (Core Data Model and Persistence Stack):**

- Core Data model includes Document, Folder, HistoryItem and many-to-many Document–Folder (via DocumentFolder join). HistoryItem was part of the original model spec (playedAt, lastSentenceId or equivalent, durationSeconds, relationship to Document). Confirm in actual .xcdatamodeld and extend only if missing or inconsistent.

---

## Project Context Reference

- **Architecture:** `_bmad-output/planning-artifacts/architecture.md`
- **Epics and AC:** `_bmad-output/planning-artifacts/epics.md`
- **Previous stories:** `_bmad-output/implementation-artifacts/1-1-core-data-model-and-persistence-stack.md`, `_bmad-output/implementation-artifacts/1-2-queue-and-app-settings-persistence.md`
- **PRD:** `_bmad-output/planning-artifacts/prd.md`

---

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

- HistoryItem entity already present in Core Data model (Story 1.1); changed Document.historyItems delete rule from Cascade to Nullify so history entries remain when document is deleted (document ref nullified).
- DocumentRepository: added saveHistoryEntry(document:playedAt:lastSentenceId:durationSeconds:) and fetchHistoryEntries(byDocument:byFolder:from:to:) with optional document, folder, and date-range filters; writes on background context, reads from viewContext; results sorted by playedAt descending. saveHistoryEntry throws invalidDuration for negative durationSeconds.
- DocumentRepositoryTests: added 6 history tests (save/fetch, empty fetch, by document, by date range, ordering, delete document nullifies history item's document). All 22 tests pass.
- Code review fixes: added optional folder filter to fetchHistoryEntries (AC1); added PersistenceController(storeURL:) for tests and testHistoryPersistsAcrossRestart; added durationSeconds >= 0 validation and testSaveHistoryEntryRejectsNegativeDuration; added testFetchHistoryEntriesByFolder. File List updated to include PersistenceController.swift and sprint-status.yaml.

### File List

- AuditLab/Persistence/AuditLab.xcdatamodeld/AuditLab.xcdatamodel/contents
- AuditLab/Persistence/DocumentRepository.swift
- AuditLab/Persistence/PersistenceController.swift
- AuditLabTests/DocumentRepositoryTests.swift
- _bmad-output/implementation-artifacts/sprint-status.yaml

## Change Log

- 2026-03-03: Implemented HistoryItem persistence. Document.historyItems delete rule set to Nullify; added saveHistoryEntry and fetchHistoryEntries to DocumentRepository (background writes, viewContext reads); added 6 unit tests. All 22 tests pass. Story ready for review.
- 2026-03-03: Code review fixes. Added folder filter to fetchHistoryEntries; restart-persistence test (PersistenceController(storeURL:)); duration validation and negative-duration test; by-folder fetch test. Updated File List.
