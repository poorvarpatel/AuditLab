# Story 2.3: View Library as List or Grid

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user,
I want to view my library as a list or grid of documents with identifiable metadata (e.g. title),
So that I can find and open documents.

## Acceptance Criteria

1. **Given** the user has one or more documents in the library  
   **When** they open the Library tab  
   **Then** documents are shown in a list or grid with at least title (or equivalent metadata) (FR3)  
   **And** the view uses native SwiftUI components and HIG (NFR-U3)

2. **Given** the library is empty  
   **When** the user opens the Library tab  
   **Then** an explicit empty state is shown (e.g. short message and optional "Add PDF" action) (NFR-U1)

## Tasks / Subtasks

- [ ] **Task 1: Library list/grid with document metadata** (AC: #1)
  - [ ] Ensure Library tab shows documents from LibStore (or persistence) in a list and/or grid layout.
  - [ ] Display at least title (or equivalent metadata) per document; use existing Document/PaperRec or Core Data model attributes.
  - [ ] Use native SwiftUI (List, LazyVGrid, or equivalent) and follow Apple HIG for list/grid patterns.
- [ ] **Task 2: Empty state** (AC: #2)
  - [ ] When library has no documents, show explicit empty state: short message and optional "Add PDF" (or equivalent) action per NFR-U1.
  - [ ] Reuse or align with Architecture/UX: intentional design with semantic background + text (and optional system symbol); no blank screen.
- [ ] **Task 3: Verification** (AC: #1, #2)
  - [ ] Manual: With documents in library, open Library tab → list/grid with titles; with empty library → empty state. Confirm native components and HIG.

## Dev Notes

- **Epic 2: Library & Document Management** — This story delivers the main library view: list or grid of documents with identifiable metadata (FR3) and explicit empty state (NFR-U1). Story 2.1 added documents to the library; 2.2 hardened parse failure and large-file handling. This story does not add document detail (2.4) or remove document (2.5); it only displays the library.
- **Existing pieces:** LibStore holds library state (from persistence); LibraryView and related views already exist. This story focuses on how the library is presented (list/grid + empty state), not on add/remove flows.

### Project Structure Notes

- **Views/Library:** LibraryView (and any LibraryHeaderView, LibraryCardView) are the primary touchpoints. Add or adjust list/grid layout and empty-state view. No business logic in views; bind to LibStore (documents, empty state).
- **Stores/LibStore:** Already provides library data (from persistence). May need a published property or derived state for “isEmpty” if empty state is driven from store.
- **Persistence:** No change required for this story; continue reading documents via existing repository/LibStore.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.3] — FR3, NFR-U1, NFR-U3.
- [Source: _bmad-output/planning-artifacts/architecture.md#Frontend Architecture] — Tab-based root, NavigationStack; structure and data flow.
- [Source: _bmad-output/planning-artifacts/architecture.md#Process Patterns] — Empty and loading states: intentional design with semantic background + text; no blank or generic screens.

---

## Technical Requirements

- **List or grid:** Use native SwiftUI (e.g. `List`, `LazyVGrid`, `LazyVStack`) to show documents. At least title (or equivalent) per document; data from LibStore/persistence.
- **Empty state:** When library has zero documents, show explicit empty state per NFR-U1: short message and optional “Add PDF” action. No blank or unexplained screen.
- **HIG and components:** Use native platform UI elements; adhere to Apple Human Interface Guidelines for list/grid layout, spacing, typography (NFR-U3).

---

## Architecture Compliance

- **Layered architecture:** Views bind to LibStore only; no View → Persistence or View → Service. LibStore already owns library state; view only presents it. [Source: architecture.md#Architectural Boundaries]
- **Empty states:** Intentional design with semantic background + text (and optional system symbol); no blank or generic screens. [Source: architecture.md#Process Patterns, epics Additional Requirements]
- **Structure:** Views under `Views/Library/`; Stores under `Stores/`. One primary type per file; file name = type name. [Source: architecture.md#Structure Patterns]

---

## Library & Framework Requirements

- **SwiftUI:** Use `List`, `LazyVGrid`, `LazyVStack`, or equivalent for list/grid. No custom layout engine required.
- **iOS 26.1+:** Target and APIs as per project. No new frameworks beyond existing SwiftUI and system components.

---

## File Structure Requirements

- **Modified:** `Views/Library/LibraryView.swift` (or equivalent path per project layout) — Implement or adjust list/grid of documents and empty state. Bind to LibStore (documents, isEmpty if needed).
- **Created (if needed):** Empty-state view (e.g. `LibraryEmptyView` or inline in LibraryView) per Architecture empty-state pattern.
- **Unchanged:** LibStore (unless adding isEmpty or similar for empty state), Persistence, PDFParser, DocumentPicker.

---

## Testing Requirements

- **Unit (optional):** If LibStore exposes isEmpty or document count, assert empty vs non-empty state. Alternatively rely on manual verification.
- **Manual (required):** (1) Add one or more documents → open Library tab → confirm list/grid with titles. (2) Remove all documents (or start empty) → confirm explicit empty state with message and optional action. (3) Confirm native SwiftUI and HIG-consistent layout.
- **Regression:** Story 2.1 (add PDF) and 2.2 (parse failure, large file) behavior must remain; no change to add/parse flows.

---

## Previous Story Intelligence

**From Story 2.2 (PDF Parse Failure and Large-File Handling):**

- LibStore has addDocument(from:), isAddingDocument, addError; loading overlay and error alert. Library state comes from persistence (repository). Do not change add or error paths; this story only changes how the library list/grid and empty state are presented.
- DocumentRepository and PersistenceController are in place. Library is fetched via store; views read from store.

**From Story 2.1 (Add PDF to Library via Document Picker):**

- DocumentPicker and LibraryView exist; documents are added via LibStore and persisted. This story uses that same library data for display in list/grid form and adds empty state when count is zero.

**From Epic 1:**

- Core Data and repository provide documents; LibStore exposes them to the UI. View layer must not call persistence directly.

---

## Git Intelligence Summary

- Recent work: Story 2.1 (add PDF via document picker), Epic 1 (Core Data, persistence, migration). Patterns: LibStore + persistence, Task.detached for parsing, Alert for errors, loading state.
- For 2.3: Reuse existing LibStore and Library views; add list/grid layout and empty-state UI only. No new persistence or parsing logic.

---

## Project Context Reference

- **Brownfield:** SwiftUI app with LibStore, DocumentPicker, PDFParser, Core Data persistence. Stories 2.1 and 2.2 complete; this story adds list/grid view and empty state for the Library tab.
- **Docs:** _bmad-output/planning-artifacts/architecture.md (structure, boundaries, empty states); _bmad-output/planning-artifacts/epics.md (Story 2.3, FR3, NFR-U1, NFR-U3).

---

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List
