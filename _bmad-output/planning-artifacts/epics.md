---
stepsCompleted: ['step-01-validate-prerequisites', 'step-01-extraction-confirmed', 'step-02-design-epics', 'step-03-create-stories', 'step-04-final-validation']
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/planning-artifacts/architecture.md
  - _bmad-output/planning-artifacts/ux-design-specification.md
---

# AuditLab - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for AuditLab, decomposing the requirements from the PRD, UX Design if it exists, and Architecture requirements into implementable stories.

## Requirements Inventory

### Functional Requirements

FR1: User can add a PDF to the library from a document picker or file source.
FR2: User can remove a document from the library.
FR3: User can view the library as a list or grid of documents with identifiable metadata (e.g. title).
FR4: User can view document detail (e.g. metadata, section structure) before adding to queue or folders.
FR5: System persists the library across app restarts and device reboot.
FR6: User receives clear, dismissible feedback when a PDF cannot be added or parsed (e.g. corrupted or unsupported), and existing data is unchanged.
FR50: When a document is deleted, it is removed from all folders, queue entries, and future playback; historical records remain but are clearly marked as unavailable.
FR7: User can create a folder and give it a name.
FR8: User can rename a folder.
FR9: User can delete a folder (with defined behavior for documents that were only in that folder).
FR10: User can add a document to a folder; the same document can be in multiple folders.
FR11: User can remove a document from a folder without removing it from the library or other folders.
FR12: User can view the set of documents in a folder.
FR13: User can view which folders contain a given document.
FR14: System persists folders and document–folder relationships across app restarts.
FR46: System enforces uniqueness of document–folder relationships (no duplicate document-in-folder) and maintains referential integrity when documents or folders are deleted.
FR15: User can add a document to the playback queue (with optional section/scope configuration where supported).
FR16: User can add a folder to the queue; system snapshots its current documents into the queue as discrete items (deterministic at add time; not a live reference).
FR17: User can remove an item from the queue.
FR18: User can reorder items in the queue.
FR19: User can view the current queue (order and items).
FR20: System persists the queue across app restarts.
FR21: User can start playback of a document (from library, queue, or history).
FR22: User can pause and resume playback.
FR23: User can select a system voice for playback.
FR24: System applies user's selected voice to playback.
FR25: User can adjust speech rate (and pitch if in scope) for playback.
FR26: User can see transcript and figure context during playback (sentence/position and figures where available).
FR27: User can resume playback from a stored last position (e.g. from History or document detail).
FR28: System stores and restores playback position at sentence-level granularity (or equivalent).
FR51: If the app terminates during playback, state is restored on next launch.
FR29: User can view listening history (past sessions per document).
FR30: User can search history by document name.
FR31: User can filter history by date range and by folder.
FR32: System displays history entries with at least timestamp, last listened position, and duration (or equivalent).
FR33: User can open a history entry to view details and, where supported, resume playback from that position.
FR34: System persists the selected voice across sessions.
FR35: System persists speech rate (and pitch if in scope) across sessions.
FR36: User can choose appearance (system, light, or dark); choice is persisted.
FR37: User can clear history (with explicit confirmation).
FR38: User can see the app version (e.g. in Settings or about).
FR39: All interactive elements have accessibility labels so VoiceOver can announce them correctly.
FR40: Focus order follows visual reading order (or is validated against platform accessibility focus-order guidelines) for VoiceOver and keyboard-style navigation.
FR41: Important state changes (e.g. "Added to queue", "Added to folder") are announced to the user (e.g. via VoiceOver or equivalent).
FR42: Layout and text scale support Dynamic Type without breaking layout or obscuring content.
FR43: Tap targets meet minimum size and spacing for accessibility (e.g. 44pt minimum per platform guidelines).
FR49: App is verified to be fully navigable using VoiceOver without requiring sighted interaction.
FR44: When PDF parsing fails, the user sees a clear error message and the app does not crash.
FR45: When PDF parsing or add fails, existing library, queue, and folder data remain unchanged and usable.
FR47: System handles large PDFs (e.g. up to 400+ pages) without UI blocking or crashes.
FR48: PDF parsing occurs asynchronously without freezing the UI.

### NonFunctional Requirements

