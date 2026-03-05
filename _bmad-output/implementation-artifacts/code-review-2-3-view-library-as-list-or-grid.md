# Code Review: Story 2-3 View Library as List or Grid

**Story:** 2-3-view-library-as-list-or-grid  
**Reviewed:** 2026-03-05  
**Reviewer:** Adversarial code review (workflow)

---

## Git vs Story Discrepancies

**Count:** 5

- **Story Dev Agent Record → File List:** Empty (no files listed).
- **Git reality:** 
  - Modified: `AuditLab/LibraryView.swift`, `AuditLab/LibraryCardView.swift`, `AuditLab/RootView.swift`
  - Untracked (new): `AuditLabTests/LibraryViewStory23IntegrationTests.swift`, `AuditLabUITests/LibraryViewStory23AcceptanceTests.swift`
- **Conclusion:** All changed files are undocumented in the story. No "false claims" (story listing files with no changes); all discrepancies are "files changed but not in story File List" → incomplete documentation.

---

## Issues Summary

| Severity | Count |
|----------|--------|
| HIGH     | 1     |
| MEDIUM   | 3     |
| LOW      | 4     |

---

## HIGH

### 1. Invalid SF Symbol name (LibraryView.swift:149)

- **Location:** `LibraryView.swift` line 149 — `Label("Add PDF", systemImage: "plus.doc")`
- **Evidence:** Runtime log: `[Invalid Configuration] No symbol named 'plus.doc' found in system symbol set`. Apple SF Symbols does not provide `plus.doc`; the system falls back or shows a broken/placeholder icon.
- **Fix:** Use a valid symbol, e.g. `doc.badge.plus` or `plus.circle` or `square.and.arrow.down` (per HIG for "add document" actions).
- **Impact:** Empty-state "Add PDF" button may show wrong/missing icon; inconsistent with NFR-U3 (native platform UI).

---

## MEDIUM

### 2. Story File List empty (Story file – Dev Agent Record)

- **Location:** `_bmad-output/implementation-artifacts/2-3-view-library-as-list-or-grid.md` → Dev Agent Record → File List
- **Evidence:** Section is blank. Git shows 5 files touched by this story (3 modified, 2 new).
- **Fix:** Populate File List with: `AuditLab/LibraryView.swift`, `AuditLab/LibraryCardView.swift`, `AuditLab/RootView.swift`, `AuditLabTests/LibraryViewStory23IntegrationTests.swift`, `AuditLabUITests/LibraryViewStory23AcceptanceTests.swift` (paths relative to repo root).
- **Impact:** Traceability and future reviews cannot verify scope; violates workflow "File List includes every new/modified/deleted file".

### 3. Tasks not marked complete (Story file – Tasks/Subtasks)

- **Location:** Story file – all Task 1, Task 2, Task 3 (and subtasks) are `[ ]`.
- **Evidence:** Implementation satisfies AC1 (list/grid with title, native SwiftUI), AC2 (empty state with message + Add PDF), and verification (identifiers, tests). Code and tests exist and pass.
- **Fix:** Mark Task 1, Task 2, and Task 3 (and their subtasks) as `[x]` and add brief Completion Notes in Dev Agent Record.
- **Impact:** Story progress is misreported; "task marked [x] but not done" audit is reversed here—"tasks done but not marked" undermines definition-of-done and sprint accuracy.

### 4. RootView change out of story scope (RootView.swift)

- **Location:** `AuditLab/RootView.swift` – `-TEST_SEED_LIBRARY` seeding in `onAppear`.
- **Evidence:** Story 2.3 does not mention UI test seeding. Change supports acceptance tests (LibraryViewStory23AcceptanceTests) that depend on seeded library.
- **Fix:** Either (a) add RootView to story File List and note in Completion Notes that change is for Story 2.3 UI test support, or (b) treat as separate test-infrastructure commit and document in story as "supporting change (test only)".
- **Impact:** Without documentation, reviewers cannot tell if RootView is in scope for 2.3 or accidental scope creep.

---

## LOW

### 5. Story Status stale (Story file)

- **Location:** Story Status field: `ready-for-dev`.
- **Evidence:** Implementation and tests are in place; sprint-status had 2-3 as `in-progress`. After code review, status should be `review` (or `done` once issues are resolved).
- **Fix:** Update Status to `review` (or per workflow after fixes to `done`).
- **Impact:** Sprint and story status out of sync; low severity because it’s documentation only.

### 6. Magic numbers (LibraryView, LibraryCardView)

- **Location:** `LibraryView.swift` – `GridItem(.adaptive(minimum: 320), spacing: 18)`, `minHeight: 220`; padding 18, 24, 32.
- **Evidence:** Architecture "Format Patterns" and common practice prefer named constants for layout constants.
- **Fix:** Introduce private constants (e.g. `libraryGridMinColumnWidth`, `libraryCardMinHeight`) or document in comment that values align with HIG list/grid spacing.
- **Impact:** Maintainability and consistency; low.

### 7. Play with missing pack (LibraryView.swift:164–174)

- **Location:** `play(_ r: PaperRec)` – `guard let p = lib.getPack(id: r.id) else { return }`.
- **Evidence:** If pack is not cached (e.g. not yet loaded from disk), user taps Play and nothing happens; no error or loading feedback.
- **Fix:** Consider showing an alert or inline message when `getPack` returns nil (e.g. "Document is still loading" or trigger load and retry). Optional for 2.3; could be follow-up.
- **Impact:** Edge-case UX; low.

### 8. Stale comment in integration tests (LibraryViewStory23IntegrationTests.swift:6)

- **Location:** Header comment: "TDD RED PHASE: Tests are skipped until feature is implemented."
- **Evidence:** Tests are not skipped (no `XCTSkip`); feature is implemented and tests run.
- **Fix:** Update comment to state tests are active and cover AC1/AC2 (list/grid, empty state).
- **Impact:** Documentation only; low.

---

## AC Validation

| AC | Requirement | Verdict | Notes |
|----|-------------|---------|--------|
| AC1 | Documents in list/grid with at least title; native SwiftUI and HIG | **IMPLEMENTED** | LazyVGrid + LibraryCardView with rec.title, authLine, pubLine; accessibility identifiers; system colors/fonts. |
| AC2 | Empty library → explicit empty state (message + optional Add PDF) | **IMPLEMENTED** | libraryEmptyState: semantic background, "No documents yet", "Add PDF" button; identifiers for UI tests. |

---

## Task Audit

- **Task 1 (list/grid + metadata):** Implemented (LibraryView LazyVGrid, LibraryCardView title/metadata); not marked [x].
- **Task 2 (empty state):** Implemented (libraryEmptyState); not marked [x].
- **Task 3 (verification):** Manual + integration/UI tests present; not marked [x].

No task is marked [x]; therefore no "marked complete but not done" critical finding. All tasks are done but unmarked → MEDIUM documentation finding (see #3 above).

---

## Outcome

**Changes Requested:** 1 HIGH, 3 MEDIUM must be addressed (SF Symbol, File List, Tasks marked complete, RootView documented). LOW items recommended but not blocking.

After fixes: re-run review, then set story status to `done` and sync sprint-status if applicable.
