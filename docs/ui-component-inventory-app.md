# UI Component Inventory – app (AuditLab)

**Generated:** 2026-03-02 (Deep Scan – Step 4)

## Navigation & layout

| Component | Purpose |
|-----------|---------|
| `RootView` | TabView: Library, Queue, History, Settings. |
| `LibraryView` | Library tab: header, folder grid, paper grid (LazyVGrid), file picker & player sheets. |
| `QueueView` | Queue tab: list and playback entry. |
| `HistView` | History tab. |
| `SetView` | Settings tab. |

## Library

| Component | Purpose |
|-----------|---------|
| `LibraryHeaderView` | Add paper, add folder actions. |
| `LibraryCardView` | Card for one paper: play, add to queue, delete. |
| `FolderGridView` | Grid of folders; tap → folder detail. |
| `FolderDetailView` | Single folder detail. |
| `FolderQueueConfigView` | Folder queue configuration. |
| `DocumentPicker` | PDF file picking. |

## Playback

| Component | Purpose |
|-----------|---------|
| `PlayerView` | Player UI: title, meta, FigurePanelView, TranscriptView, controls; completion & skip handling. |
| `TranscriptView` | Transcript with current sentence highlight. |
| `FigurePanelView` | Figure display area. |
| `ScratchView` | Scratch/notes (if present). |
| `PaperDetailView` | Paper detail (if used). |

## Reusable / shared

- Standard SwiftUI (Label, Text, Button, Sheet, Alert, etc.).
- No separate design system package; system colors (e.g. `Color(.systemGroupedBackground)`).
