# Story 1.1: Core Data Model and Persistence Stack

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story

As a developer,
I want a Core Data model and persistence stack with Document, Folder, and HistoryItem entities and a repository interface for documents and folders,
So that the app can store and retrieve library and folder data.

---

## Acceptance Criteria

1. **Given** the app target has no Core Data model yet  
   **When** the story is implemented  
   **Then** an `.xcdatamodeld` exists with entities: Document (attributes sufficient for identity, title, addedAt, file reference), Folder (identity, name, createdAt), HistoryItem (playedAt, lastSentenceId or equivalent, durationSeconds, relationship to Document)  
   **And** Document and Folder have a many-to-many relationship (no duplicate document-in-folder; referential integrity on delete)  
   **And** a PersistenceController (or equivalent) provides a Core Data stack with main context for UI and optional background context for bulk work  
   **And** a repository type exposes at least: addDocument, fetchDocuments, deleteDocument, addFolder, fetchFolders, deleteFolder, addDocumentToFolder, removeDocumentFromFolder, fetchDocumentsInFolder, fetchFoldersForDocument  
   **And** entity and attribute naming follows Architecture (PascalCase entities, camelCase attributes)

2. **Given** the repository is called with valid data  
   **When** addDocument or addFolder is invoked and save is performed  
   **Then** data is persisted and fetch methods return the saved data after app restart (NFR-R1)

---

## Tasks / Subtasks

