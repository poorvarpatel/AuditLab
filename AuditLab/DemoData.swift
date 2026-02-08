//
//  DemoData.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/7/26.
//

import Foundation

enum DemoData {
  static func pack(id: String = "demo-1") -> ReadPack {
    switch id {
    case "demo-1":
      return pack1()
    case "demo-2":
      return pack2()
    case "demo-3":
      return pack3()
    default:
      return pack1()
    }
  }
  
  private static func pack1() -> ReadPack {
    let pid = "demo-1"

    let secs: [Sec] = [
      .init(id: "s1", title: "Abstract", kind: "body",
            sentIds: ["a1","a2","a3","a4","a5"], defOn: true),
      .init(id: "s2", title: "Results", kind: "body",
            sentIds: ["r1","r2","r3","r4","r5","r6"], defOn: true),
      .init(id: "s3", title: "Works Cited", kind: "bib",
            sentIds: ["b1"], defOn: false)
    ]

    let sents: [Sent] = [
      .init(id: "a1", secId: "s1", text: "This paper tests a simple hypothesis about reading workflows.", figIds: nil),
      .init(id: "a2", secId: "s1", text: "We built an audio-first interface that reads only the content.", figIds: nil),
      .init(id: "a3", secId: "s1", text: "Headers, footers, page numbers, and bibliography are excluded.", figIds: nil),
      .init(id: "a4", secId: "s1", text: "Figure 1 is referenced when discussing the main architecture.", figIds: ["Figure 1"]),
      .init(id: "a5", secId: "s1", text: "We report that sentence-based highlighting is reliable on iOS.", figIds: nil),

      .init(id: "r1", secId: "s2", text: "Results show smoother comprehension when sections are paused.", figIds: nil),
      .init(id: "r2", secId: "s2", text: "Figure 2 demonstrates the transcript window behavior.", figIds: ["Figure 2"]),
      .init(id: "r3", secId: "s2", text: "Users prefer a center highlight with text moving around it.", figIds: nil),
      .init(id: "r4", secId: "s2", text: "The rewind and fast-forward controls reduce re-listening time.", figIds: nil),
      .init(id: "r5", secId: "s2", text: "Speed control in small increments supports fast reading.", figIds: nil),
      .init(id: "r6", secId: "s2", text: "We conclude this MVP is ready to connect to a PDF parser.", figIds: nil),

      .init(id: "b1", secId: "s3", text: "This would be ignored.", figIds: nil),
    ]

    let figs: [Fig] = [
      .init(id: "Figure 1", label: "Figure 1", url: "https://example.com/fig1.png", cap: "Architecture"),
      .init(id: "Figure 2", label: "Figure 2", url: "https://example.com/fig2.png", cap: "Transcript window")
    ]

    return ReadPack(
      id: pid,
      meta: .init(title: "Demo Paper for AuditLab", auths: ["A. Author", "B. Author"], date: "2024"),
      secs: secs,
      sents: sents,
      figs: figs
    )
  }
  
  private static func pack2() -> ReadPack {
    let pid = "demo-2"

    let secs: [Sec] = [
      .init(id: "s1", title: "Introduction", kind: "body",
            sentIds: ["i1","i2","i3"], defOn: true),
      .init(id: "s2", title: "Methodology", kind: "body",
            sentIds: ["m1","m2","m3","m4"], defOn: true),
      .init(id: "s3", title: "Conclusion", kind: "body",
            sentIds: ["c1","c2"], defOn: true)
    ]

    let sents: [Sent] = [
      .init(id: "i1", secId: "s1", text: "This study examines user behavior in mobile reading applications.", figIds: nil),
      .init(id: "i2", secId: "s1", text: "We focus on attention span and comprehension metrics.", figIds: nil),
      .init(id: "i3", secId: "s1", text: "Our hypothesis is that audio playback improves retention.", figIds: nil),

      .init(id: "m1", secId: "s2", text: "We recruited fifty participants for a controlled study.", figIds: nil),
      .init(id: "m2", secId: "s2", text: "Each participant read three academic papers in different formats.", figIds: nil),
      .init(id: "m3", secId: "s2", text: "Comprehension was measured through multiple choice questions.", figIds: nil),
      .init(id: "m4", secId: "s2", text: "Audio playback showed a fifteen percent improvement.", figIds: nil),

      .init(id: "c1", secId: "s3", text: "Our findings support the use of audio interfaces for academic reading.", figIds: nil),
      .init(id: "c2", secId: "s3", text: "Future work will explore customization options for different disciplines.", figIds: nil),
    ]

    return ReadPack(
      id: pid,
      meta: .init(title: "Audio Interfaces and Reading Comprehension", auths: ["C. Chen", "D. Davis"], date: "2025"),
      secs: secs,
      sents: sents,
      figs: []
    )
  }
  
  private static func pack3() -> ReadPack {
    let pid = "demo-3"

    let secs: [Sec] = [
      .init(id: "s1", title: "Abstract", kind: "body",
            sentIds: ["a1","a2","a3"], defOn: true),
      .init(id: "s2", title: "Discussion", kind: "body",
            sentIds: ["d1","d2","d3"], defOn: true)
    ]

    let sents: [Sent] = [
      .init(id: "a1", secId: "s1", text: "Mobile learning environments present unique challenges for content delivery.", figIds: nil),
      .init(id: "a2", secId: "s1", text: "This paper explores multimodal approaches to educational content.", figIds: nil),
      .init(id: "a3", secId: "s1", text: "We propose a framework combining visual and auditory elements.", figIds: nil),

      .init(id: "d1", secId: "s2", text: "Our framework integrates seamlessly with existing platforms.", figIds: nil),
      .init(id: "d2", secId: "s2", text: "Early testing shows promising engagement metrics.", figIds: nil),
      .init(id: "d3", secId: "s2", text: "We recommend further longitudinal studies to validate these results.", figIds: nil),
    ]

    return ReadPack(
      id: pid,
      meta: .init(title: "Multimodal Learning in Mobile Environments", auths: ["E. Evans"], date: "2025"),
      secs: secs,
      sents: sents,
      figs: []
    )
  }

  static func qitem(for p: ReadPack) -> QItem {
    let on = Set(p.secs.filter { $0.defOn && $0.kind != "bib" }.map { $0.id })
    return .init(paperId: p.id, secOn: on, incApp: false, incSum: false)
  }

  static func rec(for p: ReadPack) -> PaperRec {
    .init(id: p.id, title: p.meta.title, auths: p.meta.auths, date: p.meta.date, addedAt: Date(), isRead: false)
  }
  
  // Helper to get all demo papers
  static func allDemoPapers() -> [(pack: ReadPack, rec: PaperRec)] {
    let ids = ["demo-1", "demo-2", "demo-3"]
    return ids.map { id in
      let p = pack(id: id)
      let r = rec(for: p)
      return (p, r)
    }
  }
}
