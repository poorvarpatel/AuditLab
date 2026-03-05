//
//  SpchPlayerTests.swift
//  AuditLabTests
//
//  Unit tests for SpchPlayer's non-audio logic: speed clamping,
//  sequence building, state transitions, and jump-to-sentence.
//

import XCTest
@testable import AuditLab

@MainActor
final class SpchPlayerTests: XCTestCase {

    private var set: AppSet!
    private var sp: SpchPlayer!

    override func setUp() {
        super.setUp()
        set = AppSet()
        sp = SpchPlayer(set: set)
    }

    override func tearDown() {
        sp.stop()
        sp = nil
        set = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makePack(sentenceCount: Int = 5, sectionCount: Int = 1) -> ReadPack {
        var secs: [Sec] = []
        var sents: [Sent] = []
        var sentIdx = 0

        for s in 0..<sectionCount {
            let perSection = sentenceCount / sectionCount
            var sentIds: [String] = []
            for _ in 0..<perSection {
                let id = "sent-\(sentIdx)"
                sentIds.append(id)
                sents.append(Sent(id: id, secId: "sec-\(s)", text: "Sentence \(sentIdx).", figIds: nil))
                sentIdx += 1
            }
            secs.append(Sec(id: "sec-\(s)", title: "Section \(s)", kind: "body", sentIds: sentIds, defOn: true))
        }

        return ReadPack(
            id: "test-pack",
            meta: Meta(title: "Test Paper", auths: ["A. Author"], date: "2025"),
            secs: secs,
            sents: sents,
            figs: []
        )
    }

    private func defaultQItem(for pack: ReadPack) -> QItem {
        pack.defaultQItem()
    }

    // MARK: - Speed clamping

    func testSetSpdClampsLow() {
        sp.setSpd(0.1)
        XCTAssertEqual(sp.spd, 0.25)
    }

    func testSetSpdClampsHigh() {
        sp.setSpd(5.0)
        XCTAssertEqual(sp.spd, 3.5)
    }

    func testSetSpdAcceptsValidValue() {
        sp.setSpd(1.5)
        XCTAssertEqual(sp.spd, 1.5)
    }

    func testSetSpdEdgeCases() {
        sp.setSpd(0.25)
        XCTAssertEqual(sp.spd, 0.25)
        sp.setSpd(3.5)
        XCTAssertEqual(sp.spd, 3.5)
    }

    // MARK: - Initial state

    func testInitialState() {
        XCTAssertEqual(sp.st, .idle)
        XCTAssertEqual(sp.spd, 1.0)
        XCTAssertNil(sp.pack)
        XCTAssertEqual(sp.curSent, 0)
        XCTAssertTrue(sp.winIds.isEmpty)
        XCTAssertNil(sp.headTxt)
    }

    // MARK: - Load

    func testLoadSetsPack() {
        let pack = makePack()
        let q = defaultQItem(for: pack)
        sp.load(pack, q: q)

        XCTAssertEqual(sp.pack?.id, "test-pack")
        XCTAssertEqual(sp.st, .idle)
        XCTAssertEqual(sp.curSent, 0)
        XCTAssertNil(sp.headTxt)
    }

    func testLoadSetsWindowIds() {
        let pack = makePack(sentenceCount: 6)
        let q = defaultQItem(for: pack)
        sp.load(pack, q: q)

        XCTAssertFalse(sp.winIds.isEmpty)
        XCTAssertTrue(sp.winIds.count <= 5)
        XCTAssertTrue(sp.winIds.contains("sent-0"))
    }

    func testLoadResetsState() {
        let pack = makePack()
        let q = defaultQItem(for: pack)

        sp.load(pack, q: q)
        sp.play()
        sp.pause()

        let pack2 = ReadPack(
            id: "other",
            meta: Meta(title: "Other", auths: [], date: nil),
            secs: [Sec(id: "s0", title: "Intro", kind: "body", sentIds: ["x0"], defOn: true)],
            sents: [Sent(id: "x0", secId: "s0", text: "Hello.", figIds: nil)],
            figs: []
        )
        sp.load(pack2, q: pack2.defaultQItem())

        XCTAssertEqual(sp.pack?.id, "other")
        XCTAssertEqual(sp.st, .idle)
        XCTAssertEqual(sp.curSent, 0)
    }

    // MARK: - State transitions

    func testPlaySetsPlayState() {
        let pack = makePack()
        sp.load(pack, q: defaultQItem(for: pack))
        sp.play()
        XCTAssertEqual(sp.st, .play)
    }

    func testPauseSetsPauseState() {
        let pack = makePack()
        sp.load(pack, q: defaultQItem(for: pack))
        sp.play()
        sp.pause()
        XCTAssertEqual(sp.st, .pause)
    }

    func testStopSetsIdleState() {
        let pack = makePack()
        sp.load(pack, q: defaultQItem(for: pack))
        sp.play()
        sp.stop()
        XCTAssertEqual(sp.st, .idle)
    }

    func testPauseDoesNothingWhenIdle() {
        sp.pause()
        XCTAssertEqual(sp.st, .idle)
    }

    func testDoublePlayDoesNothing() {
        let pack = makePack()
        sp.load(pack, q: defaultQItem(for: pack))
        sp.play()
        sp.play()
        XCTAssertEqual(sp.st, .play)
    }

    // MARK: - Jump to sentence

    func testJumpToSentenceUpdatesCursor() {
        let pack = makePack(sentenceCount: 6)
        sp.load(pack, q: defaultQItem(for: pack))

        sp.jumpToSentence(3)

        XCTAssertEqual(sp.curSent, 3)
        XCTAssertNil(sp.headTxt)
    }

    func testJumpToSentenceIgnoresOutOfBounds() {
        let pack = makePack(sentenceCount: 3)
        sp.load(pack, q: defaultQItem(for: pack))

        sp.jumpToSentence(10)
        XCTAssertEqual(sp.curSent, 0)

        sp.jumpToSentence(-1)
        XCTAssertEqual(sp.curSent, 0)
    }

    func testJumpToSentenceUpdatesWindow() {
        let pack = makePack(sentenceCount: 10, sectionCount: 2)
        sp.load(pack, q: defaultQItem(for: pack))

        sp.jumpToSentence(5)

        XCTAssertTrue(sp.winIds.contains("sent-5"))
    }

    func testJumpRequiresPack() {
        sp.jumpToSentence(0)
        XCTAssertEqual(sp.curSent, 0)
        XCTAssertTrue(sp.winIds.isEmpty)
    }

    // MARK: - Section filtering

    func testBibSectionsAreExcluded() {
        let pack = ReadPack(
            id: "bib-test",
            meta: Meta(title: "Bib Test", auths: [], date: nil),
            secs: [
                Sec(id: "s0", title: "Body", kind: "body", sentIds: ["b0"], defOn: true),
                Sec(id: "s1", title: "Bibliography", kind: "bib", sentIds: ["b1"], defOn: true)
            ],
            sents: [
                Sent(id: "b0", secId: "s0", text: "Body sentence.", figIds: nil),
                Sent(id: "b1", secId: "s1", text: "Bib entry.", figIds: nil)
            ],
            figs: []
        )
        sp.load(pack, q: pack.defaultQItem())

        XCTAssertEqual(sp.pack?.sents.count, 2)
        XCTAssertTrue(sp.winIds.contains("b0"))
    }

    func testDisabledSectionsAreExcluded() {
        let pack = ReadPack(
            id: "off-test",
            meta: Meta(title: "Off Test", auths: [], date: nil),
            secs: [
                Sec(id: "s0", title: "Included", kind: "body", sentIds: ["i0"], defOn: true),
                Sec(id: "s1", title: "Excluded", kind: "body", sentIds: ["e0"], defOn: false)
            ],
            sents: [
                Sent(id: "i0", secId: "s0", text: "Included sentence.", figIds: nil),
                Sent(id: "e0", secId: "s1", text: "Excluded sentence.", figIds: nil)
            ],
            figs: []
        )
        let q = pack.defaultQItem()
        XCTAssertTrue(q.secOn.contains("s0"))
        XCTAssertFalse(q.secOn.contains("s1"))

        sp.load(pack, q: q)
        sp.jumpToSentence(1)
        XCTAssertEqual(sp.curSent, 0, "Jump to excluded-section sentence should fail")
    }

    // MARK: - defaultQItem extension

    func testDefaultQItemIncludesBodySections() {
        let pack = makePack(sentenceCount: 6, sectionCount: 2)
        let q = pack.defaultQItem()

        XCTAssertEqual(q.paperId, "test-pack")
        XCTAssertEqual(q.secOn.count, 2)
        XCTAssertFalse(q.incApp)
        XCTAssertFalse(q.incSum)
    }

    func testDefaultQItemExcludesBib() {
        let pack = ReadPack(
            id: "q-test",
            meta: Meta(title: "Q", auths: [], date: nil),
            secs: [
                Sec(id: "body", title: "Body", kind: "body", sentIds: [], defOn: true),
                Sec(id: "bib", title: "References", kind: "bib", sentIds: [], defOn: true)
            ],
            sents: [],
            figs: []
        )
        let q = pack.defaultQItem()
        XCTAssertTrue(q.secOn.contains("body"))
        XCTAssertFalse(q.secOn.contains("bib"))
    }
}
