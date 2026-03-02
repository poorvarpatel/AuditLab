# Data Models – app (AuditLab)

**Generated:** 2026-03-02 (Deep Scan – Step 4)

## Parsed paper content (ReadPack)

| Type | Purpose |
|------|---------|
| `ReadPack` | Top-level: id, meta, secs, sents, figs. |
| `Meta` | title, auths, date. |
| `Sec` | Section: id, title, kind ("body"\|"appendix"\|"bib"\|"sum"), sentIds, defOn. |
| `Sent` | Sentence: id, secId, text, figIds. |
| `Fig` | Figure: id, label, url, cap. |

## Library & queue

| Type | Purpose |
|------|---------|
| `PaperRec` | Library record: id, title, auths, date, addedAt, isRead. |
| `QItem` | Legacy queue item: paperId, secOn, incApp, incSum. |
| `PaperQueueConfig` | Paper in queue: paperId, secOn, incApp, incSum. |
| `FolderQueueConfig` | Folder in queue: folderId, selectedPaperIds, isExpanded. |
| `QueueItemType` | Enum: .paper(PaperQueueConfig) \| .folder(FolderQueueConfig). |
| `QueueItem` | Wrapper: id + QueueItemType. |

## Folders

| Type | Purpose |
|------|---------|
| `FoldRec` | Folder: id (UUID), name, pids (paper IDs). |

## Persistence (current)

- **UserDefaults:** AppSet (skipAsk, figBg, wps).
- **In-memory:** LibStore.recs, LibStore.packs; QueueStore.items/folderPapersMap; FoldStore.folds. Comment in LibStore: “later: persist to disk”.
