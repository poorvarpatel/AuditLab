# Code Review: Story 2-6 - Empty and Loading States for Library

**Review Date:** March 5, 2026  
**Story File:** 2-6-empty-and-loading-states-for-library.md  
**Story Key:** 2-6-empty-and-loading-states-for-library

---

## Step 1: Load story and discover changes

- **Story path:** `_bmad-output/implementation-artifacts/2-6-empty-and-loading-states-for-library.md`
- **Story key:** 2-6-empty-and-loading-states-for-library
- **Git status:** Uncommitted changes include `AuditLab/LibraryView.swift`, `AuditLab/LibStore.swift`; untracked `AuditLabUITests/LibraryViewAcceptanceTests.swift`, `AuditLabTests/DocumentDeleteCascadeTests.swift`. Other modified app files (LibraryCardView, PaperDetailView, QueueView, RootView, etc.) are from prior stories (2-3, 2-4, 2-5).
- **File List vs git:** Story File List: LibraryView.swift, LibStore.swift, LibraryViewAcceptanceTests.swift, DocumentDeleteCascadeTests.swift. LibraryView and LibStore are modified in git; the two test files are untracked (new). No files in story File List lack git changes for 2-6 scope. PaperDetailView is modified in git but was not changed for 2-6 (story lists it as "Unchanged (reference only)").
- **Inputs loaded:** architecture.md (FULL_LOAD), epics.md (Story 2.6, NFR-U1, NFR-U2). No project-context.md found.

---

## Step 2: Review attack plan

1. **AC validation:** AC1 (empty state), AC2 (loading within 500 ms for add-PDF and load-document).
2. **Task audit:** Every [x] task checked for evidence in code.
3. **Code quality:** Security, performance, error handling, naming, test quality.
4. **Git vs story:** Discrepancies between File List and actual changes.

---

## Step 3: Adversarial review results

### AC validation

| AC | Requirement | Evidence | Verdict |
|----|-------------|----------|---------|
| AC1 | Empty state with short message and optional action (NFR-U1) | LibraryView shows `libraryEmptyState` when `lib.recs.isEmpty`; "No documents yet", "Add a PDF to get started.", Add PDF button; `.secondarySystemGroupedBackground`; identifiers and VoiceOver label. | **IMPLEMENTED** |
| AC2 | Loading/progress within 500 ms for add-PDF and load-document (NFR-U2, NFR-P3) | Add-PDF: `isAddingDocument = true` at start of `addDocument(from:)` (LibStore:76); overlay in LibraryView:107–125. Document detail: `loadingPackId` set synchronously in `ensurePackLoaded` (LibStore:175); PaperDetailView shows `loadingView` when `lib.loadingPackId == rec.id`. | **IMPLEMENTED** |

### Task completion audit

- **Task 1:** Empty state verified (libraryEmptyState, message, button, semantic background, identifiers, VoiceOver label). Done.
- **Task 2:** Overlay when `lib.isAddingDocument`, ProgressView, "Parsing PDF...", single overlay, a11y label and identifier. Done.
- **Task 3:** PaperDetailView loadingView, ProgressView, `document-detail-loading` identifier and label; loading set synchronously. Done.
- **Task 4:** LibStore doc comment documents synchronous initial load; no spinner. Done.
- **Task 5:** Empty-state UI tests exist; document-detail loading test exists; DocumentDeleteCascadeTests fixed. Optional loading-overlay test not added.

### Git vs story discrepancies

- **Count:** 0 critical. Story File List matches 2-6 scope. Other modified files (PaperDetailView, etc.) are from other stories and correctly not claimed as 2-6 changes.

---

## Step 4: Findings (3–10 issues)

### MEDIUM

**M1 – File List includes non–2.6 test file**  
- **Where:** Story File List lists `AuditLabTests/DocumentDeleteCascadeTests.swift` (modified: fix nil doc.identity unwrap).  
- **Issue:** That test file belongs to Story 2.5 (cascade delete). The change unblocks the suite but does not implement or verify any 2.6 requirement. Listing it under 2.6 blurs story boundaries and makes 2.6 appear to own maintenance of 2.5 tests.  
- **Suggestion:** Either remove from 2.6 File List and note in Completion Notes only, or add a clear note: "Test file from Story 2.5; fixed here to allow suite to pass."

