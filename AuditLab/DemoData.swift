//
//  DemoData.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/7/26.
//

import Foundation

enum DemoData {
  static func pack() -> ReadPack {
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

  static func qitem(for p: ReadPack) -> QItem {
    let on = Set(p.secs.filter { $0.defOn && $0.kind != "bib" }.map { $0.id })
    return .init(paperId: p.id, secOn: on, incApp: false, incSum: false)
  }

  static func rec(for p: ReadPack) -> PaperRec {
    .init(id: p.id, title: p.meta.title, auths: p.meta.auths, date: p.meta.date, addedAt: Date())
  }
}
