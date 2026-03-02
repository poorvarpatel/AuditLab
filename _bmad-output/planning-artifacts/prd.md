---
stepsCompleted: ['step-01-init', 'step-02-discovery', 'step-02b-vision', 'step-02c-executive-summary', 'step-03-success', 'step-04-journeys', 'step-05-domain', 'step-06-innovation', 'step-07-project-type', 'step-08-scoping', 'step-09-functional', 'step-10-nonfunctional', 'step-11-polish', 'step-e-01-discovery', 'step-e-02-review', 'step-e-03-edit']
date: '2025-03-02'
lastEdited: '2025-03-02'
editHistory:
  - date: '2025-03-02'
    changes: 'Validation-report-driven edits: FR16/24/32 wording, FR40/43/47 measurability, NFR-P1/P6 specificity, frontmatter date.'
classification:
  projectType: mobile_app
  domain: general
  complexity: low
  projectContext: brownfield
inputDocuments:
  - docs/index.md
  - docs/project-overview.md
  - docs/project-structure.md
  - docs/architecture.md
  - docs/architecture-patterns.md
  - docs/technology-stack.md
  - docs/development-guide.md
  - docs/deployment-configuration.md
  - docs/source-tree-analysis.md
  - docs/existing-documentation-inventory.md
  - docs/data-models-app.md
  - docs/state-management-app.md
  - docs/ui-component-inventory-app.md
  - docs/asset-inventory-app.md
  - docs/api-contracts-app.md
briefCount: 0
researchCount: 0
brainstormingCount: 0
projectDocsCount: 15
workflowType: 'prd'
---

# Product Requirements Document - AuditLab

**Author:** Hajoonkim
**Date:** 2025-03-02

## Executive Summary

AuditLab is an iOS app that turns PDFs into structured, navigable, audible content so users can manage a paper library, build playback queues, and listen with transcript and figure support. The product vision is full workflow: organize, sort, export, and share papers and transcripts, not just listen. Target users include researchers, students, and professionals who need to work with papers efficiently; accessibility is a first-class concern for visually impaired users. Near-term priorities: persistence for library, queue, and folders; user-facing error handling when add/parse fails; completing add-to-folder and History read status; replacing demo data in paper detail; and adding a README and basic test coverage.

### What Makes This Special

- **HIG and native feel:** The app follows Apple's Human Interface Guidelines so it feels consistent and predictable on iOS.
- **Accessibility:** Designed to work well with VoiceOver and for visually impaired users from the start, not as an afterthought.
- **Actionable content:** Import and "read" PDFs—parse into sections, sentences, and figures—then queue, navigate, listen, and (when implemented) export and share. PDFs become actionable content, not just files to open.

## Project Classification

| Dimension | Value |
|-----------|--------|
| **Project type** | Mobile app (iOS, Swift/SwiftUI, single Xcode target) |
| **Domain** | General / productivity |
| **Complexity** | Low |
| **Project context** | Brownfield (existing codebase and documentation) |

## Success Criteria

### User Success

- Users can **organize papers in folders** with **one document in multiple folders** (many-to-many); folders work reliably and match mental model.
- Users can **listen** with a **chosen system voice** (selection persisted); playback feels intentional, not brittle.
- Users can **find past listening activity** via **History** with search and filters (by date, document, folder); History feels like a real tool, not a placeholder.
- **Visually impaired users** can use the app effectively with VoiceOver (labels, order, Dynamic Type, tap targets); accessibility is a visible differentiator.
- **Core "done" moment:** Add PDFs → put them in folders (including same doc in multiple folders) → build queue → listen with chosen voice → later find and resume from History.

### Business Success

- **App Store readiness:** The app looks and behaves like something that could ship tomorrow (icon, launch screen, dark mode, no obvious crashes or layout bugs).
- **Portfolio / interview narrative:** In 30 seconds, "Accessible, persistent, searchable PDF-to-audio research tool built with clean architecture and production-grade iOS patterns" is obvious from the product and code.

### Technical Success

- **Persistence:** Full move to **Core Data** for documents, folders, history, and app state; UserDefaults only where it's the right tool (e.g. trivial UI prefs if needed).
- **Data model:** Correct **many-to-many** (Document ↔ Folder) in Core Data; no ad-hoc ID arrays or UserDefaults for library/queue/folders.
- **Architecture:** Clear separation—Views, ViewModels (or equivalent), Persistence layer, Speech service, PDF service; no business logic in views; no oversized view files.
- **Quality:** Dark mode works; SwiftUI **native components only**; intentional empty and loading states; error handling for bad/malformed PDFs (no crashes).
- **Accessibility:** VoiceOver tested; accessibility labels and navigation order; support for larger Dynamic Type; no too-small tap targets.

