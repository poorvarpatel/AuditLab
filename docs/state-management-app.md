# State Management – app (AuditLab)

**Generated:** 2026-03-02 (Deep Scan – Step 4)

## Stores (ObservableObject)

| Store | Role | Key state |
|-------|------|-----------|
| **LibStore** | Library of papers | `recs: [PaperRec]`, `packs: [String: ReadPack]` (in-memory). add, storePack, getPack. |
| **QueueStore** | Playback queue | `items: [QItem]`, `idx`, folder state (activeFolderId, folderPapers, folderIdx). add, rm, move, next, prev, startFolderPlayback, endFolderPlayback. |
| **FoldStore** | Folders | `folds: [FoldRec]`. addNew, rename, addPaper, removePaper, deleteFolder, moveFolder. |
| **AppSet** | Settings | `skipAsk`, `figBg`, `wps` (UserDefaults-backed). |

## Playback state

| Type | Role |
|------|------|
| **SpchPlayer** | ObservableObject; playback cursor (curSent, winIds, headTxt), pack, PlaySt (idle/play/pause). Uses AVSpeechSynthesizer; token stream (head/sent/gap). |

## Pattern

SwiftUI + Combine: `@Published` and `@EnvironmentObject`; no Redux/Vuex. All stores are `@MainActor` or used on main thread.