NFR-P1: PDF parsing runs off the main thread so the UI remains responsive; no freezing or indefinite "loading" for documents up to 100 pages.
NFR-P2: Large PDFs (e.g. 400+ pages) are handled without crashing or blocking the UI; parsing may be incremental or background where appropriate.
NFR-P3: User actions receive immediate visual acknowledgment (e.g. button press state) within 100 ms where applicable; longer operations display loading or progress indicators within 500 ms.
NFR-P4: Memory usage during parsing of large PDFs is bounded and does not grow unbounded with document size; parsing is performed incrementally where feasible.
NFR-P5: When the app enters background, playback either pauses or continues in accordance with system audio policies (e.g. background audio capability); behavior is explicit and consistent.
NFR-P6: History queries (search, filter) remain responsive under long-term usage (e.g. 10,000+ history entries).
NFR-R1: Persisted data (library, folders, queue, history, settings, playback position) survives app restart and normal device use without loss or corruption.
NFR-R2: If the app terminates abnormally during playback or during a write, on next launch the app recovers to a consistent state (e.g. last committed state) and does not leave orphaned or partially written data.
NFR-R3: Persistence schema changes support lightweight migration without user data loss.
NFR-R4: The app must not crash under normal supported usage scenarios.
NFR-A1: All primary user flows (add document, manage folders, manage queue, play, History, Settings) are fully navigable and usable with VoiceOver only, without sighted assistance.
NFR-A2: Layout and typography support Dynamic Type up to the largest accessibility sizes without clipping, overlap, or loss of functionality.
NFR-A3: Interactive elements have sufficient tap target size and spacing to meet platform accessibility guidelines (e.g. 44pt minimum where applicable).
NFR-A4: The app respects system accessibility settings (e.g. Reduce Motion, Bold Text, Increased Contrast) where applicable.
NFR-S1: All user data (documents, metadata, history, settings) remains on device unless the user explicitly exports or shares; no data is transmitted to external servers by default.
NFR-S2: No user data is collected for analytics or third-party purposes; the app does not require network access for core functionality.
NFR-S3: Imported documents are stored within the app sandbox and are not accessible to other apps.
NFR-U1: Empty states (no documents, empty queue, empty folder, no history) are explicitly designed and communicated (e.g. short message and optional action), not blank or generic.
NFR-U2: Loading and progress states are shown for operations that can take noticeable time (e.g. adding/parsing a PDF, loading a document).
NFR-U3: UI components use native platform UI elements and adhere to Apple Human Interface Guidelines for layout, spacing, typography, and navigation patterns.

### Additional Requirements

- **Starter / Epic 1 Story 1:** Project is brownfield; no CLI starter. First implementation story is: add Core Data model (Document, Folder, HistoryItem; many-to-many Document–Folder) and persistence layer (stack + repository interface); implement migration from current in-memory/UserDefaults state.
- Core Data as single persistence store; main context for UI, background context for import/parsing where appropriate.
- Lightweight migration from current state; no existing Core Data store; seed or migrate from in-memory/UserDefaults in a one-time migration step.
- Parsed content (ReadPack) in-memory/cache keyed by document ID; not stored in Core Data for MVP; optional TranscriptChunk post-MVP if needed for resume/search.
- Layered architecture: Views, Stores (ViewModels), Persistence, Services (PDFParser, SpchPlayer); no business logic in views; no direct View → Persistence or View → Service.
- Naming: Core Data entities PascalCase singular; attributes camelCase; Swift one primary type per file, file name = type name.
- Error handling: throws/Result at boundary; user-facing message in ViewModel state (e.g. alertMessage); Alert or banner in view; no silent swallows; malformed PDF shows single dismissible alert.
- Loading: one loading indicator per logical operation; show within ~500 ms for long operations.
- Project structure: layer-based under AuditLab/ (Models, Views, Stores, Persistence, Services, Assets.xcassets); tests in AuditLabTests/ mirroring layers.
- Responsive: SwiftUI and system layout; iOS size classes (compact/regular); design for compact width first; no pixel breakpoints.
- Accessibility (UX): WCAG 2.1 AA; VoiceOver labels and hints on all interactive elements; logical focus order; state changes announced; Dynamic Type to largest sizes without clipping; ~44pt tap targets; semantic Success/Warning/Destructive for feedback colors.
- Single visual style; no user theme or accent options; system appearance (dark mode); no Appearance or Accent controls in Settings.
- Empty and loading states: intentional design with semantic background + text (and optional system symbol); no blank or generic screens.
- Error UX: clear message + next step; announce for VoiceOver; use semantic Error/Warning.
- Components: prefer system (TabView, List, Form, Button, Alert, Picker, etc.); custom only for transcript+current sentence highlight, figure panel, reorderable queue list, empty/loading state views.

### FR Coverage Map