**M2 – Weak assertion in document-detail loading test**  
- **Where:** `AuditLabUITests/LibraryViewAcceptanceTests.swift` – `testDocumentDetailShowsLoadingState()` (lines 272–288).  
- **Issue:** The test passes if **either** loading state appears **or** content appears: `XCTAssertTrue(loadingAppeared || contentAppeared, ...)`. When the pack is already cached or loads very quickly, the test never asserts that the loading UI exists. So we do not positively verify that the loading state is shown when the pack is not cached.  
- **Suggestion:** Prefer a test that forces uncached load (e.g. new app launch, first open of detail) and asserts that the loading view or "Loading document…" text appears at least briefly; or document that the test is intentionally lenient and manual verification covers the loading state.

### LOW

**L1 – Optional UI test for add-PDF loading overlay not implemented**  
- **Where:** Task 5: "Optional: UI test for empty state visibility and Add PDF button; optional test for loading overlay presence during add."  
- **Issue:** Empty state and Add PDF are covered. No test asserts that the add-PDF loading overlay (`library-add-pdf-loading`) appears during add. The constant `A11y.addPdfLoading` was added but is never used in any assertion.  
- **Suggestion:** Add an optional UI test that taps Add PDF and asserts `app.otherElements[A11y.addPdfLoading].waitForExistence(timeout: 1)` (or similar) before the sheet/picker blocks; or document that this is left for manual verification.

**L2 – No test verifies 500 ms timing**  
- **Where:** NFR-P3 / AC2 require loading indicator within 500 ms.  
- **Issue:** Implementation sets `isAddingDocument` and `loadingPackId` synchronously, so loading appears immediately in practice. There is no unit or UI test that measures or asserts the 500 ms bound.  
- **Suggestion:** Low risk given synchronous state updates; optional: add a short comment in code or tests that 500 ms is satisfied by design (state set before async work).

**L3 – addPdfLoading constant unused in assertions**  
- **Where:** `LibraryViewAcceptanceTests.swift` – `A11y.addPdfLoading = "library-add-pdf-loading"` (line 22).  
- **Issue:** The constant is defined but no test uses it in a `waitForExistence` or similar assertion.  
- **Suggestion:** Use it in an optional loading-overlay test, or remove the constant if no test will use it (identifier remains on the view for accessibility).

**L4 – No record that manual verification was performed**  
- **Where:** Task 5 checkboxes for manual verification are marked [x].  
- **Issue:** There is no note, date, or artifact (e.g. in Dev Agent Record) that the three manual checks (empty library, add PDF → loading → list, document detail → loading → content) were actually run.  
- **Suggestion:** Add a one-line note in Completion Notes: "Manual verification performed: empty state, add-PDF overlay, document-detail loading (date/session)."

---

## Summary

| Severity | Count |
|----------|--------|
| CRITICAL | 0 |
| HIGH     | 0 |
| MEDIUM   | 2 (M1, M2) |
| LOW      | 4 (L1–L4) |

**Story claims:** All ACs and tasks are implemented. No task is marked [x] without supporting code.  
**Remaining issues:** 2 MEDIUM (documentation/scope, test strength), 4 LOW (optional test, 500 ms, unused constant, manual verification record).

---

## Step 5: Status and next steps

- **Recommendation:** Address M1 (File List / Completion Notes) and M2 (test or documentation) for a clean review.  
- **If all HIGH and MEDIUM are fixed:** Story status → **done**, sprint status → **done**.  
- **If HIGH or MEDIUM remain:** Story status → **in-progress**, sprint status → **in-progress**.

---

## Outcome: Action items created

**User choice:** [2] Create action items.

- **Review Follow-ups (AI)** subsection added to story Tasks/Subtasks with 6 items (2 Medium, 4 Low).
- **Story status:** in-progress.
- **Sprint status:** 2-6-empty-and-loading-states-for-library → in-progress.
- **Action items created:** 6.