### Measurable Outcomes

| Outcome | Target |
|--------|--------|
| Folders + many-to-many | One document appears in multiple folders and stays correct after restart. |
| Persistence | Library, queue, folders survive app restart with Core Data. |
| Voice selection | User-selected voice persists and is used for TTS. |
| History | Search + filter (date, document, folder) return correct results. |
| Accessibility | Critical flows usable with VoiceOver; no blocking issues. |
| Stability | No crashes on malformed or bad PDFs; graceful degradation. |

## Product Scope

### MVP – Minimum Viable Product

- **Data & persistence**
  - Core Data model: **Document**, **Folder**, **HistoryItem** (optional: **TranscriptChunk**).
  - Many-to-many Document ↔ Folder; no workarounds.
  - Migrate off UserDefaults for library, queue, folders, and any persistent app data; use UserDefaults only where it's the right fit.
- **Folders**
  - Fix current folder behavior.
  - Support one file in multiple folders end-to-end (add/remove from folder, show in each folder, persist).
- **PDF extraction**
  - Smarter, more polished extraction: e.g. regex for headers/footers, page numbers; normalize whitespace; better paragraph/chunk separation for TTS; optional section detection (e.g. ALL CAPS/bold). No overengineering—polish over new tech.
- **Speech**
  - List all `AVSpeechSynthesisVoice.speechVoices()`; user can select voice; selection persisted; applied to playback.
- **History**
  - Search bar (e.g. SwiftUI `.searchable`).
  - Filters: by date, by document, by folder.
  - Show: timestamp, last listened position, duration (and any other fields needed for the "thoughtful tool" feel).
- **Settings**
  - Voice selection, speech rate, dark mode override (System / Light / Dark), clear history, app version. Clean and intentional; no clutter.
- **App quality**
  - Dark mode working; SwiftUI-only, native UI; empty and loading states; error handling for bad PDFs (no crashes); basic accessibility (labels, order, tap targets, Dynamic Type where relevant).

### Growth Features (Post-MVP)

- Speech: **rate slider**, **pitch slider**, **"continue from last position"** (resume).
- History and data: richer History display; optional TranscriptChunk in Core Data if needed for resume or search.
- App Store polish: app icon, launch screen, privacy policy stub, proper app name/capitalization; feel shippable.

### Vision (Future)

- Keep the product **simple and shippable**; avoid scope that doesn't support the core story.
- **Explicitly out of scope:** AI summaries, cloud sync, user accounts, collaboration, complex analytics, overdesigned custom UI. Prefer "simple and finished" over "ambitious and half-done."

## User Journeys

### 1. Primary User – Success Path

**Opening scene:** Alex is preparing for a literature review. They have a stack of PDFs and need to listen while commuting and later pick up exactly where they left off. They've tried generic PDF readers and separate TTS tools; nothing keeps papers, queue, and listening position in one place.

**Rising action:** Alex opens AuditLab, adds a PDF via the document picker, and sees it in the library. They create a folder "Q1 Review" and add the same paper to that folder and to "Priority." They build a queue from the folder, tap play, and listen with transcript and figures. They choose a preferred voice in Settings and see it persist. Later they open History, search by document name, and see last position and duration.

**Climax:** Alex finishes a section, closes the app, and reopens it the next day. The queue and folder membership are unchanged. They resume from History and continue from the last sentence. The app feels like a single, reliable research tool.

**Resolution:** Alex can treat AuditLab as the place to organize, queue, and listen to papers with chosen voice and resume—no re-finding or re-adding. Research flow is continuous.

---

### 2. Visually Impaired User – Accessibility Journey

**Opening scene:** Jordan relies on VoiceOver for all iOS use. Many apps have unlabeled buttons, illogical focus order, or layouts that break with larger text. Jordan needs to add PDFs, put them in folders, build a queue, and listen—same workflow as sighted users—but success means "VoiceOver reads everything correctly and I never get lost."