FR1: Epic 2 - Add PDF to library
FR2: Epic 2 - Remove document from library
FR3: Epic 2 - View library list/grid
FR4: Epic 2 - View document detail
FR5: Epic 2 - Library persists (infrastructure from Epic 1)
FR6: Epic 2 - Clear feedback when PDF add/parse fails
FR7: Epic 3 - Create folder with name
FR8: Epic 3 - Rename folder
FR9: Epic 3 - Delete folder
FR10: Epic 3 - Add document to folder (many-to-many)
FR11: Epic 3 - Remove document from folder
FR12: Epic 3 - View documents in folder
FR13: Epic 3 - View folders containing a document
FR14: Epic 3 - Folders and document–folder persist (infrastructure from Epic 1)
FR15: Epic 4 - Add document to queue
FR16: Epic 4 - Add folder to queue (snapshot)
FR17: Epic 4 - Remove item from queue
FR18: Epic 4 - Reorder queue
FR19: Epic 4 - View queue
FR20: Epic 4 - Queue persists (infrastructure from Epic 1)
FR21: Epic 5 - Start playback
FR22: Epic 5 - Pause and resume playback
FR23: Epic 5 - Select system voice
FR24: Epic 5 - Selected voice applied to playback
FR25: Epic 5 - Adjust speech rate (and pitch if in scope)
FR26: Epic 5 - Transcript and figure context during playback
FR27: Epic 5 - Resume from stored position
FR28: Epic 5 - Store/restore position at sentence level
FR29: Epic 6 - View listening history
FR30: Epic 6 - Search history by document name
FR31: Epic 6 - Filter history by date and folder
FR32: Epic 6 - History shows timestamp, position, duration
FR33: Epic 6 - Open history entry and resume
FR34: Epic 7 - Persist selected voice (infrastructure from Epic 1)
FR35: Epic 7 - Persist speech rate/pitch (infrastructure from Epic 1)
FR36: Epic 7 - Choose and persist appearance
FR37: Epic 7 - Clear history with confirmation
FR38: Epic 7 - Show app version
FR39: Epic 8 - Accessibility labels on interactive elements
FR40: Epic 8 - Focus order for VoiceOver
FR41: Epic 8 - State-change announcements
FR42: Epic 8 - Dynamic Type support
FR43: Epic 8 - Tap target size and spacing
FR44: Epic 2 - Clear error message when parsing fails, no crash
FR45: Epic 2 - Existing data unchanged on parse/add failure
FR46: Epic 3 - Uniqueness and referential integrity (doc–folder)
FR47: Epic 2 - Large PDFs without UI block or crash
FR48: Epic 2 - PDF parsing async (no UI freeze)
FR49: Epic 8 - Full VoiceOver navigability
FR50: Epic 2 - Document delete cascades (folders, queue)
FR51: Epic 5 - Restore playback state after app termination

## Epic List

### Epic 1: Persistent Data Foundation
Users' library, folders, queue, history, and preferences can survive app restart. Core Data model (Document, Folder, HistoryItem; many-to-many Document–Folder), persistence layer (stack + repository), and one-time migration from current in-memory/UserDefaults state.
**FRs enabled (implemented in later epics):** FR5, FR14, FR20, FR34, FR35, FR36.

### Epic 2: Library & Document Management
Users can build and manage a paper library: add PDFs, view list/grid and document detail, remove documents, and get clear feedback when a PDF can't be added or parsed.
**FRs covered:** FR1, FR2, FR3, FR4, FR5, FR6, FR44, FR45, FR47, FR48, FR50.

### Epic 3: Folders & Organization
Users can organize papers in named folders with one document in multiple folders; folder membership persists.
**FRs covered:** FR7, FR8, FR9, FR10, FR11, FR12, FR13, FR14, FR46.

### Epic 4: Playback Queue
Users can build and manage a playback queue (add document or folder snapshot, reorder, remove, view); queue persists.
**FRs covered:** FR15, FR16, FR17, FR18, FR19, FR20.

### Epic 5: Playback & Speech
Users can play, pause, and resume; choose and persist a system voice; adjust rate (and pitch if in scope); see transcript and figures; store and restore playback position; recover state after app termination.
**FRs covered:** FR21, FR22, FR23, FR24, FR25, FR26, FR27, FR28, FR51.

### Epic 6: History & Resume
Users can view listening history, search by document name, filter by date and folder, see timestamp/position/duration, and resume from an entry.
**FRs covered:** FR29, FR30, FR31, FR32, FR33.

### Epic 7: Settings & Preferences
Users can set and persist voice, speech rate (and pitch if in scope), appearance (system/light/dark), clear history with confirmation, and see app version.
**FRs covered:** FR34, FR35, FR36, FR37, FR38.

### Epic 8: Accessibility
All primary flows are usable with VoiceOver only; labels, focus order, and state announcements are correct; layout supports Dynamic Type and tap targets meet guidelines.
**FRs covered:** FR39, FR40, FR41, FR42, FR43, FR49.

---

## Epic 1: Persistent Data Foundation

Users' library, folders, queue, history, and preferences can survive app restart. Core Data model (Document, Folder, HistoryItem; many-to-many Document–Folder), persistence layer (stack + repository), and one-time migration from current in-memory/UserDefaults state.

### Story 1.1: Core Data Model and Persistence Stack

As a developer,
I want a Core Data model and persistence stack with Document, Folder, and HistoryItem entities and a repository interface for documents and folders,
So that the app can store and retrieve library and folder data.

