//
//  PlayerView.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/7/26.
//

internal import SwiftUI
import AVFoundation

struct PlayerView: View {
    @ObservedObject var sp: SpchPlayer
    @EnvironmentObject var set: AppSet
    @EnvironmentObject var q: QueueStore
    @EnvironmentObject var lib: LibStore
    @ObservedObject var bus = NotifBus.shared
    
    @State private var showAsk = false
    @State private var askIdx = 0
    @State private var showCtrls = true
    
    var body: some View {
        VStack(spacing: 12) {
            
            // Title + meta (top)
            VStack(spacing: 4) {
                Text(titleTxt())
                    .font(.headline)
                    .lineLimit(1)
                
                Text(metaTxt())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.top, 8)
            
            // Figures (fixed area)
            FigurePanelView()
                .frame(height: 280)
                .padding(.horizontal, 14)
            
            // Transcript (middle)
            TranscriptView(sp: sp)
              .environmentObject(set)
              .layoutPriority(1)
              .padding(.horizontal, 14)
            
            // Controls (collapsible dock)
            ctrlDock()
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            setupCompletionHandler()
        }
        .onChange(of: bus.wantSkip) { oldValue, newValue in
            guard let v = newValue else { return }
            askIdx = v
            showAsk = true
            bus.wantSkip = nil
        }
        .alert("Skip to this sentence?", isPresented: $showAsk) {
            Button("Cancel", role: .cancel) { }
            Button("Skip", role: .destructive) {
                let cur = sp.curSent
                let d = Double(askIdx - cur)
                sp.jumpSec(d >= 0 ? 10 : -10)
            }
        } message: {
            Text("This will move playback to a new spot in the paper.")
        }
    }
    
    private func setupCompletionHandler() {
        sp.onPaperComplete = { [weak sp] in
            Task { @MainActor in
                guard let sp = sp else { return }
                handlePaperCompletion(sp)
            }
        }
    }
    
    private func handlePaperCompletion(_ player: SpchPlayer) {
        // Mark current paper as read
        if let currentPaperId = player.pack?.id {
            if let idx = lib.recs.firstIndex(where: { $0.id == currentPaperId }) {
                lib.recs[idx].isRead = true
            }
        }
        
        // Advance queue and load next paper
        loadNextPaper(player)
    }
    
    private func loadNextPaper(_ player: SpchPlayer) {
        // Advance queue
        q.next()
        
        // Get next item
        guard let nextItem = q.cur() else {
            // Queue finished - stop playing
            player.stop()
            return
        }
        
        // Check if this is a folder
        if nextItem.paperId.hasPrefix("folder:") {
            let folderId = String(nextItem.paperId.dropFirst(7))
            let folderPapers = q.getFolderPapers(folderId)
            
            if !folderPapers.isEmpty {
                // Start folder playback
                q.startFolderPlayback(folderId, papers: folderPapers)
                
                // Load first paper from folder
                if let firstPaper = folderPapers.first {
                    guard let nextPack = lib.getPack(id: firstPaper.paperId) else { return }
                    player.load(nextPack, q: firstPaper)
                    player.play()
                }
            } else {
                // Empty folder, skip to next
                loadNextPaper(player)
            }
        } else {
            // Regular paper - load and play
            guard let nextPack = lib.getPack(id: nextItem.paperId) else { return }
            player.load(nextPack, q: nextItem)
            player.play()
        }
    }
    
    private func ctrlDock() -> some View {
        VStack(spacing: 10) {
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showCtrls.toggle() }
                } label: {
                    Image(systemName: showCtrls ? "chevron.down" : "chevron.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(6)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("Controls")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // spacer to balance the chevron
                Color.clear.frame(width: 28, height: 28)
            }
            
            if showCtrls {
                ctrlRow()
                speedBox()
            }
        }
        .padding(14)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
    
    private func ctrlRow() -> some View {
        HStack(spacing: 18) {
            Button("⟲ 10s") { sp.jumpSec(-10) }
                .buttonStyle(.bordered)
            
            Button(sp.st == .play ? "Pause" : "Play") {
                sp.st == .play ? sp.pause() : sp.play()
            }
            .buttonStyle(.borderedProminent)
            
            Button("10s ⟳") { sp.jumpSec(10) }
                .buttonStyle(.bordered)
        }
    }
    
    private func speedBox() -> some View {
        VStack(spacing: 10) {
            HStack {
                Text("Speed")
                Spacer()
                Text(String(format: "%.2fx", sp.spd))
                    .monospacedDigit()
            }
            
            Slider(
                value: Binding(
                    get: { sp.spd },
                    set: { v in
                        let s = (v / 0.05).rounded() * 0.05
                        sp.setSpd(s)
                    }
                ),
                in: 0.25...3.5
            )
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach([0.25,0.5,0.75,1.0,1.5,2.0,2.5,3.0], id: \.self) { v in
                            Button(String(format: "%.2gx", v)) { sp.setSpd(v) }
                                .buttonStyle(.bordered)
                                .id(v)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50) // Show ~4 buttons at a time
                .onAppear {
                    // Scroll to 0.75x on first appearance
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo(0.75, anchor: .center)
                        }
                    }
                }
            }
        }
    }
    
    private func titleTxt() -> String { sp.pack?.meta.title ?? "AuditLab" }
    
    private func metaTxt() -> String {
        guard let m = sp.pack?.meta else { return "" }
        var out: [String] = []
        if m.auths.count > 0 && m.auths.count <= 2 { out.append(m.auths.joined(separator: ", ")) }
        if let d = m.date, !d.isEmpty { out.append(d) }
        return out.joined(separator: " • ")
    }
}