**Rising action:** Jordan opens AuditLab with VoiceOver on. Every control has a clear accessibility label; focus order follows the visual flow (Library → folders → papers → add actions). They add a PDF and hear confirmation ("Added to library"). They assign the document to multiple folders and hear feedback ("Added to folder Q1 Review"). They build a queue and hear "Added to queue." They start playback and hear the selected voice; transcript and position are announced. In Settings, voice list and options are fully readable; Dynamic Type is supported and layout doesn't break at larger sizes. Tap targets are large enough and logically grouped.

**Climax:** Jordan completes the full flow—add PDF, assign to folders, queue, play, change voice, search History—without sighted help. State changes (e.g. "Added to queue," "Playing," "Paused") are announced. They feel the app was designed for them, not adapted after the fact.

**Resolution:** Jordan can use AuditLab as their primary PDF-to-audio research tool. Accessibility is a first-class outcome, not a checklist item.

---

### 3. Evaluator / Portfolio Review Journey (30-Second Scan)

**Opening scene:** An interviewer or reviewer has 30 seconds to judge whether the app and its author show "clean architecture, thoughtful persistence, accessible, production-ready." They don't use the app like a daily user; they scan for signals.

**Rising action:** They open the app and see a clear folder structure and library (no clutter). They add a PDF quickly, assign it to two folders, and see it in both. They start playback, then open Settings and switch voice; the new voice applies immediately and the choice feels persistent. They open History, use search, and see last listened position and duration. They note dark mode, native SwiftUI, and no obvious layout bugs.

**Climax:** In under 30 seconds they've seen: organization (folders, many-to-many), persistence (library, queue, folders, voice, history), playback and voice selection, and searchable history with resume. They conclude: "Clean architecture. Thoughtful persistence. Accessible. Production-ready."

**Resolution:** The evaluator treats the product and the builder as intentional and shippable. The 30-second demo supports the stated narrative.

---

### 4. Edge Case: Malformed / Bad PDF

**Opening scene:** Sam imports a PDF that's corrupted, password-protected, or otherwise unparseable. In a fragile app this could mean a crash or a silent failure with no way to recover.

**Rising action:** Sam selects the file. The app attempts to parse it. Parsing fails. Instead of crashing, the app shows a clear error message (e.g. "Couldn't read this PDF. It may be corrupted or in an unsupported format."). The app remains stable; library, queue, and folders are unchanged. Sam can dismiss the error and try another file or remove the problematic one from the picker.

**Climax:** Failure is contained and communicated. No data loss, no crash, no dead end.

**Resolution:** Sam trusts the app with marginal files. Defensive handling of bad PDFs is a visible sign of engineering maturity.

---

### 5. Edge Case: Resume From Last Position

**Opening scene:** Casey is listening to a long paper and has to close the app mid-sentence (phone call, end of commute). They want to reopen days later and resume exactly where they left off.

**Rising action:** Casey pauses and switches away (or the app is backgrounded/closed). Days later they open AuditLab. They go to History, find the document, and see "Resume from [position]" or equivalent. They tap resume; playback continues from that sentence with the same voice and settings.

**Climax:** Continuity is preserved across sessions. Persistence isn't just "library and folders survive"—it's "playback state survives so I can resume research with zero re-finding."

**Resolution:** Casey treats AuditLab as reliable for long-form listening. Resume-from-last-position is a core expectation, not a nice-to-have.

---

### 6. Returning User After Weeks ("Future Self")

**Opening scene:** Morgan used AuditLab heavily for a project, then didn't open it for three weeks. They return and wonder: Is my library still there? Can I find what I was listening to? Do I have to reconfigure everything?

**Rising action:** Morgan opens the app. The library and folder structure are intact. Voice preference is unchanged. They open History, search by document or date, and see past sessions with last position and duration. They tap resume on a paper and continue from where they left off. No re-import, no re-organization, no "start over."

**Climax:** The app behaves like a stable, long-term research tool. Persistence and searchable history make "future self" a supported user.

**Resolution:** Morgan can leave and return without anxiety. Stability and persistence support real-world, intermittent use.

---

### Journey Requirements Summary