**Acceptance Criteria:**

**Given** the app target has no Core Data model yet  
**When** the story is implemented  
**Then** an `.xcdatamodeld` exists with entities: Document (attributes sufficient for identity, title, addedAt, file reference), Folder (identity, name, createdAt), HistoryItem (playedAt, lastSentenceId or equivalent, durationSeconds, relationship to Document)  
**And** Document and Folder have a many-to-many relationship (no duplicate document-in-folder; referential integrity on delete)  
**And** a PersistenceController (or equivalent) provides a Core Data stack with main context for UI and optional background context for bulk work  
**And** a repository type exposes at least: addDocument, fetchDocuments, deleteDocument, addFolder, fetchFolders, deleteFolder, addDocumentToFolder, removeDocumentFromFolder, fetchDocumentsInFolder, fetchFoldersForDocument  
**And** entity and attribute naming follows Architecture (PascalCase entities, camelCase attributes)

**Given** the repository is called with valid data  
**When** addDocument or addFolder is invoked and save is performed  
**Then** data is persisted and fetch methods return the saved data after app restart (NFR-R1)

### Story 1.2: Queue and App Settings Persistence

As a user,
I want the playback queue and my app settings (voice, speech rate, appearance) to be stored by the persistence layer,
So that the queue and preferences survive app restart.

**Acceptance Criteria:**

**Given** the Core Data model and repository from Story 1.1  
**When** the story is implemented  
**Then** the model or repository supports persisting an ordered queue (ordered list of document references or queue entries)  
**And** the model or repository (or agreed UserDefaults boundary) supports persisting: selected voice identifier, speech rate, appearance (system/light/dark)  
**And** repository (or equivalent) methods exist to save and load queue order and settings  
**And** after app restart, loaded queue order and settings match the last saved state (FR34, FR35, FR36 infrastructure; NFR-R1)

**Given** the user has set a voice and added items to the queue  
**When** the app is terminated and relaunched  
**Then** the queue content and order and the selected voice (and rate, appearance) are restored

### Story 1.3: HistoryItem Persistence

As a user,
I want my listening sessions to be stored (document, timestamp, position, duration),
So that history can be displayed and used for resume later.

**Acceptance Criteria:**

**Given** the Core Data model from Story 1.1  
**When** the story is implemented  
**Then** HistoryItem entity exists (or is extended) with: playedAt, lastSentenceId or equivalent position, durationSeconds, and relationship to Document  
**And** the repository exposes methods to: save a history entry (after playback or pause), fetch history entries (optionally by document, date range, or folder)  
**And** saved history entries persist across app restart and are returned by fetch methods (NFR-R1)

**Given** the user has played part of a document  
**When** a history entry is saved  
**Then** the entry includes document reference, timestamp, last position (sentence-level or equivalent), and duration (or equivalent)

### Story 1.4: Migration from Current State to Core Data

As a user,
I want any existing library, folder, or queue data (in-memory or UserDefaults) to be migrated into Core Data once,
So that I don’t lose my data when the app switches to Core Data.

**Acceptance Criteria:**

**Given** the app currently uses in-memory and/or UserDefaults for library, folders, or queue  
**When** the story is implemented  
**Then** a one-time migration runs (e.g. on first launch after upgrade) that reads existing library, folders, and queue from current sources  
**And** that data is written into Core Data via the repository (Story 1.1, 1.2)  
**And** after migration, the app uses only Core Data (and agreed UserDefaults for trivial prefs if any) as the source of truth for library, folders, queue  
**And** migration is idempotent or guarded so it does not run again and corrupt data (NFR-R2, NFR-R3)

**Given** the user had documents in the library or items in the queue before the update  
**When** they open the app after the update  
**Then** those documents and queue items appear in the app and persist across subsequent restarts

---

## Epic 2: Library & Document Management

Users can build and manage a paper library: add PDFs, view list/grid and document detail, remove documents, and get clear feedback when a PDF can't be added or parsed.

### Story 2.1: Add PDF to Library via Document Picker

As a user,
I want to add a PDF to my library from the document picker,
So that I can later organize, queue, and listen to it.

**Acceptance Criteria:**

**Given** the persistence layer from Epic 1 is available  
**When** the user taps Add and selects a valid PDF from the document picker  
**Then** the app invokes the PDF parsing service (off main thread per NFR-P1) and, on success, persists the document via the repository  
**And** the new document appears in the library list and persists across restart (FR1, FR5)  
**And** a loading or progress indicator is shown within 500 ms for the add operation (NFR-P3, NFR-U2)

**Given** the user selects a file  
**When** parsing completes successfully  
**Then** the document is stored with identifiable metadata (e.g. title) for display in the library (FR3)

### Story 2.2: PDF Parse Failure and Large-File Handling

