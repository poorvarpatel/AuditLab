# Story 1.2: Queue and App Settings Persistence

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story

As a user,
I want the playback queue and my app settings (voice, speech rate, appearance) to be stored by the persistence layer,
So that the queue and preferences survive app restart.

---

## Acceptance Criteria

1. **Given** the Core Data model and repository from Story 1.1
   **When** the story is implemented
   **Then** the model or repository supports persisting an ordered queue (ordered list of document references or queue entries)
   **And** the model or repository (or agreed UserDefaults boundary) supports persisting: selected voice identifier, speech rate, appearance (system/light/dark)
   **And** repository (or equivalent) methods exist to save and load queue order and settings
   **And** after app restart, loaded queue order and settings match the last saved state (FR34, FR35, FR36 infrastructure; NFR-R1)

2. **Given** the user has set a voice and added items to the queue
   **When** the app is terminated and relaunched
   **Then** the queue content and order and the selected voice (and rate, appearance) are restored

---

## Tasks / Subtasks

- [x] **Task 1: Add QueueEntry entity to Core Data model** (AC: #1)
  - [x] Add `QueueEntry` entity to `AuditLab.xcdatamodeld` with attributes: `identity` (UUID), `orderIndex` (Integer 32), `paperId` (String), `secOn` (Transformable/Binary — set of section IDs), `incApp` (Boolean), `incSum` (Boolean)
  - [x] Add relationship from `QueueEntry` to `Document` (optional to-one, nullify on delete) so queue entries referencing deleted documents can be cleaned up
  - [x] Verify model version/migration: since the store was just created in 1.1 and no user data exists yet, adding the entity directly to the existing model version is acceptable (no lightweight migration needed for fresh stores)
- [x] **Task 2: Add AppSettings entity to Core Data model** (AC: #1)
  - [x] Add `AppSettings` entity with attributes: `voiceIdentifier` (String, optional), `speechRate` (Double, default 2.8), `appearance` (String, default "system" — values: "system", "light", "dark"), `skipAsk` (Boolean, default true), `figBg` (Boolean, default true)
  - [x] AppSettings is a singleton row — repository enforces at most one instance
- [x] **Task 3: Extend repository with queue CRUD** (AC: #1, #2)
  - [x] Add to `DocumentRepositoryProtocol`: `addQueueEntry(identity:paperId:orderIndex:secOn:incApp:incSum:)`, `fetchQueueEntries() -> [QueueEntry]` (sorted by orderIndex ascending), `deleteQueueEntry(_:)`, `deleteAllQueueEntries()`, `updateQueueOrder(entries:)` (bulk reorder)
  - [x] Implement all queue methods in `DocumentRepository`
  - [x] **All mutations MUST use a background context** (`PersistenceController.shared.newBackgroundContext()`), perform work inside `context.perform { }`, and save on that context. The `viewContext` is READONLY — never call `viewContext.save()` for mutations.
  - [x] `fetchQueueEntries` reads from `viewContext` (readonly); `automaticallyMergesChangesFromParent` on viewContext will pick up background saves automatically
- [x] **Task 4: Extend repository with settings CRUD** (AC: #1, #2)
  - [x] Add to `DocumentRepositoryProtocol`: `saveSettings(voiceIdentifier:speechRate:appearance:skipAsk:figBg:)`, `fetchSettings() -> AppSettings?`
  - [x] Implement: upsert pattern — fetch existing AppSettings row; if none, insert; update attributes; save. **Use background context for writes.**
  - [x] `fetchSettings` reads from `viewContext` (readonly)
- [x] **Task 5: Refactor existing repository mutations to use background context** (AC: #1)
  - [x] Refactor ALL existing `DocumentRepository` write methods (addDocument, deleteDocument, addFolder, deleteFolder, addDocumentToFolder, removeDocumentFromFolder) to use `newBackgroundContext()` + `context.perform { }` instead of `viewContext`
  - [x] Keep ALL fetch/read methods on `viewContext` (readonly)
  - [x] Update `PersistenceController` if needed (viewContext already has `automaticallyMergesChangesFromParent = true`, which is correct)
  - [x] Ensure the repository holds a reference to `PersistenceController` (not just a single context) so it can create background contexts on demand
- [x] **Task 6: Unit tests for queue and settings persistence** (AC: #2)
  - [x] Test: add queue entries with different orderIndex values, fetch, verify order
  - [x] Test: delete a queue entry, verify it's removed
  - [x] Test: deleteAllQueueEntries clears the queue
  - [x] Test: updateQueueOrder reorders correctly
  - [x] Test: saveSettings creates a row; subsequent saveSettings updates same row (singleton)
  - [x] Test: fetchSettings returns saved values
  - [x] Test: queue entry with relationship to Document — delete document, verify queue entry handling
  - [x] Tests use in-memory PersistenceController with background context pattern

---

## Dev Notes

### Critical Architecture Directive: Background Context for All Writes

**The `viewContext` is READONLY.** All mutations (insert, update, delete, save) MUST happen on a background context obtained from `PersistenceController.shared.newBackgroundContext()`. Work must be wrapped in `context.perform { }` (or `context.performAndWait { }` for synchronous test helpers).

The `viewContext` has `automaticallyMergesChangesFromParent = true` and `NSMergeByPropertyObjectTrumpMergePolicy`, so background saves propagate to the UI context automatically. This pattern:
- Keeps the main thread free of Core Data write blocking
- Prevents UI hitches from saves
- Is the standard production Core Data pattern for iOS

**This means the existing Story 1.1 repository methods that write on `viewContext` must be refactored in this story** (Task 5). The refactor is scoped to changing the context used for writes — no API signature changes, no Store wiring changes.

### Repository Architecture Change

Current `DocumentRepository` holds a single `NSManagedObjectContext` (viewContext). This must change to hold a reference to `PersistenceController` so it can:
- Read from `viewContext` (readonly, for fetches)
- Create `newBackgroundContext()` for each write operation

**New init signature:**
```swift
final class DocumentRepository: DocumentRepositoryProtocol {
    private let persistenceController: PersistenceController

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }
    
    private var viewContext: NSManagedObjectContext {
        persistenceController.viewContext
    }
}
```

**Write method pattern:**
```swift
func addDocument(identity: UUID, title: String, addedAt: Date, fileReference: Data?) throws {
    let bgContext = persistenceController.newBackgroundContext()
    try bgContext.performAndWait {
        let doc = Document(context: bgContext)
        doc.identity = identity
        doc.title = title
        doc.addedAt = addedAt
        doc.fileReference = fileReference
        try bgContext.save()
    }
}
```

**Read method pattern (unchanged — viewContext, readonly):**
```swift
func fetchDocuments() throws -> [Document] {
    let request = Document.fetchRequest()
    request.sortDescriptors = [NSSortDescriptor(keyPath: \Document.addedAt, ascending: false)]
    return try viewContext.fetch(request)
}
```

### Queue Persistence Design

The queue is an **ordered list** of items, each referencing a document (by paperId string) with playback configuration (secOn, incApp, incSum). This maps to a `QueueEntry` Core Data entity with an `orderIndex` integer for ordering.

**Why not a to-many ordered relationship on a "Queue" entity?** Core Data ordered relationships have known performance and merge issues. An explicit `orderIndex` attribute is simpler, more debuggable, and standard for ordered lists in Core Data.

**`updateQueueOrder` method:** Accepts an array of `QueueEntry` objectIDs in desired order, fetches each on a background context, sets `orderIndex` = array position, saves once. This supports drag-to-reorder in QueueStore.

**Queue–Document relationship:** Optional to-one from QueueEntry → Document. Delete rule: Nullify. When a document is deleted, the queue entry's `document` relationship becomes nil. The queue entry itself remains (or can be cleaned up by the Store in a later story when it wires to the repository). This preserves queue order even if a document is temporarily unavailable.

### App Settings Design

Settings that are currently in `AppSet` via UserDefaults (`skipAsk`, `figBg`, `wps`) plus new settings from the PRD/architecture (`voiceIdentifier`, `speechRate`, `appearance`) are consolidated into a single `AppSettings` Core Data entity.

**Singleton pattern:** The repository enforces exactly one AppSettings row. `saveSettings` fetches the existing row (if any) and updates it; if none exists, it inserts one. This avoids duplicate rows.

**Why Core Data instead of UserDefaults?** Architecture specifies "Core Data as single source of truth" with "UserDefaults only where it's the right tool (e.g. trivial UI prefs)." Voice, rate, appearance, and queue are not trivial — they're part of the app's persistent state that should survive backup/restore consistently with the rest of the data. Consolidating into Core Data simplifies the persistence boundary.

**Migration of existing UserDefaults values:** Out of scope for this story (Story 1.4 handles migration). This story only creates the Core Data entity and repository methods. The existing `AppSet` store continues to use UserDefaults until Story 1.4 wires it.

### Epic and Scope

- **Epic 1: Persistent Data Foundation** — This story adds queue and settings persistence to the Core Data layer established in Story 1.1. It does NOT wire Stores to the repository (that's Story 1.4 migration). It does NOT implement HistoryItem usage (that's Story 1.3).
- **Do not modify:** Views, QueueStore, FoldStore, LibStore, or AppSet. Do not add any UI changes. This is persistence-layer only.
- **Do refactor:** DocumentRepository to use background contexts for all writes (including the existing document/folder methods from Story 1.1).

### Project Structure Notes

- All new/modified files stay in `AuditLab/Persistence/`
- Modified: `AuditLab.xcdatamodeld` (add QueueEntry, AppSettings entities), `DocumentRepository.swift` (add queue/settings methods + refactor to background context), `PersistenceController.swift` (if needed)
- Modified: `AuditLabTests/DocumentRepositoryTests.swift` (add queue/settings tests, update existing tests for background context pattern)
- No new top-level directories. No new files outside Persistence and Tests.
- [Source: _bmad-output/planning-artifacts/architecture.md#Project Structure & Boundaries]

### References

- [Source: _bmad-output/planning-artifacts/architecture.md#Data Architecture] — Core Data as single store; queue and settings persistence
- [Source: _bmad-output/planning-artifacts/architecture.md#Naming Patterns] — PascalCase entities, camelCase attributes
- [Source: _bmad-output/planning-artifacts/architecture.md#Process Patterns] — throws at boundary; no silent swallows
- [Source: _bmad-output/planning-artifacts/architecture.md#Architectural Boundaries] — Persistence owns Core Data; Stores call repository
- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.2] — Acceptance criteria and epic context
- [Source: _bmad-output/implementation-artifacts/1-1-core-data-model-and-persistence-stack.md] — Previous story implementation details

---

## Technical Requirements

- **Core Data model update:** Add `QueueEntry` and `AppSettings` entities to existing `AuditLab.xcdatamodeld`. Entity names PascalCase singular. Attribute names camelCase. QueueEntry has optional to-one relationship to Document (inverseName: `queueEntries`, delete rule: Nullify on QueueEntry side, no cascade from Document to QueueEntry — use Nullify so deleting a document doesn't silently remove queue entries).
- **Background context for all writes:** Every repository method that inserts, updates, or deletes MUST use `persistenceController.newBackgroundContext()` wrapped in `context.perform { }` or `context.performAndWait { }`. The viewContext is READONLY — used only for fetch operations. This applies to ALL repository methods, including the existing ones from Story 1.1.
- **Repository init change:** `DocumentRepository` must hold a `PersistenceController` reference instead of a single `NSManagedObjectContext`. This is a breaking change to the init signature but the protocol interface (method signatures) does not change for existing methods.
- **Errors:** All new repository methods use `throws`. Do not swallow errors. Surface them to the caller.
- **Ordering:** QueueEntry uses `orderIndex` (Integer 32) for sort order. `fetchQueueEntries` returns sorted by `orderIndex` ascending.
- **Settings singleton:** Repository enforces one AppSettings row via upsert pattern.

---

## Architecture Compliance

- **Layered architecture:** All changes in Persistence layer only. No Views, no Stores, no Services modified. [Source: architecture.md#Architectural Boundaries]
- **Single persistence store:** Core Data remains the single source of truth. New entities extend the existing model. [Source: architecture.md#Data Architecture]
- **Background context pattern:** All writes on background context; viewContext readonly. `automaticallyMergesChangesFromParent` ensures UI sees updates. [Source: architecture.md#Communication Patterns — "Run parsing and heavy work off the main actor"]
- **One primary type per file; file name = type name:** No new Swift files needed — QueueEntry and AppSettings are Core Data generated classes. Repository and PersistenceController are modified in place. [Source: architecture.md#Naming Patterns]
- **No business logic in views:** N/A — no view changes in this story.

---

## Library & Framework Requirements

- **Core Data:** System framework only. No third-party persistence libraries. iOS 26.1+.
- **Swift:** Swift 6 (or project's current version). Use `performAndWait` for synchronous write helpers in repository; `perform` with async/await if preferred. Both are valid.
- **No new package dependencies.** Xcode + system frameworks only.

---

## File Structure Requirements

- **Modified:** `AuditLab/Persistence/AuditLab.xcdatamodeld/AuditLab.xcdatamodel/contents` — add QueueEntry, AppSettings entities
- **Modified:** `AuditLab/Persistence/DocumentRepository.swift` — add queue/settings methods; refactor all write methods to background context; change init to accept PersistenceController
- **Modified:** `AuditLab/Persistence/PersistenceController.swift` — only if changes needed (likely no changes; viewContext already configured correctly)
- **Modified:** `AuditLabTests/DocumentRepositoryTests.swift` — add queue and settings tests; update existing tests for background context pattern
- **Modified:** `AuditLab.xcodeproj/project.pbxproj` — only if Xcode requires it for model changes
- **Do NOT create:** New View files, new Store files, new Service files. Do NOT move or rename existing files.

---

## Testing Requirements

- **Unit tests:** Extend `AuditLabTests/DocumentRepositoryTests.swift` (or add a new `QueueRepositoryTests.swift` if preferred for organization). Use in-memory `PersistenceController(inMemory: true)`.
- **Queue tests:**
  - Add 3 queue entries with orderIndex 0, 1, 2 → fetchQueueEntries returns them in order
  - Delete middle entry → fetch returns 2 entries in correct order
  - deleteAllQueueEntries → fetch returns empty
  - updateQueueOrder with reversed order → fetch returns reversed
  - Add queue entry with document relationship → delete document → queue entry still exists with nil document
- **Settings tests:**
  - fetchSettings on empty store → returns nil
  - saveSettings → fetchSettings returns saved values
  - saveSettings twice → still one row (singleton), second values returned
  - Verify default values (speechRate 2.8, appearance "system")
- **Background context verification:** Tests should use the same in-memory PersistenceController pattern but verify that write operations complete and data is fetchable via viewContext (proves automaticallyMergesChangesFromParent works).
- **Existing test update:** Existing document/folder tests may need minor adjustments if the init signature changes, but behavior should remain identical.

---

## Previous Story Intelligence

**From Story 1.1 (Core Data Model and Persistence Stack):**

- **PersistenceController:** `final class` with `NSPersistentContainer`, `viewContext` (with `automaticallyMergesChangesFromParent = true` and `NSMergeByPropertyObjectTrumpMergePolicy`), `newBackgroundContext()`. Supports `inMemory` for tests. This is exactly the foundation needed for background writes.
- **DocumentRepository:** Currently takes a single `NSManagedObjectContext` (defaulting to `PersistenceController.shared.viewContext`). **This must be refactored** to hold `PersistenceController` instead so it can create background contexts. The protocol interface does not change.
- **Core Data model:** Uses intermediate `DocumentFolder` entity for Document–Folder many-to-many with cascade delete rules on Document/Folder side. QueueEntry and AppSettings are new additions alongside existing entities.
- **Test pattern:** In-memory store via `PersistenceController(inMemory: true)`, repository initialized with that controller's context. Tests will need to be updated to pass the controller instead.
- **Key learning:** Code review caught several issues in 1.1 (PersistenceController needed `final`, mergePolicy, default param on init). Expect similar scrutiny — ensure background context pattern is correct from the start.

---

## Git Intelligence Summary

- **Latest commit:** `a5859aa` — "Added core data and test target, added core data tests (#3)". This is the Story 1.1 implementation. Files added: `AuditLab/Persistence/` (model, PersistenceController, DocumentRepository), `AuditLabTests/DocumentRepositoryTests.swift`, xcschemes.
- **Existing patterns:** ObservableObject stores (LibStore, QueueStore, FoldStore, AppSet) with `@Published` state. Types in `Types.swift` (PaperRec, ReadPack, QItem, QueueItem, FoldRec). No persistence wiring yet — stores are all in-memory.
- **QueueStore current state:** `items: [QItem]` in-memory array with `idx` for current position. Supports add, remove, move, clear, folder playback. QItem has: paperId, secOn (Set<String>), incApp, incSum. The QueueEntry Core Data entity must mirror these fields.
- **AppSet current state:** `skipAsk` (Bool), `figBg` (Bool), `wps` (Double) via UserDefaults. Architecture adds: voiceIdentifier (String), speechRate (Double → maps to wps), appearance (String). The AppSettings entity consolidates all of these.
- **Takeaway:** Build the persistence entities to match the existing in-memory types exactly so Story 1.4 (migration) can wire them seamlessly.

---

## Latest Technical Information

- **Core Data `perform`/`performAndWait`:** On iOS 15+ (our target is 26.1+), `NSManagedObjectContext.perform { }` is async and `performAndWait { }` is synchronous. For repository methods that `throw`, use the closure-based `performAndWait` which allows re-throwing errors from inside the closure.
- **Core Data Transformable:** For `secOn` (Set<String>), use `Transformable` attribute type with `NSSecureUnarchiveFromData` transformer (or store as Binary with manual JSON encode/decode). The secure transformer is preferred for type safety. Alternatively, store as a comma-separated String and convert in the repository — simpler and avoids transformer registration.
- **Ordered relationships vs. orderIndex:** Core Data ordered to-many relationships (`isOrdered = true`) have known issues with merge conflicts and performance. Explicit `orderIndex` integer attribute is the recommended pattern for ordered collections.
- **No deprecated APIs:** `NSPersistentContainer`, `NSManagedObjectContext.perform`, `performAndWait` are all current and non-deprecated on iOS 26.1+.

---

## Project Context Reference

- **Architecture (single source of truth):** `_bmad-output/planning-artifacts/architecture.md`
- **Epics and acceptance criteria:** `_bmad-output/planning-artifacts/epics.md`
- **Previous story:** `_bmad-output/implementation-artifacts/1-1-core-data-model-and-persistence-stack.md`
- **PRD:** `_bmad-output/planning-artifacts/prd.md`
- **Project knowledge:** `docs/` (project-overview, architecture, technology-stack)

---

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

- QueueEntry and AppSettings entities added to AuditLab.xcdatamodel (Document inverse relationship queueEntries with Nullify). secOn stored as Binary (JSON array of strings).
- DocumentRepository refactored to hold PersistenceController; all writes use newBackgroundContext() + performAndWait; reads use viewContext. Protocol extended with queue CRUD and settings save/fetch; addQueueEntry accepts optional document for relationship.
- DocumentRepositoryTests updated to DocumentRepository(persistenceController:); added queue tests (order, delete, deleteAll, updateQueueOrder, document nullify) and settings tests (create, singleton update, fetch nil when empty). All 13 tests pass.
- **Code review fixes (AI):** (1) File List updated to include project.pbxproj, AuditLabTests.xcscheme, testplans/AuditLabTests.xctestplan. (2) Replaced force unwraps (as!) in DocumentRepository with guard/cast and DocumentRepositoryError.invalidObjectType. (3) Added tests: testAppSettingsDefaultValuesPersisted, testSaveSettingsWithNilVoiceIdentifier, testUpdateQueueOrderEmptyArrayIsNoOp. (4) Added doc comments on queue and settings repository methods.

### File List

- AuditLab/Persistence/AuditLab.xcdatamodeld/AuditLab.xcdatamodel/contents
- AuditLab/Persistence/DocumentRepository.swift
- AuditLabTests/DocumentRepositoryTests.swift
- AuditLab.xcodeproj/project.pbxproj
- AuditLab.xcodeproj/xcshareddata/xcschemes/AuditLabTests.xcscheme
- testplans/AuditLabTests.xctestplan

## Change Log

- 2025-03-03: Implemented queue and app settings persistence. Added QueueEntry and AppSettings to Core Data model; extended DocumentRepository with queue CRUD and settings upsert; refactored all repository writes to background context; added unit tests. Story ready for review.
- 2025-03-03: Code review fixes applied: safe casts and DocumentRepositoryError in DocumentRepository; File List completed; doc comments on queue/settings methods; tests for default values, nil voiceIdentifier, empty updateQueueOrder.