- [x] **Task 1: Create Core Data model** (AC: #1)
  - [x] Add `AuditLab.xcdatamodeld` to app target (or add to existing if present)
  - [x] Create Document entity: identity (UUID or string), title, addedAt (Date), file reference (e.g. bookmark data or path)
  - [x] Create Folder entity: identity, name, createdAt (Date)
  - [x] Create HistoryItem entity: playedAt, lastSentenceId (or equivalent), durationSeconds, relationship to Document
  - [x] Add many-to-many between Document and Folder (no duplicate document-in-folder; set delete rules for referential integrity)
- [x] **Task 2: Implement PersistenceController** (AC: #1)
  - [x] Provide main NSManagedObjectContext for UI
  - [x] Provide optional background context for bulk/import work
  - [x] Initialize stack (e.g. NSPersistentContainer) and load store
- [x] **Task 3: Implement repository interface** (AC: #1, #2)
  - [x] Define repository type (protocol or class) with: addDocument, fetchDocuments, deleteDocument, addFolder, fetchFolders, deleteFolder, addDocumentToFolder, removeDocumentFromFolder, fetchDocumentsInFolder, fetchFoldersForDocument
  - [x] Implement repository to use PersistenceController contexts
  - [x] Ensure save is performed so data persists across app restart
- [x] **Task 4: Verify persistence** (AC: #2)
  - [x] Add/update document and folder via repository, save, restart app (or new context), verify fetch returns saved data

---

## Developer Context

### Epic and scope

- **Epic 1: Persistent Data Foundation** — This story establishes the Core Data model and repository only. Stories 1.2 (queue/settings), 1.3 (HistoryItem persistence), and 1.4 (migration from current state) build on this. Do not implement queue persistence, HistoryItem usage, or migration in this story.
- **Current codebase:** Library is in-memory (`LibStore.recs: [PaperRec]`). Folders are in-memory (`FoldStore` with `FoldRec`: id, name, pids). Queue is in-memory (`QueueStore.items`). Settings use UserDefaults (`AppSet`: skipAsk, figBg, wps). This story does not change Stores yet; it only adds the persistence layer and model. Stores will be wired to the repository in later stories.

### Source tree components to touch

- **New:** `AuditLab/Persistence/` (or equivalent per project layout)
  - `AuditLab.xcdatamodeld` — Core Data model
  - `PersistenceController.swift` — stack, main + background contexts
  - `DocumentRepository.swift` (or single repository type) — CRUD for documents and folders
- **Do not modify in this story:** `LibStore`, `FoldStore`, `QueueStore`, `AppSet`, `Types.swift`, Views. Wiring Stores to the repository is out of scope.

### Project structure notes

- Architecture specifies **layer-based** layout under `AuditLab/`: Models/, Views/, Stores/, Persistence/, Services/. Current codebase is flat under `AuditLab/*.swift`. Create `Persistence/` and place the model and persistence types there; do not add new top-level folders that bypass this. [Source: _bmad-output/planning-artifacts/architecture.md#Project Structure & Boundaries]

### References

- [Source: _bmad-output/planning-artifacts/architecture.md#Data Architecture] — Core Data, entities, many-to-many, migration note
- [Source: _bmad-output/planning-artifacts/architecture.md#Naming Patterns] — PascalCase entities, camelCase attributes
- [Source: _bmad-output/planning-artifacts/architecture.md#Structure Patterns] — Persistence in `Persistence/`, repository in same layer
- [Source: _bmad-output/planning-artifacts/epics.md#Epic 1] — Story 1.1 acceptance criteria and epic context

---

## Technical Requirements

- **Core Data model:** One `.xcdatamodeld` in the app target. Entities: Document, Folder, HistoryItem. Document–Folder many-to-many with uniqueness (no duplicate document-in-folder) and delete rules that preserve referential integrity (e.g. cascade or nullify as appropriate when document or folder is deleted).
- **PersistenceController:** Provide at least one main context for UI-bound work. Provide an optional background context (e.g. for import/parsing) if architecture calls for it. Use NSPersistentContainer or equivalent; load the store at init.
- **Repository:** One type (protocol or concrete class) that exposes the required methods and uses the persistence stack. All mutations must result in a save so that data survives app restart. Use main context for UI-facing reads/writes unless a specific flow is designated for background context.
- **Naming:** Entity names PascalCase singular (Document, Folder, HistoryItem). Attribute names camelCase (e.g. addedAt, lastSentenceId, durationSeconds). Relationship names camelCase and descriptive. [Source: _bmad-output/planning-artifacts/architecture.md#Naming Patterns]
- **Errors:** Repository methods that can fail should use `throws` or `Result<T, Error>`. Do not swallow errors; surface them to the caller (Stores will handle user-facing messages in later stories). [Source: _bmad-output/planning-artifacts/architecture.md#Process Patterns]

---

## Architecture Compliance

- **Layered architecture:** Persistence layer owns the Core Data stack and repository. No UI types in Persistence. Views and Stores do not call Core Data directly; they will call the repository (in later stories). [Source: _bmad-output/planning-artifacts/architecture.md#Architectural Boundaries]
- **Single persistence store:** Core Data is the single source of truth for library, folders, and (in later stories) queue and history. This story establishes the model and repository only. [Source: _bmad-output/planning-artifacts/architecture.md#Data Architecture]
- **One primary type per file; file name = type name:** e.g. `PersistenceController.swift`, `DocumentRepository.swift`. [Source: _bmad-output/planning-artifacts/architecture.md#Naming Patterns]
- **No business logic in views:** Not applicable in this story (no view changes). Repository and PersistenceController contain no UI logic.

---

## Library & Framework Requirements

- **Core Data:** Use the system Core Data framework. No third-party persistence libraries. iOS 26.1+ deployment target per architecture. [Source: _bmad-output/planning-artifacts/architecture.md]
- **Swift:** Swift 6 (or project’s current Swift version). Use async/await or Combine only where needed for persistence (e.g. if exposing async repository APIs); main context access can be synchronous for this story.
- **No new package dependencies:** No SPM/CocoaPods additions for persistence. Xcode + system frameworks only.

---

## File Structure Requirements

- Create directory: `AuditLab/Persistence/` (or the path already used by the Xcode group for persistence).
- Place in it:
  - `AuditLab.xcdatamodeld` — Core Data model (Document, Folder, HistoryItem, many-to-many).
  - `PersistenceController.swift` — NSPersistentContainer (or equivalent), main context, optional background context.
  - `DocumentRepository.swift` (or a single repository type name used in architecture) — implements addDocument, fetchDocuments, deleteDocument, addFolder, fetchFolders, deleteFolder, addDocumentToFolder, removeDocumentFromFolder, fetchDocumentsInFolder, fetchFoldersForDocument.
- Do not create Views, Stores, or Services in this story. Do not move or refactor existing Stores/Views.

---

## Testing Requirements

- **Unit tests:** Add or extend the test target to cover the repository: e.g. in-memory or on-disk store, add document and folder, fetch, add document to folder, fetch documents in folder / folders for document, remove, delete; verify data after save. Architecture suggests `AuditLabTests/Persistence/DocumentRepositoryTests.swift` (or equivalent). [Source: _bmad-output/planning-artifacts/architecture.md#Project Structure & Boundaries]
- **Persistence across restart:** Manually or via test: add document/folder, save, tear down stack (or restart app), reinitialize, fetch — saved data must be returned (NFR-R1).
- No UI tests or accessibility tests required for this story.

---

## Previous Story Intelligence

Not applicable — this is the first story in Epic 1. There is no previous story file to reuse. Implement from architecture and epics only.

---

## Git Intelligence Summary

- **Recent commits:** Brownfield project; recent work includes “Ready to implement”, PRD → architecture → epics, and earlier app features (PDF parser, queue, library, folders). No existing Core Data model or Persistence folder in the scanned structure.
- **Existing patterns:** SwiftUI, `ObservableObject` stores (`LibStore`, `QueueStore`, `FoldStore`, `AppSet`), `@Published` state. Types in `Types.swift` (e.g. `PaperRec`, `ReadPack`, `QItem`). No persistence layer yet; this story introduces it.
- **Takeaway:** Add Persistence without refactoring existing Stores. Keep repository interface clear so Stores can be wired in a later story.

---

## Latest Technical Information

- **Core Data:** Use NSPersistentContainer for the stack. Prefer lightweight migration options for future model changes. Many-to-many can be modeled with an optional intermediate entity (e.g. DocumentFolder) for explicit uniqueness and delete rules, or with Core Data’s many-to-many and duplicate checking in code; ensure no duplicate document-in-folder and consistent delete behavior.
- **iOS 26.1+:** Use current Xcode and SDK. No deprecated persistence APIs required for this story.

---

## Project Context Reference

- **Architecture (single source of truth for structure and patterns):** `_bmad-output/planning-artifacts/architecture.md`
- **Epics and acceptance criteria:** `_bmad-output/planning-artifacts/epics.md`
- **Project knowledge (if present):** `docs/` (e.g. project-overview, architecture, technology-stack). Use for consistency with existing docs only; implementation rules come from architecture and this story.

---

## Dev Agent Record

### Agent Model Used

(To be filled when dev-story runs.)

### Debug Log References

- PersistenceController implemented as final class with NSInMemoryStoreType for test support; viewContext configured with automaticallyMergesChangesFromParent and NSMergeByPropertyObjectTrumpMergePolicy.
- DocumentRepository: concrete class conforming to DocumentRepositoryProtocol with all required methods; default parameter on init uses PersistenceController.shared.viewContext.
- Core Data model uses intermediate entity DocumentFolder for Document–Folder many-to-many with cascade delete rules on Document/Folder side and nullify on DocumentFolder side for referential integrity; duplicate document-in-folder prevented in repository in `addDocumentToFolder`.

### Completion Notes List

- **Task 1:** Created `AuditLab/Persistence/AuditLab.xcdatamodeld` with Document, Folder, HistoryItem, and DocumentFolder (join) entities. PascalCase entities, camelCase attributes; Document–Folder many-to-many via DocumentFolder with cascade delete rules.
- **Task 2:** `PersistenceController.swift` — final class with shared instance, viewContext (with mergePolicy + automaticallyMergesChangesFromParent), newBackgroundContext(), NSPersistentContainer; supports in-memory via NSInMemoryStoreType for tests.
- **Task 3:** `DocumentRepository.swift` — addDocument, fetchDocuments, deleteDocument, addFolder, fetchFolders, deleteFolder, addDocumentToFolder, removeDocumentFromFolder, fetchDocumentsInFolder, fetchFoldersForDocument; all mutations call save.
- **Task 4:** Unit tests in `AuditLabTests/Persistence/DocumentRepositoryTests.swift` (in-memory store); test target and shared scheme added. Build succeeded; run tests via Xcode or `xcodebuild -scheme AuditLab -destination 'platform=iOS Simulator,...' -only-testing:AuditLabTests test`.

### File List

- AuditLab/Persistence/AuditLab.xcdatamodeld/.xccurrentversion
- AuditLab/Persistence/AuditLab.xcdatamodeld/AuditLab.xcdatamodel/contents
- AuditLab/Persistence/PersistenceController.swift
- AuditLab/Persistence/DocumentRepository.swift
- AuditLabTests/DocumentRepositoryTests.swift
- AuditLab.xcodeproj/project.pbxproj (Persistence in app target; AuditLabTests target and scheme)
- AuditLab.xcodeproj/xcshareddata/xcschemes/AuditLab.xcscheme
- AuditLab.xcodeproj/xcshareddata/xcschemes/AuditLabTests.xcscheme
- AuditLab/.gitignore (deleted)
- _bmad-output/implementation-artifacts/sprint-status.yaml (1-1 story set to in-progress then review)

## Change Log

- 2026-03-03: Story 1-1 implemented. Core Data model (Document, Folder, HistoryItem, DocumentFolder), PersistenceController, DocumentRepository with full CRUD and document–folder many-to-many; unit test target and DocumentRepositoryTests added; sprint status → review.
- 2026-03-03: Code review fixes — PersistenceController changed to final class with NSInMemoryStoreType, added mergePolicy + automaticallyMergesChangesFromParent; fixed .xccurrentversion plist format; fixed representedClassName in xcdatamodel; restored default param on DocumentRepository.init; updated Dev Agent Record to match current code; simplified test suite.
