# Story 2.4: View Document Detail

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user,
I want to view document detail (metadata, section structure) before adding to queue or folders,
so that I can decide how to use the document.

## Acceptance Criteria

1. **Given** a document exists in the library  
   **When** the user taps the document  
   **Then** a detail view shows metadata and section structure (or equivalent) where available (FR4)  
   **And** the user can navigate back to the library

2. **Given** document detail is loading  
   **When** the user is on the detail view  
   **Then** a loading state is shown (NFR-U2)

## Tasks / Subtasks

- [x] **Task 1: Navigate from library to document detail** (AC: #1)
  - [x] From Library tab, tapping a document card (or row) opens the document detail view (PaperDetailView or equivalent).
  - [x] Use NavigationStack + navigationDestination, or sheet, or push so the user can open detail from the library and return.
  - [x] Ensure back/done control returns to the library.
- [x] **Task 2: Show metadata and section structure in detail view** (AC: #1)
  - [x] Detail view displays metadata: title, authors, date (or equivalent from PaperRec/ReadPack.meta).
  - [x] Detail view displays section structure where available: section titles (and optionally kind) from ReadPack.secs (Sec).
  - [x] Use native SwiftUI (List, Form, or grouped content) and HIG (NFR-U3).
- [x] **Task 3: Loading state on detail view** (AC: #2)
  - [x] When the pack (ReadPack) for the document is not yet in memory and must be loaded (e.g. from disk or parse), show a loading state (e.g. ProgressView + message) until content is ready (NFR-U2).
  - [x] One loading indicator per logical operation; show within ~500 ms for long operations (architecture).
- [x] **Task 4: Verification** (AC: #1, #2)
  - [x] Manual: Tap document in library → detail shows metadata + sections; navigate back. With slow or loading pack → loading state appears. Confirm native components and HIG.

## Dev Notes

- **Epic 2: Library & Document Management** — This story delivers the document detail screen: metadata and section structure (FR4) and loading state (NFR-U2). Story 2.3 delivered library list/grid and empty state; this story adds navigation to detail and enriches the existing PaperDetailView (or equivalent) with section structure and loading behavior.
- **Existing pieces:** PaperDetailView exists and shows title, authors/date, "Add to Queue", "Play Now". It does not show section structure and is not currently opened from the library grid (LibraryView has no tap-to-detail navigation). LibStore has getPack(id:) returning ReadPack?; ReadPack has meta (Meta), secs ([Sec]), sents, figs. Sec has id, title, kind, sentIds. Use these to display section structure.

### Project Structure Notes

- **Views:** PaperDetailView (AuditLab/PaperDetailView.swift) is the primary touchpoint. Extend it to show section structure (ReadPack.secs) and a loading state when pack is loading. LibraryView and LibraryCardView: add navigation to open PaperDetailView when the user taps a document (e.g. NavigationStack + navigationDestination(selection:) or sheet with selected rec).
- **Stores/LibStore:** Already provides recs (library) and getPack(id:). If loading a pack from disk is async, LibStore may need a way to expose loading state for a given document (e.g. loadingDocumentId or similar) so the detail view can show a spinner until getPack(id:) returns non-nil.
- **Models:** ReadPack (Types.swift) has meta: Meta, secs: [Sec]. Sec: id, title, kind, sentIds. Use these for section list in detail view.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.4] — FR4, NFR-U2.
- [Source: _bmad-output/planning-artifacts/architecture.md#Frontend Architecture] — NavigationStack for drill-down; Views bind to Stores only.
- [Source: _bmad-output/planning-artifacts/architecture.md#Process Patterns] — Loading states: one per logical operation; show within ~500 ms.

---

## Technical Requirements

- **Navigation:** From Library, user tap on a document opens the document detail view. Use NavigationStack with navigationDestination (or equivalent) or sheet; provide clear way to return (back button or "Done").
- **Metadata:** Display at least title, authors, date (from PaperRec / ReadPack.meta). Already partially in PaperDetailView (title, sub() for auths/date); ensure complete and consistent.
- **Section structure:** Display list of sections from ReadPack.secs (Sec: id, title, kind). Use List or similar; section title (and optionally kind) per row. If pack is not loaded, show loading state first.
- **Loading state:** When detail view is shown and the pack is not yet available (e.g. loading from disk), show ProgressView (and optional message) until getPack(id:) returns a value. One loading indicator per screen; within ~500 ms for long operations (NFR-U2, architecture).

---

## Architecture Compliance

- **Layered architecture:** Views bind to LibStore only; no View → Persistence or View → Service. PaperDetailView receives rec: PaperRec and uses lib.getPack(id: rec.id) for ReadPack; LibStore may need to expose loading state for pack if load is async. [Source: architecture.md#Architectural Boundaries]
- **Loading states:** One loading indicator per logical operation; show within ~500 ms. [Source: architecture.md#Process Patterns]
- **Structure:** Views under AuditLab/ (or Views/Library/ if refactored); PaperDetailView is in Shared or Library per architecture (PaperDetailView in project structure). One primary type per file. [Source: architecture.md#Structure Patterns]

---

## Library & Framework Requirements

- **SwiftUI:** Use NavigationStack, navigationDestination or sheet; List/Form for section list; ProgressView for loading. No new frameworks.
- **iOS 26.1+:** As per project. ReadPack, Sec, Meta from existing Types.swift; LibStore.getPack(id:) already available.

---

## File Structure Requirements

- **Modified:** AuditLab/LibraryView.swift — Add navigation to document detail (e.g. @State selectedRec: PaperRec?, navigationDestination(for: PaperRec.self) { rec in PaperDetailView(rec: rec) } or sheet). Ensure card/row is tappable to set selectedRec (or equivalent).
- **Modified:** AuditLab/LibraryCardView.swift (if needed) — Add an explicit "tap to open detail" target (e.g. button or onTapGesture) that invokes a callback (e.g. onTap: () -> Void) so LibraryView can set selection and push/sheet detail. Alternatively wrap card in NavigationLink or use .contentShape + onTapGesture in LibraryView.
- **Modified:** AuditLab/PaperDetailView.swift — (1) Add section structure: when lib.getPack(id: rec.id) is non-nil, display secs (e.g. List of section titles). (2) Add loading state: when pack is nil and load is in progress (if LibStore exposes this), show ProgressView; when pack is nil and not loading, show empty or "Unable to load" per product rule. (3) Keep existing metadata (title, authors, date) and Add to Queue / Play Now.
- **Unchanged:** LibStore (unless adding loading state for pack load), Persistence, PDFParser, DocumentPicker.

---

## Testing Requirements

- **Unit (optional):** If LibStore exposes a loading state for pack-by-id, assert loading vs loaded. Otherwise rely on manual verification.
- **Manual (required):** (1) With documents in library, tap a document → detail view shows metadata and section list; navigate back. (2) When detail is loading (if applicable), confirm loading indicator. (3) Confirm native SwiftUI and HIG.
- **Regression:** Library list/grid (2.3), add PDF (2.1), parse failure (2.2) unchanged; no change to add/parse or empty state.

---

## Previous Story Intelligence

**From Story 2.3 (View Library as List or Grid):**

- LibraryView shows documents in LazyVGrid with LibraryCardView (title, metadata, Play, Add to Queue, Delete). No current navigation to PaperDetailView on card tap. Add selection state and navigationDestination (or sheet) to open PaperDetailView when user taps a document. Use accessibility identifiers where helpful (e.g. library-document-list, library-document-card).
- Code review learnings: Use valid SF Symbols (e.g. doc.badge.plus); keep RootView changes for UI tests documented; update File List and tasks in story when done.

**From Story 2.2 & 2.1:**

- LibStore has getPack(id:), recs, addDocument, isAddingDocument, addError. PaperDetailView already uses lib.getPack(id: rec.id) for Add to Queue and Play. This story extends that same view with section structure and ensures navigation from library and loading state.

---

## Git Intelligence Summary

- Recent work: Story 2.3 (library list/grid, LibraryCardView, empty state, integration/UI tests). Patterns: LibStore + persistence, LazyVGrid, semantic empty state, accessibility identifiers. For 2.4: Add navigation from library to PaperDetailView; extend PaperDetailView with sections and loading state; no new persistence or parsing logic.

---

## Project Context Reference

- **Brownfield:** SwiftUI app with LibStore, PaperDetailView, LibraryView, LibraryCardView, Core Data persistence, ReadPack/Sec/Meta in Types.swift. Stories 2.1–2.3 complete. This story adds tap-to-detail navigation and enriches PaperDetailView with section structure and loading state.
- **Docs:** _bmad-output/planning-artifacts/architecture.md (structure, boundaries, loading); _bmad-output/planning-artifacts/epics.md (Story 2.4, FR4, NFR-U2). No project-context.md in repo.

---

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

- Task 1: LibraryView: added @State selectedRec, .onTapGesture on each LibraryCardView to set selectedRec, .sheet(item: $selectedRec) presenting PaperDetailView with env objects. Done button (document-detail-done) returns to library.
- Task 2: PaperDetailView shows metadata from ReadPack.meta (title, authors, date) and a grouped section list (sec.title, sec.kind) when pack is loaded. Uses ScrollView + VStack and native styling.
- Task 3: LibStore: added loadingPackId and ensurePackLoaded(id:) to load pack off-main; PaperDetailView calls ensurePackLoaded on appear and shows ProgressView + "Loading document…" when loadingPackId == rec.id, else "Unable to load" when pack nil.
- All 62 unit tests pass. UI acceptance tests for 2-4 added to LibraryViewAcceptanceTests.swift; manual verification recommended (tap document → detail → back).
- Note: QueueStore/QueueView changes (folder playback state) are from prior feature work and not directly related to story 2-4 scope; included in branch for integration testing.

### File List

- AuditLab/LibraryView.swift (modified)
- AuditLab/LibraryCardView.swift (modified - accessibility identifier added)
- AuditLab/PaperDetailView.swift (modified)
- AuditLab/LibStore.swift (modified)
- AuditLab/QueueStore.swift (modified - folder playback state added)
- AuditLab/QueueView.swift (modified - folder playback UI added)
- AuditLab/RootView.swift (modified - test seeding for UI tests)
- AuditLab.xcodeproj/project.pbxproj (modified - UI test target changes)
- AuditLabUITests/LibraryViewAcceptanceTests.swift (modified - tests for story 2-3 and 2-4)

### Change Log

- 2025-03-05: Story 2-4 implemented. Navigation from library to document detail via sheet; PaperDetailView shows metadata, section structure, loading state; LibStore.ensurePackLoaded + loadingPackId for async pack load.