As a user,
I want a clear, dismissible message when a PDF can't be added or parsed, and no crash or data loss,
So that I can try another file and trust the app with marginal files.

**Acceptance Criteria:**

**Given** the user selects a corrupted, password-protected, or otherwise unparseable PDF  
**When** parsing fails  
**Then** the app shows a clear, dismissible error message (e.g. "Couldn't read this PDF. It may be corrupted or unsupported.") and does not crash (FR6, FR44)  
**And** existing library, queue, and folder data remain unchanged and usable (FR45)  
**And** the error is surfaced via ViewModel state and an Alert or banner (Architecture error pattern)

**Given** the user selects a large PDF (e.g. 400+ pages)  
**When** parsing runs  
**Then** parsing runs asynchronously without freezing the UI (FR48)  
**And** the app does not crash or block the UI; parsing may be incremental or background (FR47, NFR-P2, NFR-P4)

### Story 2.3: View Library as List or Grid

As a user,
I want to view my library as a list or grid of documents with identifiable metadata (e.g. title),
So that I can find and open documents.

**Acceptance Criteria:**

**Given** the user has one or more documents in the library  
**When** they open the Library tab  
**Then** documents are shown in a list or grid with at least title (or equivalent metadata) (FR3)  
**And** the view uses native SwiftUI components and HIG (NFR-U3)

**Given** the library is empty  
**When** the user opens the Library tab  
**Then** an explicit empty state is shown (e.g. short message and optional "Add PDF" action) (NFR-U1)

### Story 2.4: View Document Detail

As a user,
I want to view document detail (metadata, section structure) before adding to queue or folders,
So that I can decide how to use the document.

**Acceptance Criteria:**

**Given** a document exists in the library  
**When** the user taps the document  
**Then** a detail view shows metadata and section structure (or equivalent) where available (FR4)  
**And** the user can navigate back to the library

**Given** document detail is loading  
**When** the user is on the detail view  
**Then** a loading state is shown (NFR-U2)

### Story 2.5: Remove Document from Library (with Cascade)

As a user,
I want to remove a document from the library,
So that I can keep my library tidy.

**Acceptance Criteria:**

**Given** a document is in the library and possibly in folders and/or the queue  
**When** the user removes the document from the library  
**Then** the document is removed from the library and from all folders and queue entries (FR2, FR50)  
**And** historical records (HistoryItem) that reference the document remain but are clearly marked as unavailable or handled per product rule  
**And** the persistence layer maintains referential integrity (no orphaned folder or queue references)

### Story 2.6: Empty and Loading States for Library

As a user,
I want clear empty and loading states when the library has no documents or when operations are in progress,
So that I never see a blank or unexplained screen.

**Acceptance Criteria:**

**Given** the library is empty  
**When** the user views the library  
**Then** an explicit empty state is shown with a short message and optional action (NFR-U1)

**Given** an add-PDF or load-document operation is in progress  
**When** the operation can take noticeable time  
**Then** a loading or progress indicator is shown within 500 ms (NFR-U2, NFR-P3)

---

## Epic 3: Folders & Organization

Users can organize papers in named folders with one document in multiple folders; folder membership persists.

### Story 3.1: Create and Name Folder

As a user,
I want to create a folder and give it a name,
So that I can group documents.

**Acceptance Criteria:**

**Given** the user is on the Library or folder management screen  
**When** they create a new folder and enter a name  
**Then** a folder is created with that name and persisted via the repository (FR7, FR14)  
**And** the folder appears in the folder list and survives app restart

### Story 3.2: Rename Folder

As a user,
I want to rename a folder,
So that I can keep folder names meaningful.

**Acceptance Criteria:**

**Given** a folder exists  
**When** the user renames it (e.g. via edit or long-press)  
**Then** the folder's name is updated and persisted (FR8, FR14)

### Story 3.3: Delete Folder

As a user,
I want to delete a folder,
So that I can remove groups I no longer need.

**Acceptance Criteria:**

**Given** a folder exists and may contain document references  
**When** the user deletes the folder  
**Then** the folder is removed and document–folder relationships for that folder are removed; documents remain in the library and in other folders (FR9, FR46)  
**And** behavior for "documents that were only in that folder" is defined and implemented (e.g. document stays in library only)

### Story 3.4: Add Document to Folder (Many-to-Many)

As a user,
I want to add a document to a folder (and the same document can be in multiple folders),
So that I can organize papers in multiple groups.

**Acceptance Criteria:**

**Given** a document is in the library and one or more folders exist  
**When** the user adds the document to a folder  
**Then** the document appears in that folder's document list and the relationship is persisted (FR10, FR14)  
**And** the same document can be added to multiple folders without duplication (many-to-many; FR46)  
**And** duplicate document-in-folder is not created (uniqueness enforced)

