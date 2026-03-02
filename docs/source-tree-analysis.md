# Source Tree Analysis

**Generated:** 2026-03-02 (Deep Scan – Step 5)

## Annotated directory tree

```
AuditLab/                          # Project root (repo)
├── AuditLab/                     # App source (Part: app)
│   ├── AuditLabApp.swift         # Entry point: @main, WindowGroup, RootView
│   ├── RootView.swift            # TabView: Library | Queue | History | Settings
│   ├── Types.swift               # ReadPack, Meta, Sec, Sent, Fig, Queue types, PaperRec, FoldRec
│   ├── LibStore.swift            # Library store (ObservableObject)
│   ├── QueueStore.swift          # Queue & folder playback store
│   ├── FoldStore.swift           # Folders store
│   ├── AppSet.swift              # Settings (UserDefaults)
│   ├── PDFParser.swift           # PDF → ReadPack parsing (PDFKit)
│   ├── SpchPlayer.swift          # AVSpeechSynthesizer playback engine
│   ├── LibraryView.swift         # Library tab
│   ├── LibraryHeaderView.swift
│   ├── LibraryCardView.swift
│   ├── FolderGridView.swift
│   ├── FolderDetailView.swift
│   ├── FolderQueueConfigView.swift
│   ├── QueueView.swift           # Queue tab
│   ├── PlayerView.swift          # Playback UI
│   ├── TranscriptView.swift
│   ├── FigurePanelView.swift
│   ├── PaperDetailView.swift
│   ├── SetView.swift             # Settings tab
│   ├── HistView.swift            # History tab
│   ├── ScratchView.swift
│   ├── DocumentPicker.swift      # PDF picker
│   ├── DemoData.swift            # Demo ReadPack data
│   └── Assets.xcassets/          # App icon, AccentColor
├── AuditLab.xcodeproj/           # Xcode project (iOS target, deployment 26.1)
├── docs/                         # Project knowledge (generated + inventory)
├── LICENSE                       # MIT
├── _bmad/                        # Tooling (excluded from app docs)
└── _bmad-output/                 # Outputs (excluded)
```

## Critical folders (app)

| Folder | Purpose |
|--------|---------|
| `AuditLab/` | All Swift sources and assets for the single app target. |
| `AuditLab/Assets.xcassets/` | App icon and accent color. |

## Entry points

- **App:** `AuditLabApp.swift` → `RootView()` with environment objects.
- **Playback:** `SpchPlayer` (created when playing a paper); `PlayerView(sp:)`.

## Integration (single-part)

No cross-part integration; single iOS app target.