| Journey | Capabilities / requirements surfaced |
|--------|--------------------------------------|
| **Primary – Success** | Add PDF; many-to-many folders; build queue; play with transcript/figures; voice selection (persisted); History with search and last position; persistence of library, queue, folders. |
| **Visually Impaired** | Full VoiceOver support; accessibility labels on all controls; logical focus order; Dynamic Type without layout break; spoken feedback on state changes; adequate tap targets; same workflow as primary (add, folders, queue, listen, History). |
| **Evaluator / Portfolio** | Clean first impression; folder structure and many-to-many visible; fast add + assign + play + switch voice; History search and resume visible; dark mode; native SwiftUI; no obvious bugs—all achievable in a short demo. |
| **Malformed PDF** | Graceful parse failure; clear, user-facing error message; no crash; no corruption of existing data; dismissible error and recovery path. |
| **Resume from last position** | Persist playback position (e.g. sentence/section) per document; History shows "resume" entry; resume restores position, voice, and context. |
| **Returning user (future self)** | Persistence of library, folders, voice preference; History searchable by document/date; resume from History; no re-setup after long absence. |

The following sections detail platform-specific requirements, scoping, and the functional and non-functional requirement set.

## Mobile App Specific Requirements

### Project-Type Overview

AuditLab is a native iOS app (Swift/SwiftUI), single target, no backend. It is fully offline: library, queue, folders, and playback state are stored on device (Core Data). The app relies on device capabilities for file access, speech synthesis, and accessibility (VoiceOver). Distribution target is the App Store; requirements align with Apple's HIG and store readiness.

### Technical Architecture Considerations

- **Native iOS only:** Swift/SwiftUI; no cross-platform layer. Minimum deployment target iOS 26.1+ (per existing project). Single Xcode target.
- **Offline-first:** No network dependency. All data (documents, folders, queue, history, voice preference, playback position) persists locally via Core Data. UserDefaults only where it is the appropriate tool (e.g. trivial UI prefs if any).
- **No push notifications:** Out of scope; no server, no push strategy.
- **Device features:** File/document picker for PDF import; AVSpeechSynthesizer for TTS; local file access for parsed content and assets. Accessibility: VoiceOver, Dynamic Type, system accessibility APIs. No camera, location, or other device features required for MVP.

### Platform Requirements

- **Platform:** iOS 26.1+ (iphoneos).
- **Frameworks:** SwiftUI, PDFKit, AVFoundation, Core Data. Combine / async-await as used today.
- **UI:** SwiftUI only; native controls and patterns. Dark mode supported (system + optional override in Settings). Layout must respect Dynamic Type and accessibility.
- **Persistence:** Core Data for Document, Folder, HistoryItem (and optional TranscriptChunk). Many-to-many Document–Folder. Migration path from current in-memory/UserDefaults state.

### Device Permissions & Capabilities

- **File access:** Document picker (and any local file access needed for PDFs). No broad "Files" or cloud storage scope required for MVP.
- **No special capabilities** for MVP (no iCloud, push, background audio beyond standard playback if applicable). Signing and capabilities kept minimal; add only as needed (e.g. background audio if required for playback).

### Offline Mode

- **Fully offline:** All features (add PDF, organize, queue, play, history, settings) work without network. No sync, no accounts, no cloud.
- **Data durability:** Library, queue, folders, history, and resume position survive app restart and device reboot. Core Data is the single source of truth.

### Push Strategy

- **Not applicable.** No push notifications; no server. Omit from implementation.

### Store Compliance

- **App Store readiness:** App icon, launch screen, proper display name/capitalization. Privacy: privacy policy stub (e.g. "No data collected" / "All data stays on device") as required for submission.
- **HIG:** Use only built-in SwiftUI components and standard patterns; no custom UI that conflicts with HIG. Support system appearance (light/dark) and optional override in Settings.
- **Stability:** No crashes on malformed or unsupported PDFs; clear error messaging and recovery. Empty and loading states handled; no unexplained blank screens.
- **Accessibility:** VoiceOver support, labels, focus order, tap targets, and Dynamic Type so the app can be reviewed and used as an accessible product.

### Implementation Considerations

- **Architecture:** Clear separation of Views, ViewModels (or equivalent), persistence layer, speech service, and PDF/service layer. No business logic in views; no oversized view files.
- **Testing:** Basic unit tests for parsing and persistence; critical paths (e.g. add PDF, bad PDF handling, resume) covered so regressions are caught.
- **Dependencies:** Prefer system frameworks only; no third-party SDKs required for MVP.

## Project Scoping & Phased Development

### MVP Strategy & Philosophy

**MVP Approach:** Experience MVP—the smallest set that delivers the core story: "Accessible, persistent, searchable PDF-to-audio research tool built with clean architecture and production-grade iOS patterns." Users can add PDFs, organize in folders (one doc in many folders), build a queue, listen with a chosen voice, and later find and resume from History. Persistence and accessibility are part of MVP, not deferred.