**Given** the user adds a document to a folder  
**When** the action completes  
**Then** clear feedback is given (e.g. "Added to folder" or equivalent) for accessibility (FR41)

### Story 3.5: Remove Document from Folder

As a user,
I want to remove a document from a folder without removing it from the library or other folders,
So that I can adjust folder membership without losing the document elsewhere.

**Acceptance Criteria:**

**Given** a document is in one or more folders  
**When** the user removes it from a specific folder  
**Then** the document is removed from that folder only; it remains in the library and in any other folders (FR11, FR14)

### Story 3.6: View Documents in Folder

As a user,
I want to view the set of documents in a folder,
So that I can see what I've grouped.

**Acceptance Criteria:**

**Given** a folder exists and has zero or more documents  
**When** the user opens the folder  
**Then** the list of documents in that folder is displayed (FR12)  
**And** if the folder is empty, an explicit empty state is shown (NFR-U1)

### Story 3.7: View Folders Containing a Document

As a user,
I want to see which folders contain a given document,
So that I understand where the document lives.

**Acceptance Criteria:**

**Given** a document is in one or more folders  
**When** the user views the document (e.g. in detail or in library)  
**Then** the user can see which folders contain that document (FR13)

---

## Epic 4: Playback Queue

Users can build and manage a playback queue (add document or folder snapshot, reorder, remove, view); queue persists.

### Story 4.1: Add Document to Queue

As a user,
I want to add a document to the playback queue,
So that I can listen to it in order.

**Acceptance Criteria:**

**Given** a document is in the library (or folder)  
**When** the user adds it to the queue  
**Then** the document is appended to the queue and the queue is persisted (FR15, FR20)  
**And** the user receives clear feedback (e.g. "Added to queue") (FR41)

### Story 4.2: Add Folder to Queue (Snapshot)

As a user,
I want to add a folder to the queue so that all its current documents are added as discrete items,
So that I can queue a whole group at once.

**Acceptance Criteria:**

**Given** a folder exists with one or more documents  
**When** the user adds the folder to the queue  
**Then** the system snapshots the folder's current documents and appends them to the queue as discrete items (not a live reference) (FR16)  
**And** the snapshot is deterministic at add time (order and membership fixed when added)  
**And** the queue is persisted (FR20)

### Story 4.3: View Current Queue

As a user,
I want to view the current queue (order and items),
So that I know what will play next.

**Acceptance Criteria:**

**Given** the user has zero or more items in the queue  
**When** they open the Queue tab  
**Then** the current queue order and items are displayed (FR19)  
**And** if the queue is empty, an explicit empty state is shown (NFR-U1)

### Story 4.4: Remove Item from Queue

As a user,
I want to remove an item from the queue,
So that I can change what will play.

**Acceptance Criteria:**

**Given** the queue has one or more items  
**When** the user removes an item  
**Then** that item is removed from the queue and the updated queue is persisted (FR17, FR20)

### Story 4.5: Reorder Queue

As a user,
I want to reorder items in the queue,
So that I can control playback order.

**Acceptance Criteria:**

**Given** the queue has two or more items  
**When** the user reorders (e.g. drag or move controls)  
**Then** the new order is reflected and persisted (FR18, FR20)  
**And** reorder uses standard list reorder patterns and is accessible (VoiceOver labels)

---

## Epic 5: Playback & Speech

Users can play, pause, and resume; choose and persist a system voice; adjust rate (and pitch if in scope); see transcript and figures; store and restore playback position; recover state after app termination.

### Story 5.1: Start Playback from Library, Queue, or History

As a user,
I want to start playback of a document from the library, queue, or history,
So that I can listen to the content.

**Acceptance Criteria:**

**Given** a document is available (in library, queue, or history)  
**When** the user taps play (or "Play from here")  
**Then** playback starts using the document's parsed content (FR21)  
**And** the selected system voice (from settings) is applied (FR24)  
**And** playback state is visible and can be paused (Story 5.2)

### Story 5.2: Pause and Resume Playback

As a user,
I want to pause and resume playback,
So that I can control listening.

**Acceptance Criteria:**

**Given** playback is in progress  
**When** the user taps pause  
**Then** playback pauses and the current position is retained (FR22)  
**When** the user taps resume  
**Then** playback continues from the same position (FR22)

**Given** the app enters background during playback  
**When** system audio policy is applied  
**Then** playback either pauses or continues in accordance with background audio capability; behavior is explicit and consistent (NFR-P5)

### Story 5.3: Select and Apply System Voice

As a user,
I want to select a system voice for playback and have it persist and apply,
So that I hear the voice I prefer.

**Acceptance Criteria:**

**Given** the app lists available system voices (e.g. from AVSpeechSynthesisVoice)  
**When** the user selects a voice (e.g. in Settings)  
**Then** the selection is persisted and applied to subsequent playback (FR23, FR24, FR34)  
**And** the selected voice is used for current and future playback until changed

