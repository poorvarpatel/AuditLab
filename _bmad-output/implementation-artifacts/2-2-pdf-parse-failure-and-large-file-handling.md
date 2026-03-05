# Story 2.2: PDF Parse Failure and Large-File Handling

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user,
I want a clear, dismissible message when a PDF can't be added or parsed, and no crash or data loss,
So that I can try another file and trust the app with marginal files.

## Acceptance Criteria

1. **Given** the user selects a corrupted, password-protected, or otherwise unparseable PDF  
   **When** parsing fails  
   **Then** the app shows a clear, dismissible error message (e.g. "Couldn't read this PDF. It may be corrupted or unsupported.") and does not crash (FR6, FR44)  
   **And** existing library, queue, and folder data remain unchanged and usable (FR45)  
   **And** the error is surfaced via ViewModel state and an Alert or banner (Architecture error pattern)

2. **Given** the user selects a large PDF (e.g. 400+ pages)  
   **When** parsing runs  
   **Then** parsing runs asynchronously without freezing the UI (FR48)  
   **And** the app does not crash or block the UI; parsing may be incremental or background (FR47, NFR-P2, NFR-P4)

## Tasks / Subtasks

- [x] **Task 1: Harden parse-failure path and user-facing error** (AC: #1)
  - [x] Ensure PDFParser (or equivalent) throws a distinct error type/code for unparseable PDFs (corrupted, password-protected, unsupported). Do not swallow errors; propagate to LibStore.
  - [x] In LibStore.addDocument(from:), on parse failure: do not call repository.addDocument; do not mutate library state; set a user-facing error message (e.g. addError or alertMessage) with a clear, dismissible message per AC.
  - [x] Ensure the view shows a single dismissible Alert (or banner) with that message. Use Architecture error pattern: ViewModel state → Alert; no crash, no silent swallow.
- [x] **Task 2: Verify existing data unchanged on failure** (AC: #1)
  - [x] On any parse or add failure, guarantee no partial document is persisted and no existing library/queue/folder state is modified. If parsing fails mid-way, do not add to repository; if repository add fails after parse, consider whether to retry or show error without mutating existing data.
  - [x] Add or extend unit test: given parse failure, assert library count unchanged and user-facing error set.
- [x] **Task 3: Large PDF and async / non-blocking behavior** (AC: #2)
  - [x] Confirm PDF parsing is already off the main thread (Story 2.1). If not, move parsing to background (Task.detached or background context) so UI never freezes (FR48).
  - [x] For large PDFs (e.g. 400+ pages): ensure parsing does not load entire document into memory at once if that would cause unbounded growth; use incremental or streaming approach where feasible (NFR-P4). Document any limits or strategies in code comments.
  - [x] Ensure no crash or indefinite hang: add timeouts or chunking if necessary; show loading indicator for long-running parse and clear it on success or failure (NFR-P2, NFR-P3).
- [x] **Task 4: Verification** (AC: #1, #2)
  - [x] Implement or confirm the verification steps in "How to verify this works" below so the feature can be validated manually and, where applicable, by tests.

## How to verify this works

**Manual verification (required):**

1. **Unparseable PDF**
   - Use a corrupted PDF, password-protected PDF, or non-PDF file (if picker allows). Trigger add from Library.
   - **Expect:** A clear, dismissible error message (e.g. "Couldn't read this PDF. It may be corrupted or unsupported."); app does not crash; after dismissing, library/queue/folder are unchanged.
2. **Large PDF**
   - Add a PDF with 400+ pages (or the largest available).
   - **Expect:** Loading indicator appears; UI remains responsive during parsing; no freeze or crash; when complete, document appears in library or a clear error is shown.
3. **Data integrity on failure**
   - With existing documents in library, trigger an add that fails (e.g. bad file).
   - **Expect:** Existing documents still visible and unchanged; no duplicate or partial entries.

**Optional automated verification:**

- **Unit:** Mock PDFParser to throw on parse; call LibStore add; assert library count unchanged, addError (or equivalent) set, no repository add called. Optionally test large-file path with a stub that simulates long-running parse off main thread.

Use these steps to confirm the story is complete and to catch regressions.

## Dev Notes

- **Epic 2: Library & Document Management** — This story focuses on resilience: parse failure UX (clear message, no crash, no data loss) and large-file handling (async, no UI block, bounded memory where feasible).
- **Existing pieces:** Story 2.1 wired DocumentPicker → LibStore.addDocument(from:), PDF parsing off main thread, loading state, and error alert. This story strengthens the error message content, guarantees no state corruption on failure, and ensures large PDFs are handled without blocking or unbounded memory.

### Project Structure Notes

- **Stores/LibStore:** Already has addDocument(from:), isAddingDocument, addError. Extend error handling so parse failures set a single, clear user-facing message and never mutate library/repository.
- **Services/PDFParser:** Must throw on unparseable input; consider distinct error cases (e.g. corrupted vs password-protected) if helpful for messaging. Parsing must remain off main thread; for large files, avoid loading entire PDF into memory at once if it violates NFR-P4.
- **Views/Library:** Alert (or banner) bound to LibStore addError; single dismissible message. No change to persistence or repository from View.

### References

- [Source: _bmad-output/planning-artifacts/architecture.md#Process Patterns] — Error handling: throws at boundary, user-facing message in ViewModel state, Alert/banner; no silent swallows. Loading: one indicator per operation, ~500 ms.
- [Source: _bmad-output/planning-artifacts/architecture.md#Communication Patterns] — Main thread for UI state; parsing off main.
- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.2] — FR6, FR44, FR45, FR47, FR48, NFR-P2, NFR-P4.

---

## Technical Requirements

- **Parse failure:** PDFParser must throw on corrupted, password-protected, or unsupported PDFs. LibStore must catch, set user-facing error (e.g. addError), and not call repository.addDocument or mutate published library state. One clear, dismissible message per Architecture.
- **Data integrity:** On any failure in the add path, existing library, queue, and folder data must remain unchanged. No partial persists; no in-memory state corruption.
- **Async parsing:** Parsing must run off the main thread (already in Story 2.1). For large PDFs, avoid unbounded memory growth; use incremental or chunked parsing where feasible (NFR-P4).
- **Large PDF:** No UI freeze (FR48); no crash or indefinite block (FR47, NFR-P2). Show loading for long operations; clear on success or failure.

---

## Architecture Compliance

- **Layered architecture:** View only shows Alert from LibStore state. LibStore catches PDFParser/repository errors and sets addError; no View → PDFParser or View → Persistence. [Source: architecture.md#Architectural Boundaries]
- **Error handling:** Parsing and persistence can throw; ViewModels catch and set a user-facing message; no silent swallows. Malformed PDF: single dismissible alert; do not crash. [Source: architecture.md#Process Patterns]
- **Loading:** One loading indicator per add operation; show within ~500 ms; clear on success or failure. [Source: architecture.md#Process Patterns]

---

## Library & Framework Requirements

- **PDFKit:** Use existing PDFParser/PDFKit usage. For large PDFs, prefer incremental or page-by-page reading if available to bound memory (NFR-P4); avoid loading entire document into memory when possible.
- **Swift concurrency:** Parsing off main actor; state updates on main. Use Task or background context as in Story 2.1.

---

## File Structure Requirements

- **Modified:** `LibStore.swift` — Ensure parse failure path sets addError, does not call repository or mutate library; optionally refine error message text. Large-file path: ensure parsing stays off main and loading state is cleared on success/failure.
- **Modified (if needed):** `PDFParser.swift` — Ensure it throws on unparseable input; consider incremental/large-file strategy to avoid unbounded memory. Do not move parsing to main thread.
- **Unchanged:** LibraryView — continue to bind Alert to LibStore addError; no new views. Persistence/, DocumentRepository — no changes unless error handling requires a new repository contract.

---

## Testing Requirements

- **Unit:** (1) Parse failure: mock PDFParser to throw; call LibStore add; assert library unchanged, addError set, repository add not called. (2) Optional: large-file path with long-running parse stub; assert UI thread not blocked and loading cleared.
- **Regression:** Story 2.1 behavior (valid PDF add, persistence, loading) must still pass. Existing DocumentRepository and LibStore tests must remain green.

---

## Previous Story Intelligence

**From Story 2.1 (Add PDF to Library via Document Picker):**

- LibStore.addDocument(from:) runs PDF parsing off main thread via Task.detached; on success calls repository.addDocument with bookmark and updates state on MainActor.
- addError and isAddingDocument already exist; loading overlay and error alert are shown. This story refines the error message for parse failure and guarantees no state/repository mutation on failure.
- PDFParser is invoked from LibStore; it must throw on failure so LibStore can catch and set addError without calling repository.
- DocumentPicker and LibraryView already pass URL to LibStore and show loading/alert; ensure alert message is the single, clear string from AC (e.g. "Couldn't read this PDF. It may be corrupted or unsupported.").

**From Epic 1 (Stories 1.1–1.4):**

- DocumentRepository and PersistenceController are in place. Do not call addDocument when parsing fails; existing fetch/add tests must still pass.

---

## Project Context Reference

- **Brownfield:** SwiftUI app with LibStore, DocumentPicker, PDFParser. Story 2.1 completed add flow; this story hardens failure and large-file behavior per FR6, FR44, FR45, FR47, FR48 and NFR-P2, NFR-P4.
- **Docs:** _bmad-output/planning-artifacts/architecture.md (error handling, process patterns, project structure).

---

## Dev Agent Record

### Agent Model Used

Composer (dev-story workflow)

### Debug Log References

### Completion Notes List

- Story 2.2 implementation: Parse-failure path and large-file behavior were already satisfied by Story 2.1 (LibStore addError, single Alert, parse off main, no repository call on parse failure). Verified and documented.
- PDFParser: Added documentation comment for `parse(url:)` — threading (call off main), invalid/corrupted/password-protected (throws invalidPDF), and large PDF strategy (page-by-page processing to bound memory per NFR-P4).
- Added unit test `testLibStoreParseFailureLeavesExistingLibraryUnchanged`: pre-populate one document, trigger addDocument(from: badFile), assert recs.count remains 1 and addError is set (FR45).
- No change to LibStore or LibraryView logic; existing tests (parse failure, persistence failure, concurrent add) already cover AC. File list below reflects only modified files.
- **Code review (2-2):** Fixed CRITICAL: added missing `FailingAfterFirstAddRepository` mock so `testLibStorePersistenceFailureLeavesExistingLibraryUnchanged` compiles and runs. Updated File List to include LibStore.swift (bookmark comment change).

### File List

- AuditLab/LibStore.swift (modified — bookmark-failure comment only)
- AuditLab/PDFParser.swift (modified — documentation only)
- AuditLabTests/StoreWiringTests.swift (modified — new tests + FailingAfterFirstAddRepository mock)
- _bmad-output/implementation-artifacts/2-2-pdf-parse-failure-and-large-file-handling.md (modified)
- _bmad-output/implementation-artifacts/sprint-status.yaml (modified)
