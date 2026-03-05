//
//  LibraryView.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/7/26.
//

internal import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
  @EnvironmentObject var lib: LibStore
  @EnvironmentObject var q: QueueStore
  @EnvironmentObject var set: AppSet
  @EnvironmentObject var folds: FoldStore
  @EnvironmentObject var bus: NotifBus

  @State private var sp: SpchPlayer? = nil
  @State private var showPlayer = false
  @State private var selectedFolderId: String? = nil
  @State private var showFolderDetail = false
  @State private var showFilePicker = false

  var body: some View {
    ZStack {
      Color(.systemGroupedBackground).ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: 18) {
          LibraryHeaderView(
            onAddPaper: { showFilePicker = true },
            onAddFold: { folds.addNew() }
          )

          // Folders section
          if !folds.folds.isEmpty {
            FolderGridView(onTapFolder: { fold in
              selectedFolderId = fold.id
              showFolderDetail = true
            })
            .padding(.horizontal, 18)
          }

          // Papers section
          LazyVGrid(columns: cols(), spacing: 18) {
            ForEach(lib.recs) { r in
              LibraryCardView(
                rec: r,
                status: .ready,
                onPlay: { play(r) },
                onAddToQueue: { addToQueue(r) },
                onDelete: { delete(r) }
              )
              .frame(minHeight: 220)
            }
          }
          .padding(.horizontal, 18)
          .padding(.bottom, 24)
        }
      }
      .onDrop(of: [.pdf], isTargeted: nil) { providers in
        let hasPDF = providers.contains { $0.hasItemConformingToTypeIdentifier("com.adobe.pdf") }
        if hasPDF { handleDrop(providers: providers) }
        return hasPDF
      }
    }
    .sheet(isPresented: $showPlayer) {
      if let sp {
        PlayerView(sp: sp)
          .environmentObject(set)
          .environmentObject(bus)
          .environmentObject(q)
          .environmentObject(lib)
      } else {
        Text("No player loaded").padding()
      }
    }
    .sheet(isPresented: $showFolderDetail) {
      if let folderId = selectedFolderId {
        FolderDetailView(folderId: folderId)
          .environmentObject(lib)
          .environmentObject(folds)
          .environmentObject(q)
          .environmentObject(set)
          .environmentObject(bus)
      }
    }
    .sheet(isPresented: $showFilePicker) {
      DocumentPicker { url in
        showFilePicker = false
        lib.addDocument(from: url)
      }
    }
    .overlay {
      if lib.isAddingDocument {
        ZStack {
          Color.black.opacity(0.4)
            .ignoresSafeArea()
          
          VStack(spacing: 16) {
            ProgressView()
              .scaleEffect(1.5)
            Text("Parsing PDF...")
              .font(.headline)
          }
          .padding(32)
          .background(Color(.systemBackground))
          .cornerRadius(16)
          .accessibilityElement(children: .combine)
          .accessibilityLabel("Parsing PDF")
        }
      }
    }
    .alert("Add PDF Failed", isPresented: Binding(
      get: { lib.addError != nil },
      set: { if !$0 { lib.addError = nil } }
    )) {
      Button("OK") {}
    } message: {
      Text(lib.addError ?? "")
    }
  }

  private func cols() -> [GridItem] {
    [GridItem(.adaptive(minimum: 320), spacing: 18)]
  }

  private func play(_ r: PaperRec) {
    if sp == nil { sp = SpchPlayer(set: set) }
    guard let sp else { return }

    guard let p = lib.getPack(id: r.id) else { return }
    let it = DemoData.qitem(for: p)

    q.add(it)
    q.idx = max(0, q.items.count - 1)

    sp.load(p, q: it)
    showPlayer = true
  }

  private func delete(_ r: PaperRec) {
    lib.delete(r)
  }
  
  private func addToQueue(_ r: PaperRec) {
    guard let p = lib.getPack(id: r.id) else { return }
    let it = DemoData.qitem(for: p)
    q.add(it)
  }
  
  private func handleDrop(providers: [NSItemProvider]) {
    for provider in providers {
      provider.loadFileRepresentation(forTypeIdentifier: "com.adobe.pdf") { url, error in
        guard let url = url else {
          Task { @MainActor in
            lib.addError = "Couldn't use the dropped file. Please use Add to choose a PDF."
          }
          return
        }
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
        do {
          if FileManager.default.fileExists(atPath: tempURL.path) {
            try FileManager.default.removeItem(at: tempURL)
          }
          try FileManager.default.copyItem(at: url, to: tempURL)
          Task { @MainActor in
            lib.addDocument(from: tempURL, cleanupURL: tempURL)
          }
        } catch {
          Task { @MainActor in
            lib.addError = "Couldn't use the dropped file. Please use Add to choose a PDF."
          }
        }
      }
    }
  }

  private func addDemo() {
    for (pack, rec) in DemoData.allDemoPapers() {
      lib.add(rec, documentIdentity: UUID(), pack: pack)
    }
  }
}