### Story 5.4: Adjust Speech Rate (and Pitch if in Scope)

As a user,
I want to adjust speech rate (and pitch if in scope) for playback,
So that I can listen at a comfortable pace.

**Acceptance Criteria:**

**Given** the user can access speech settings  
**When** they adjust the speech rate (e.g. slider)  
**Then** the rate is applied to playback and persisted (FR25, FR35)  
**And** if pitch is in scope, the same applies for pitch

### Story 5.5: Transcript and Figure Context During Playback

As a user,
I want to see transcript and figure context during playback (sentence/position and figures where available),
So that I can follow along visually.

**Acceptance Criteria:**

**Given** playback is in progress  
**When** the user views the player  
**Then** the current sentence (or position) in the transcript is visible and highlighted where applicable (FR26)  
**And** figures associated with the current position are shown where available (e.g. figure panel)  
**And** custom views for transcript highlight and figure panel follow UX spec (system components where possible)

### Story 5.6: Store and Restore Playback Position (Sentence-Level)

As a user,
I want my playback position to be stored and restored at sentence-level granularity,
So that I can resume from where I left off.

**Acceptance Criteria:**

**Given** the user has played part of a document  
**When** they pause or leave playback  
**Then** the last position (sentence or equivalent) is stored (e.g. in HistoryItem or related) (FR28)  
**When** they resume (e.g. from History or document detail)  
**Then** playback continues from the stored position (FR27)

### Story 5.7: Restore Playback State After App Termination

As a user,
I want the app to restore playback state if it terminated during playback,
So that I don't lose my place unexpectedly.

**Acceptance Criteria:**

**Given** the app terminated during playback (or during a write)  
**When** the user launches the app again  
**Then** the app recovers to a consistent state (e.g. last committed position) and does not leave orphaned or partially written data (FR51, NFR-R2)  
**And** the user can resume from History or queue as appropriate

---

## Epic 6: History & Resume

Users can view listening history, search by document name, filter by date and folder, see timestamp/position/duration, and resume from an entry.

### Story 6.1: View Listening History

As a user,
I want to view my listening history (past sessions per document),
So that I can see what I've listened to and resume.

**Acceptance Criteria:**

**Given** the user has one or more history entries  
**When** they open the History tab  
**Then** past sessions per document are displayed (FR29)  
**And** if history is empty, an explicit empty state is shown (NFR-U1)

**Given** history has many entries (e.g. 10,000+)  
**When** the user opens or queries history  
**Then** queries remain responsive (NFR-P6)

### Story 6.2: Search History by Document Name

As a user,
I want to search history by document name,
So that I can find a specific document's sessions quickly.

**Acceptance Criteria:**

**Given** the user is on the History screen  
**When** they use the search (e.g. .searchable) to type a document name  
**Then** history entries are filtered by document name (FR30)  
**And** results update as the user types; a clear "no results" state is shown when applicable

### Story 6.3: Filter History by Date and Folder

As a user,
I want to filter history by date range and by folder,
So that I can narrow down past sessions.

**Acceptance Criteria:**

**Given** the user is on the History screen  
**When** they apply filters (date range, folder)  
**Then** history entries are filtered accordingly (FR31)  
**And** filter controls are accessible (labels, VoiceOver)

### Story 6.4: Display Timestamp, Last Position, and Duration

As a user,
I want history entries to show at least timestamp, last listened position, and duration,
So that I can choose what to resume.

**Acceptance Criteria:**

**Given** a history entry exists  
**When** it is displayed in the History list  
**Then** at least timestamp, last listened position, and duration (or equivalent) are shown (FR32)

### Story 6.5: Open History Entry and Resume Playback

As a user,
I want to open a history entry and resume playback from that position,
So that I can continue listening where I left off.

**Acceptance Criteria:**

**Given** a history entry exists with a stored position  
**When** the user opens the entry (e.g. taps it)  
**Then** they can view details and, where supported, tap to resume playback from that position (FR33)  
**And** resume uses the same voice and settings (from Epic 5/7)

---

## Epic 7: Settings & Preferences

Users can set and persist voice, speech rate (and pitch if in scope), appearance (system/light/dark), clear history with confirmation, and see app version.

### Story 7.1: Voice Selection in Settings

As a user,
I want to choose my preferred system voice in Settings and have it persist,
So that playback uses my chosen voice.

**Acceptance Criteria:**

**Given** the user opens Settings  
**When** they view the voice option  
**Then** the app lists available system voices (e.g. from AVSpeechSynthesisVoice) and the current selection is indicated (FR23)  
**When** they select a different voice  
**Then** the selection is persisted and applied to playback (FR34)  
**And** no Appearance or Accent controls are present (UX spec: system appearance only)