**Resource Requirements:** Solo or small team; iOS/Swift/SwiftUI, Core Data, and accessibility competency. No backend or infrastructure.

### MVP Feature Set (Phase 1)

**Core User Journeys Supported:**

- Primary – Success (add, folders, queue, listen, voice, History)
- Visually Impaired (same flow with VoiceOver, labels, focus order, Dynamic Type)
- Malformed PDF (graceful failure, no crash)
- Returning user (persistence + History search; full resume in Phase 2)

**Must-Have Capabilities:** See **Product Scope → MVP** for the full list. Summary: Core Data model and migration; folders (fix + many-to-many + persist); PDF extraction (smarter parsing, error handling); speech (voice list, select, persist, apply); History (search, filters, timestamp/position/duration); Settings (voice, rate, dark mode, clear history, version); quality (dark mode, native SwiftUI, empty/loading states, no crashes); accessibility (VoiceOver, labels, focus order, tap targets, Dynamic Type).

### Post-MVP Features

**Phase 2 (Growth):**

- Resume from last position (persist playback position; "Resume" in History).
- Speech: rate slider, pitch slider.
- Richer History; optional TranscriptChunk in Core Data if needed for resume/search.
- App Store polish: icon, launch screen, privacy policy stub, display name.

**Phase 3 (Vision / Expansion):**

- Keep product simple and shippable.
- No AI summaries, cloud sync, accounts, collaboration, or complex analytics.
- Export/share only if it clearly supports the core story without scope creep.

### Risk Mitigation Strategy

| Risk Type | Mitigation |
|-----------|------------|
| **Technical** | Core Data and many-to-many are well understood; design model and migration early. PDF parsing: start with regex/chunking; avoid overengineering. Test bad-PDF and resume paths. |
| **Market** | "30-second evaluator" journey defines the bar; MVP is built to satisfy that narrative. No separate market validation beyond portfolio/demo readiness. |
| **Resource** | MVP is scoped to solo/small team. If resources shrink: keep Core Data + folders + voice + History + accessibility; defer rate/pitch and extra polish to Phase 2. |

## Functional Requirements

### Library & Document Management

- FR1: User can add a PDF to the library from a document picker or file source.
- FR2: User can remove a document from the library.
- FR3: User can view the library as a list or grid of documents with identifiable metadata (e.g. title).
- FR4: User can view document detail (e.g. metadata, section structure) before adding to queue or folders.
- FR5: System persists the library across app restarts and device reboot.
- FR6: User receives clear, dismissible feedback when a PDF cannot be added or parsed (e.g. corrupted or unsupported), and existing data is unchanged.
- FR50: When a document is deleted, it is removed from all folders, queue entries, and future playback; historical records remain but are clearly marked as unavailable.

### Folders & Organization

- FR7: User can create a folder and give it a name.
- FR8: User can rename a folder.
- FR9: User can delete a folder (with defined behavior for documents that were only in that folder).
- FR10: User can add a document to a folder; the same document can be in multiple folders.
- FR11: User can remove a document from a folder without removing it from the library or other folders.
- FR12: User can view the set of documents in a folder.
- FR13: User can view which folders contain a given document.
- FR14: System persists folders and document–folder relationships across app restarts.
- FR46: System enforces uniqueness of document–folder relationships (no duplicate document-in-folder) and maintains referential integrity when documents or folders are deleted.

### Queue Management

- FR15: User can add a document to the playback queue (with optional section/scope configuration where supported).
- FR16: User can add a folder to the queue; system snapshots its current documents into the queue as discrete items (deterministic at add time; not a live reference).
- FR17: User can remove an item from the queue.
- FR18: User can reorder items in the queue.
- FR19: User can view the current queue (order and items).
- FR20: System persists the queue across app restarts.

### Playback & Speech

- FR21: User can start playback of a document (from library, queue, or history).
- FR22: User can pause and resume playback.
- FR23: User can select a system voice for playback.
- FR24: System applies user's selected voice to playback.
- FR25: User can adjust speech rate (and pitch if in scope) for playback.
- FR26: User can see transcript and figure context during playback (sentence/position and figures where available).
- FR27: User can resume playback from a stored last position (e.g. from History or document detail).
- FR28: System stores and restores playback position at sentence-level granularity (or equivalent).
- FR51: If the app terminates during playback, state is restored on next launch.

### History

