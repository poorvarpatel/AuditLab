# Story 2.1: Add PDF to Library via Document Picker

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user,
I want to add a PDF to my library from the document picker,
So that I can later organize, queue, and listen to it.

## Acceptance Criteria

1. **Given** the persistence layer from Epic 1 is available  
   **When** the user taps Add and selects a valid PDF from the document picker  
   **Then** the app invokes the PDF parsing service (off main thread per NFR-P1) and, on success, persists the document via the repository  
   **And** the new document appears in the library list and persists across restart (FR1, FR5)  
   **And** a loading or progress indicator is shown within 500 ms for the add operation (NFR-P3, NFR-U2)

2. **Given** the user selects a file  
   **When** parsing completes successfully  
   **Then** the document is stored with identifiable metadata (e.g. title) for display in the library (FR3)

## Tasks / Subtasks

- [x] **Task 1: Wire document picker to LibStore add flow** (AC: #1, #2)
  - [x] Ensure LibraryView (or equivalent) passes selected URL from DocumentPicker into LibStore (e.g. `addDocument(from: url)` or `importPDF(url:)`). DocumentPicker already exists at `Views/.../DocumentPicker.swift` and is used in LibraryView — do not reimplement; wire its completion to the store.
  - [x] LibStore method must run PDF parsing off the main thread (e.g. `Task { }` or background context), then on success call DocumentRepository.addDocument (or equivalent) and update published state on main actor.
- [x] **Task 2: PDF parsing and persistence** (AC: #1, #2)
  - [x] Invoke PDFParser (or existing parsing service) with the picked URL. Parsing must run off main thread (NFR-P1). On success: create/persist Document via repository with metadata (e.g. title from parsed PDF or filename); ensure document has identity and file reference as required by repository.
  - [x] Map persisted Document to view type (e.g. PaperRec) so the new document appears in the library list immediately and after restart.
- [x] **Task 3: Loading and progress UX** (AC: #1)
  - [x] Show a loading or progress indicator within 500 ms when add is in progress (NFR-P3, NFR-U2). Use a single loading state per add operation (e.g. `isAddingDocument` or `addingDocumentTask` in LibStore); avoid multiple overlapping spinners. [Source: architecture.md#Process Patterns]
- [x] **Task 4: Verification** (AC: #1, #2)
  - [x] Implement or confirm the verification steps in "How to verify this works" below so the feature can be validated manually and, where applicable, by tests.

## How to verify this works

**Manual verification (required):**

1. **Add a valid PDF**
   - Launch the app → Library tab.
   - Tap Add (or equivalent) and choose a valid PDF from the document picker.
   - **Expect:** A loading indicator appears within ~500 ms. After parsing completes, the new document appears in the library list with identifiable metadata (e.g. title).
2. **Persistence across restart**
   - After adding a PDF, fully terminate the app and relaunch.
   - **Expect:** The same document still appears in the library list (FR5).
3. **No UI freeze**
   - Add a PDF (optionally a larger one).
   - **Expect:** UI remains responsive during parsing; no freeze or indefinite blank screen (NFR-P1).

**Optional automated verification:**

- **Unit:** With in-memory PersistenceController and a mock or real PDFParser, call LibStore’s add method with a test PDF URL; assert repository contains the new Document and LibStore’s published list includes it; assert loading state is set and then cleared.
- **UI:** If UI tests exist, add a flow: tap Add → select a test PDF (e.g. from test bundle) → assert library list gains one item and (after relaunch) still shows it.

Use these steps to confirm the story is complete and to catch regressions.

## Dev Notes

- **Epic 2: Library & Document Management** — This is the first story: adding a PDF from the document picker, parsing off main thread, persisting via repository, and showing the document in the library with correct loading UX.
- **Existing pieces:** DocumentPicker (UIDocumentPickerViewController for PDFs) and LibraryView already exist. LibStore and DocumentRepository are wired from Epic 1. Do not reimplement the picker; wire its callback to LibStore and ensure parsing + persistence follow architecture (Store → PDFParser, Store → DocumentRepository; parsing off main thread).
- **File reference:** Repository may expect a file reference or bookmark for the document; store whatever the persistence layer needs for later access (e.g. security-scoped bookmark or path). Architecture: "Document (attributes sufficient for identity, title, addedAt, file reference)."

### Project Structure Notes

- **Views/Library:** LibraryView, DocumentPicker — use existing; ensure Add action calls LibStore.
- **Stores:** LibStore — add method to accept URL from picker, run parsing off main thread, then persist via DocumentRepository and update state on main.
- **Services:** PDFParser — invoke from LibStore; do not call from View. [Source: architecture.md#Project Structure & Boundaries]
- **Persistence:** DocumentRepository.addDocument (or equivalent) — call from LibStore after successful parse.

### References

- [Source: _bmad-output/planning-artifacts/architecture.md#Data Architecture] — Core Data, repository, main/background context
- [Source: _bmad-output/planning-artifacts/architecture.md#Process Patterns] — Loading states, one indicator per operation, ~500 ms
- [Source: _bmad-output/planning-artifacts/architecture.md#Communication Patterns] — Main thread for UI state; parsing off main
- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.1] — Acceptance criteria and FR1, FR3, FR5, NFR-P1, NFR-P3, NFR-U2

---

## Technical Requirements

- **Off main thread:** PDF parsing must not run on the main actor. Use `Task { }` or a background queue; hop back to main for Store state updates and repository calls that drive UI (or use repository’s existing background-context pattern if it handles threading).
- **Repository:** Persist the new document only via DocumentRepository (e.g. `addDocument`). Use existing Core Data stack and entities (Document with identity, title, addedAt, file reference as defined in Story 1.1).
- **Loading:** One loading state per add operation; show indicator within 500 ms. Clear loading state on success or failure.

---

## Architecture Compliance

- **Layered architecture:** View → LibStore only. LibStore calls PDFParser and DocumentRepository; no View → Persistence or View → PDFParser. [Source: architecture.md#Architectural Boundaries]
- **Data flow:** User taps Add → DocumentPicker presents → user picks URL → View passes URL to LibStore → LibStore runs parse (off main) → on success calls repository → updates Store state on main → View refreshes. [Source: architecture.md#Frontend Architecture]
- **Error handling:** Parsing or persistence failures must set user-facing message in Store state; show in Alert/banner (Story 2.2 covers error UX in detail; for this story, ensure errors are not swallowed and can be surfaced).

---

## Library & Framework Requirements

- **PDFKit / existing PDF parsing:** Use the project’s existing PDF parsing service (e.g. PDFParser in Services). Do not introduce a new PDF library unless architecture explicitly allows.
- **UIDocumentPickerViewController:** Already used via DocumentPicker; use `forOpeningContentTypes: [.pdf]`. Handle security-scoped resource if required for persistent file access.
- **Swift concurrency:** Prefer async/await and `@MainActor` for UI-bound state updates. Off-main parsing as above.

---

## File Structure Requirements

- **Modified:** `LibStore.swift` — add method to accept picked URL; coordinate parsing and repository add; publish loading state and updated document list.
- **Modified:** `LibraryView.swift` (or equivalent) — ensure DocumentPicker completion passes selected URL to LibStore and that loading state is shown (e.g. overlay or progress view).
- **Unchanged:** DocumentPicker.swift — reuse as-is unless a small change is needed for callback shape. Persistence/, DocumentRepository, PDFParser — use existing APIs; add no new persistence types.
- **Tests:** Add or extend unit tests for LibStore add flow (mock or in-memory repository + stub parser) and optional UI test for add + persist + restart, per "How to verify this works."

---

## Testing Requirements

- **Unit:** Verify LibStore add flow: given a URL, parsing is triggered off main; on success, repository receives new Document and Store’s published list includes it; loading state is set then cleared; on parse/repository failure, loading is cleared and error state can be set.
- **Regression:** Existing DocumentRepository and persistence tests (Epic 1) must still pass. Do not break existing add/fetch behavior.

---

## Previous Story Intelligence

**From Epic 1 (Stories 1.1–1.4):**

- DocumentRepository exposes `addDocument`, `fetchDocuments`, etc. All writes use background context; main context for UI reads. LibStore is wired to DocumentRepository and maps Document → PaperRec for views.
- PersistenceController and Core Data model (Document, Folder, HistoryItem) are in place. Document has identity, title, addedAt, file reference.
- Stores are injected with DocumentRepository at app launch (AuditLabApp). Use the same pattern: LibStore receives URL from View, calls PDFParser then repository, updates `@Published` (or Observation) state on main.
- One loading indicator per logical operation; show within 500 ms. Avoid multiple unrelated loading flags on the same screen.

---

## Project Context Reference

- **Brownfield:** Existing SwiftUI app with LibStore, DocumentPicker, PDF parsing. Epic 1 completed Core Data and Store wiring. This story adds the full “pick PDF → parse → persist → show in library” path.
- **Docs:** Architecture and project structure in `_bmad-output/planning-artifacts/architecture.md` and `docs/` as referenced above.

---

## Dev Agent Record

### Agent Model Used

Composer (dev-story workflow)

### Debug Log References

### Completion Notes List

- Wired DocumentPicker completion to LibStore.addDocument(from:). LibraryView passes selected URL to LibStore; drop handler also uses lib.addDocument(from:).
- LibStore.addDocument(from:) runs PDF parsing off main thread via Task.detached; parseAndPersist uses PDFParser.parse, then repository.addDocument with bookmark; state updates on MainActor.
- Removed @MainActor from PDFParser so parse runs off main (NFR-P1).
- Added isAddingDocument and addError to LibStore; loading overlay shows immediately (within 500ms); error alert on add failure.
- Added security-scoped resource access and bookmark persistence for document picker URLs.
- Added testLibStoreAddDocumentFromURL unit test (in-memory repo, real PDFParser, minimal test PDF).
- Code review fixes: distinct parse vs persistence error messages; bookmark failure logged (DEBUG); guard against concurrent add; PDFParser threading documented; error-path and concurrent-add tests added.
- Code review (round 2) fixes: drop failure now sets lib.addError so user sees alert; document picker sheet dismisses when add starts; loading overlay has accessibilityLabel("Parsing PDF"); LibStore.add(rec) sets addError on repository failure. Story file was untracked at review—commit with implementation to clear File List discrepancy.

### File List

- AuditLab/LibStore.swift (modified)
- AuditLab/LibraryView.swift (modified)
- AuditLab/PDFParser.swift (modified)
- AuditLabTests/StoreWiringTests.swift (modified)
- _bmad-output/implementation-artifacts/sprint-status.yaml (modified)
- _bmad-output/implementation-artifacts/2-1-add-pdf-to-library-via-document-picker.md (modified)
