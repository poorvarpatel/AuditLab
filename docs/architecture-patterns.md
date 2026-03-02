# Architecture Patterns

**Generated:** 2026-03-02 (Deep Scan – Step 3)

## Part: app (AuditLab)

- **Style:** Component-based SwiftUI with centralized state stores.
- **State:** Four `ObservableObject` stores injected via `EnvironmentObject`: `LibStore` (library), `QueueStore` (playback queue), `FoldStore` (folders), `AppSet` (settings). No Redux/Vuex; native Combine + @Published.
- **Navigation:** TabView (Library, Queue, History, Settings); sheets for Player and folder/paper detail.
- **Async:** `@MainActor` on stores and player; `async/await` used in `PDFParser.parse(url:)`.
- **Entry points:** `AuditLabApp.swift` (App), `RootView` (root UI), `SpchPlayer` (playback engine).