- FR29: User can view listening history (past sessions per document).
- FR30: User can search history by document name.
- FR31: User can filter history by date range and by folder.
- FR32: System displays history entries with at least timestamp, last listened position, and duration (or equivalent).
- FR33: User can open a history entry to view details and, where supported, resume playback from that position.

### Settings & Preferences

- FR34: System persists the selected voice across sessions.
- FR35: System persists speech rate (and pitch if in scope) across sessions.
- FR36: User can choose appearance (system, light, or dark); choice is persisted.
- FR37: User can clear history (with explicit confirmation).
- FR38: User can see the app version (e.g. in Settings or about).

### Accessibility

- FR39: All interactive elements have accessibility labels so VoiceOver can announce them correctly.
- FR40: Focus order follows visual reading order (or is validated against platform accessibility focus-order guidelines) for VoiceOver and keyboard-style navigation.
- FR41: Important state changes (e.g. "Added to queue", "Added to folder") are announced to the user (e.g. via VoiceOver or equivalent).
- FR42: Layout and text scale support Dynamic Type without breaking layout or obscuring content.
- FR43: Tap targets meet minimum size and spacing for accessibility (e.g. 44pt minimum per platform guidelines).
- FR49: App is verified to be fully navigable using VoiceOver without requiring sighted interaction.

### Error Handling & Resilience

- FR44: When PDF parsing fails, the user sees a clear error message and the app does not crash.
- FR45: When PDF parsing or add fails, existing library, queue, and folder data remain unchanged and usable.
- FR47: System handles large PDFs (e.g. up to 400+ pages) without UI blocking or crashes.
- FR48: PDF parsing occurs asynchronously without freezing the UI.

## Non-Functional Requirements

### Performance

- NFR-P1: PDF parsing runs off the main thread so the UI remains responsive; no freezing or indefinite "loading" for documents up to 100 pages.
- NFR-P2: Large PDFs (e.g. 400+ pages) are handled without crashing or blocking the UI; parsing may be incremental or background where appropriate.
- NFR-P3: User actions receive immediate visual acknowledgment (e.g. button press state) within 100 ms where applicable; longer operations display loading or progress indicators within 500 ms.
- NFR-P4: Memory usage during parsing of large PDFs is bounded and does not grow unbounded with document size; parsing is performed incrementally where feasible.
- NFR-P5: When the app enters background, playback either pauses or continues in accordance with system audio policies (e.g. background audio capability); behavior is explicit and consistent.
- NFR-P6: History queries (search, filter) remain responsive under long-term usage (e.g. 10,000+ history entries).

### Reliability & Data Integrity

- NFR-R1: Persisted data (library, folders, queue, history, settings, playback position) survives app restart and normal device use without loss or corruption.
- NFR-R2: If the app terminates abnormally during playback or during a write, on next launch the app recovers to a consistent state (e.g. last committed state) and does not leave orphaned or partially written data.
- NFR-R3: Persistence schema changes support lightweight migration without user data loss.
- NFR-R4: The app must not crash under normal supported usage scenarios.

### Accessibility

- NFR-A1: All primary user flows (add document, manage folders, manage queue, play, History, Settings) are fully navigable and usable with VoiceOver only, without sighted assistance.
- NFR-A2: Layout and typography support Dynamic Type up to the largest accessibility sizes without clipping, overlap, or loss of functionality.
- NFR-A3: Interactive elements have sufficient tap target size and spacing to meet platform accessibility guidelines (e.g. 44pt minimum where applicable).
- NFR-A4: The app respects system accessibility settings (e.g. Reduce Motion, Bold Text, Increased Contrast) where applicable.

### Security & Privacy

- NFR-S1: All user data (documents, metadata, history, settings) remains on device unless the user explicitly exports or shares; no data is transmitted to external servers by default.
- NFR-S2: No user data is collected for analytics or third-party purposes; the app does not require network access for core functionality.
- NFR-S3: Imported documents are stored within the app sandbox and are not accessible to other apps.

### Usability & Polish

- NFR-U1: Empty states (no documents, empty queue, empty folder, no history) are explicitly designed and communicated (e.g. short message and optional action), not blank or generic.
- NFR-U2: Loading and progress states are shown for operations that can take noticeable time (e.g. adding/parsing a PDF, loading a document).
- NFR-U3: UI components use native platform UI elements and adhere to Apple Human Interface Guidelines for layout, spacing, typography, and navigation patterns.
