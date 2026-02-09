//
//  SpchPlayer.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/7/26.
//

import Foundation
import Combine
import AVFoundation

enum PlaySt {
  case idle, play, pause
}

@MainActor
final class SpchPlayer: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
  @Published var st: PlaySt = .idle
  @Published var spd: Double = 1.0
  @Published var pack: ReadPack? = nil

  // Playback cursor
  @Published var curSent: Int = 0
  @Published var winIds: [String] = [] // 5 ids shown in transcript
  @Published var headTxt: String? = nil // current section heading (solo display moments)

  private let syn = AVSpeechSynthesizer()
  private var seq: [Tok] = []
  private var tokIx: Int = 0
  private var set: AppSet
  private var isPaused = false // track if we paused mid-utterance
  private var isJumping = false // prevent concurrent jumps
  private var justJumped = false // track if we just jumped to prevent didStart overwrite
  
  // Callback when paper finishes
  var onPaperComplete: (() -> Void)?

  // token stream: headings + sentences
  private enum Tok {
    case head(String)     // section title
    case sent(Int)        // index into pack.sents
    case gap(Double)      // pause in seconds
  }

  init(set: AppSet) {
    self.set = set
    super.init()
    syn.delegate = self
    cfgAudio()
  }

  private func cfgAudio() {
    let ses = AVAudioSession.sharedInstance()
    do {
      try ses.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
      try ses.setActive(true)
    } catch {
      print("audio err:", error)
    }
  }

  func load(_ p: ReadPack, q: QItem) {
    self.pack = p
    buildSeq(p, q)
    tokIx = 0
    curSent = 0
    setWin()
    headTxt = nil
    st = .idle
    isPaused = false
  }

  func play() {
    guard st != .play else { return }
    st = .play
    
    if isPaused && syn.isPaused {
      // Resume from pause
      isPaused = false
      syn.continueSpeaking()
    } else {
      // Start fresh or restart if pause state is stale
      isPaused = false
      step()
    }
  }

  func pause() {
    guard st == .play else { return }
    st = .pause
    if syn.isSpeaking {
      isPaused = true
      syn.pauseSpeaking(at: .word)
    }
  }

  func stop() {
    st = .idle
    isPaused = false
    syn.stopSpeaking(at: .immediate)
  }

  func setSpd(_ v: Double) {
    spd = min(3.5, max(0.25, v))
  }

  // Jump forward or backward by N sentences
  func jumpSec(_ sec: Double) {
    guard let p = pack else { return }
    guard !isJumping else { return }
    
    isJumping = true
    isPaused = false
    syn.stopSpeaking(at: .immediate)
    
    // Jump by ~3 sentences per button press (roughly 10 seconds at normal speed)
    let sentencesToJump = sec >= 0 ? 3 : -3
    
    // Find all sentence tokens in the sequence
    var sentenceTokens: [(tokIdx: Int, sentIdx: Int)] = []
    for (i, tok) in seq.enumerated() {
      if case .sent(let sentIdx) = tok {
        sentenceTokens.append((i, sentIdx))
      }
    }
    
    // Find current position in sentence token array
    guard let currentPos = sentenceTokens.firstIndex(where: { $0.tokIdx == tokIx }) else {
      isJumping = false
      return
    }
    
    // Calculate new position
    let newPos = min(max(0, currentPos + sentencesToJump), sentenceTokens.count - 1)
    let (newTokIdx, newSentIdx) = sentenceTokens[newPos]
    
    // Update position
    tokIx = newTokIdx
    curSent = newSentIdx
    setWin()
    headTxt = nil
    justJumped = true
    
    // Small delay to let synthesizer fully stop, then restart
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
      guard let self else { return }
      self.isJumping = false
      
      // Restart if we were playing
      if self.st == .play {
        self.step()
      }
      
      // Reset justJumped after speaking starts
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        self.justJumped = false
      }
    }
  }

  // MARK: - Sequence build

  private func buildSeq(_ p: ReadPack, _ q: QItem) {
    var out: [Tok] = []

    // Speak meta first
    let metaTxt = metaSpeak(p.meta)
    out.append(.head(metaTxt))
    out.append(.gap(0.4))

    // For each section in order, if enabled, add heading + pauses + sentences
    for s in p.secs {
      if s.kind == "bib" { continue } // never read bibliography
      if s.kind == "appendix", !q.incApp { continue }
      if s.kind == "sum", !q.incSum { continue }
      if !q.secOn.contains(s.id) { continue }

      out.append(.gap(0.3))
      out.append(.head(s.title))
      out.append(.gap(0.35))

      for sid in s.sentIds {
        if let ix = p.sents.firstIndex(where: { $0.id == sid }) {
          out.append(.sent(ix))
        }
      }
    }
    
    // Add conclusion announcement at the end
    out.append(.gap(0.5))
    let conclusionTxt = conclusionSpeak(p.meta)
    out.append(.head(conclusionTxt))
    out.append(.gap(0.5))

    seq = out
  }
    
    private func bestVoice() -> AVSpeechSynthesisVoice? {
      // Prefer Siri / premium-ish voices if present; fall back to en-US
      let prefs = [
        "com.apple.voice.compact.en-US.Samantha",
        "com.apple.voice.enhanced.en-US.Samantha",
        "com.apple.ttsbundle.siri_female_en-US_compact",
        "com.apple.ttsbundle.siri_male_en-US_compact"
      ]

      let all = AVSpeechSynthesisVoice.speechVoices()

      for id in prefs {
        if let v = all.first(where: { $0.identifier == id }) { return v }
      }

      // Otherwise pick any en-US voice (often multiple exist)
      if let v = all.first(where: { $0.language == "en-US" }) { return v }
      return AVSpeechSynthesisVoice(language: "en-US")
    }


  private func metaSpeak(_ m: Meta) -> String {
    var parts: [String] = []
    parts.append(m.title)

    if m.auths.count > 0 && m.auths.count <= 2 {
      parts.append("By \(m.auths.joined(separator: " and "))")
    }
    if let d = m.date, !d.isEmpty {
      parts.append("Published \(d)")
    }
    return parts.joined(separator: ". ")
  }
  
  private func conclusionSpeak(_ m: Meta) -> String {
    var parts: [String] = ["We have now concluded", m.title]
    if m.auths.count > 0 && m.auths.count <= 2 {
      parts.append("by \(m.auths.joined(separator: " and "))")
    }
    return parts.joined(separator: " ")
  }

  // MARK: - Stepping

  private func step() {
    guard st == .play, tokIx < seq.count else {
      st = .idle
      // Paper finished - trigger callback
      onPaperComplete?()
      return
    }

    let tok = seq[tokIx]

    switch tok {
    case .gap(let s):
      headTxt = nil
      syn.stopSpeaking(at: .immediate)
      isPaused = false
      DispatchQueue.main.asyncAfter(deadline: .now() + s) { [weak self] in
        guard let self, self.st == .play else { return }
        self.tokIx += 1
        self.step()
      }

    case .head(let t):
      // show heading solo moment
      headTxt = t
      syn.stopSpeaking(at: .immediate)
      isPaused = false
      speak(t)
      // heading will advance in didFinish

    case .sent(let i):
      headTxt = nil
      isPaused = false
      speak(pack?.sents[i].text ?? "")
      // curSent will be updated in didStart delegate
      // advance in didFinish
    }
  }

  private func speak(_ txt: String) {
    let utt = AVSpeechUtterance(string: txt)
      utt.voice = bestVoice()

    // Map speed factor to AVSpeech rate range (rough but works well)
    let base = AVSpeechUtteranceDefaultSpeechRate // ~0.5-ish normalized
    let raw = base * Float(spd)
    utt.rate = min(0.6, max(0.1, raw))
      utt.pitchMultiplier = 0.95   // slightly lower, less “chipmunk”
      utt.preUtteranceDelay = 0.02
      utt.postUtteranceDelay = 0.02

    syn.speak(utt)
  }

  private func setWin() {
    guard let p = pack else { return }
    let i = curSent
    let ids = (i-2...i+2).compactMap { j -> String? in
      guard j >= 0 && j < p.sents.count else { return nil }
      return p.sents[j].id
    }
    winIds = ids
  }

  // MARK: - AVSpeechSynthesizerDelegate
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didStart utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            // Don't update if we just jumped - let the jump value stick
            guard !self.justJumped else { return }
            
            // Update curSent when we actually start speaking
            if case .sent(let i) = self.seq[safe: self.tokIx] {
                self.curSent = i
                self.setWin()
            }
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard self.st == .play else { return }
            self.tokIx += 1
            self.step()
        }
    }
}

// Safe array subscript
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