### Story 7.2: Speech Rate (and Pitch if in Scope) in Settings

As a user,
I want to set speech rate (and pitch if in scope) in Settings and have it persist,
So that playback uses my preferred speed.

**Acceptance Criteria:**

**Given** the user opens Settings  
**When** they adjust speech rate (e.g. slider)  
**Then** the value is persisted and applied to playback (FR35)  
**And** if pitch is in scope, the same for pitch

### Story 7.3: Appearance (System / Light / Dark) in Settings

As a user,
I want to choose appearance (system, light, or dark) and have it persisted,
So that the app matches my preference.

**Acceptance Criteria:**

**Given** the user opens Settings  
**When** they choose system, light, or dark  
**Then** the choice is persisted and the app reflects it (FR36)  
**And** no custom theme or accent options are offered (UX spec)

### Story 7.4: Clear History with Confirmation

As a user,
I want to clear my history with explicit confirmation,
So that I can reset history when I choose, without accidental loss.

**Acceptance Criteria:**

**Given** the user is in Settings  
**When** they choose to clear history  
**Then** a confirmation is shown (e.g. alert) (FR37)  
**When** they confirm  
**Then** history entries are removed (or cleared) and the History tab reflects the empty state

### Story 7.5: App Version Display

As a user,
I want to see the app version (e.g. in Settings or about),
So that I know which build I'm running.

**Acceptance Criteria:**

**Given** the user opens Settings (or About)  
**When** they view the version section  
**Then** the app version is displayed (e.g. from bundle) (FR38)

---

## Epic 8: Accessibility

All primary flows are usable with VoiceOver only; labels, focus order, and state announcements are correct; layout supports Dynamic Type and tap targets meet guidelines.

### Story 8.1: Accessibility Labels on All Interactive Elements

As a visually impaired user,
I want every interactive element to have an accessibility label,
So that VoiceOver can announce them correctly.

**Acceptance Criteria:**

**Given** any screen in the app  
**When** the user navigates with VoiceOver  
**Then** every interactive element (buttons, links, controls, list items, etc.) has an appropriate `.accessibilityLabel` (and `.accessibilityHint` where helpful) (FR39, NFR-A1)  
**And** labels are clear and actionable (e.g. "Add PDF", "Add to folder Q1 Review")

### Story 8.2: Focus Order for VoiceOver

As a visually impaired user,
I want focus order to follow visual reading order (or platform accessibility guidelines),
So that I can navigate logically with VoiceOver.

**Acceptance Criteria:**

**Given** any screen  
**When** the user moves focus with VoiceOver  
**Then** focus order follows visual reading order or is validated against platform accessibility focus-order guidelines (FR40)  
**And** Library → folders → papers → actions flow is logical

### Story 8.3: State-Change Announcements

As a user relying on VoiceOver,
I want important state changes (e.g. "Added to queue", "Added to folder", "Playing", "Paused") to be announced,
So that I get feedback without seeing the screen.

**Acceptance Criteria:**

**Given** the user performs an action that changes state (add to folder, add to queue, play, pause, etc.)  
**When** the action completes  
**Then** the state change is announced to the user (e.g. via VoiceOver or equivalent) (FR41)  
**And** announcements are concise and consistent with UX feedback patterns

### Story 8.4: Dynamic Type Support

As a user who uses larger text,
I want layout and text to scale with Dynamic Type without breaking or obscuring content,
So that I can read comfortably.

**Acceptance Criteria:**

**Given** the user has increased text size (Dynamic Type)  
**When** they use the app  
**Then** layout and typography support Dynamic Type up to the largest accessibility sizes without clipping, overlap, or loss of functionality (FR42, NFR-A2)  
**And** no fixed font sizes block scaling; semantic styles (e.g. .body, .headline) are used

### Story 8.5: Tap Target Size and Spacing

As a user with motor or accessibility needs,
I want tap targets to meet minimum size and spacing (e.g. 44pt),
So that I can tap reliably.

**Acceptance Criteria:**

**Given** any interactive element  
**When** the user taps it  
**Then** tap targets meet minimum size and spacing for accessibility (e.g. 44pt minimum per platform guidelines) (FR43, NFR-A3)  
**And** system controls and spacing are used to achieve this where possible

### Story 8.6: VoiceOver-Only Navigation Verification

As a team,
I want the app verified as fully navigable with VoiceOver without sighted interaction,
So that we can claim and deliver accessibility.

**Acceptance Criteria:**

**Given** all primary flows (add document, manage folders, manage queue, play, History, Settings)  
**When** a tester uses VoiceOver only (no sighted interaction)  
**Then** every flow can be completed successfully (FR49, NFR-A1)  
**And** the app respects system accessibility settings (e.g. Reduce Motion, Bold Text, Increased Contrast) where applicable (NFR-A4)  
**And** critical paths are documented or tested so regressions are caught
