//
//  PDFParser.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/8/26.
//

import Foundation
import PDFKit
import UIKit

enum PDFParserError: Error {
  case invalidPDF
  case noText
  case parsingFailed
}

@MainActor
final class PDFParser {
  
  // MARK: - Text Block Structure
  
  /// A single run of text with consistent font properties from PDFKit.
  /// These are raw "lines" — they need to be merged into paragraphs later.
  private struct TextRun {
    let text: String
    let fontSize: CGFloat
    let isBold: Bool
    let pageNumber: Int
  }
  
  /// A merged paragraph or heading, ready for section/sentence processing.
  private struct Paragraph {
    let text: String
    let fontSize: CGFloat   // dominant font size in this paragraph
    let isBold: Bool        // was any part bold?
    let pageNumber: Int
    let isHeading: Bool     // classified as heading
    let headingKind: String // "body", "bib", "appendix"
  }
  
  // MARK: - Main Parse Function
  
  static func parse(url: URL) async throws -> ReadPack {
    guard let document = PDFDocument(url: url) else {
      throw PDFParserError.invalidPDF
    }
    
    let pageCount = document.pageCount
    guard pageCount > 0 else {
      throw PDFParserError.invalidPDF
    }
    
    // Step 1: Extract raw text runs with font metadata
    var runs: [TextRun] = []
    for pageIndex in 0..<pageCount {
      guard let page = document.page(at: pageIndex) else { continue }
      runs.append(contentsOf: extractTextRuns(from: page, pageNumber: pageIndex + 1))
    }
    
    guard !runs.isEmpty else {
      throw PDFParserError.noText
    }
    
    // Step 2: Determine body font size
    let bodyFontSize = calculateBodyFontSize(runs)
    
    // Step 3: Merge runs into paragraphs (rejoin lines that PDFKit split)
    let paragraphs = mergeIntoParagraphs(runs, bodyFontSize: bodyFontSize)
    
    // Step 4: Extract metadata from first page
    let meta = extractMetadata(from: paragraphs, bodyFontSize: bodyFontSize)
    
    // Step 5: Parse sections and sentences
    let sections = parseSections(from: paragraphs, bodyFontSize: bodyFontSize)
    
    // Step 6: Extract figures
    let figures = extractFigures(from: paragraphs)
    
    let paperId = UUID().uuidString
    
    return ReadPack(
      id: paperId,
      meta: meta,
      secs: sections.sections,
      sents: sections.sentences,
      figs: figures
    )
  }
  
  // MARK: - Step 1: Extract Raw Text Runs
  
  /// Extract text runs from a PDF page, preserving font size and bold info.
  /// Each run is a piece of text between newlines that shares font properties.
  private static func extractTextRuns(from page: PDFPage, pageNumber: Int) -> [TextRun] {
    guard let attributedString = page.attributedString else { return [] }
    
    var runs: [TextRun] = []
    var currentText = ""
    var currentSize: CGFloat = 11
    var currentBold = false
    
    attributedString.enumerateAttributes(in: NSRange(location: 0, length: attributedString.length)) { attrs, range, _ in
      let substring = (attributedString.string as NSString).substring(with: range)
      
      if let font = attrs[.font] as? UIFont {
        let newSize = font.pointSize
        let fontName = font.fontName.lowercased()
        let newBold = fontName.contains("bold") || fontName.contains("heavy") || fontName.contains("black")
        
        // Font properties changed → flush
        if abs(newSize - currentSize) > 0.5 || newBold != currentBold {
          if !currentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            runs.append(TextRun(
              text: currentText.trimmingCharacters(in: .whitespacesAndNewlines),
              fontSize: currentSize, isBold: currentBold, pageNumber: pageNumber
            ))
          }
          currentText = ""
          currentSize = newSize
          currentBold = newBold
        }
      }
      
      // Split on newlines
      for char in substring {
        if char == "\n" {
          let trimmed = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
          if !trimmed.isEmpty {
            runs.append(TextRun(text: trimmed, fontSize: currentSize, isBold: currentBold, pageNumber: pageNumber))
          }
          currentText = ""
        } else {
          currentText.append(char)
        }
      }
    }
    
    // Flush
    let trimmed = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
    if !trimmed.isEmpty {
      runs.append(TextRun(text: trimmed, fontSize: currentSize, isBold: currentBold, pageNumber: pageNumber))
    }
    
    return runs
  }
  
  // MARK: - Step 2: Body Font Size
  
  private static func calculateBodyFontSize(_ runs: [TextRun]) -> CGFloat {
    var sizeCounts: [CGFloat: Int] = [:]
    for run in runs {
      let rounded = (run.fontSize * 2).rounded() / 2
      sizeCounts[rounded, default: 0] += run.text.count
    }
    return sizeCounts.max(by: { $0.value < $1.value })?.key ?? 11
  }
  
  // MARK: - Step 3: Merge Runs into Paragraphs
  
  /// PDFKit splits text at every visual line break. We need to merge consecutive
  /// body-text runs back into paragraphs. A new paragraph starts when:
  /// - Font size or bold status changes significantly
  /// - A line is a heading (short + bold/large)
  /// - A line is very short (likely end of paragraph or caption)
  /// - Page changes
  private static func mergeIntoParagraphs(_ runs: [TextRun], bodyFontSize: CGFloat) -> [Paragraph] {
    var paragraphs: [Paragraph] = []
    var currentLines: [String] = []
    var currentSize: CGFloat = 0
    var currentBold = false
    var currentPage = 0
    
    func flush() {
      guard !currentLines.isEmpty else { return }
      let joined = currentLines.joined(separator: " ")
        .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
      guard !joined.isEmpty else { currentLines = []; return }
      
      // Clean: remove URLs, emails, citations
      let cleaned = cleanText(joined)
      guard !cleaned.isEmpty else { currentLines = []; return }
      
      let isHead = classifyAsHeading(cleaned, fontSize: currentSize, isBold: currentBold, bodyFontSize: bodyFontSize, pageNumber: currentPage)
      
      paragraphs.append(Paragraph(
        text: cleaned,
        fontSize: currentSize,
        isBold: currentBold,
        pageNumber: currentPage,
        isHeading: isHead.isHeading,
        headingKind: isHead.kind
      ))
      currentLines = []
    }
    
    for run in runs {
      let text = run.text
      
      // Skip empty
      guard !text.isEmpty else { continue }
      
      // Skip page numbers (just digits, short)
      if text.allSatisfy({ $0.isNumber }) && text.count < 5 { continue }
      
      let isBodySize = abs(run.fontSize - bodyFontSize) < 1.0
      let isSameFont = abs(run.fontSize - currentSize) < 1.0 && run.isBold == currentBold
      let isSamePage = run.pageNumber == currentPage
      
      // Determine if this run is a heading-like line
      let looksLikeHeading = (run.fontSize > bodyFontSize + 0.5 || run.isBold) && text.count < 80
      
      // Should we start a new paragraph?
      let startNew: Bool
      if currentLines.isEmpty {
        startNew = true
      } else if !isSamePage {
        startNew = true
      } else if !isSameFont {
        // Font changed → new paragraph
        startNew = true
      } else if looksLikeHeading {
        startNew = true
      } else if currentBold && !isBodySize {
        // Current paragraph is heading-like, this run continues it only if same style
        startNew = !isSameFont
      } else {
        // Body text: keep merging lines into the same paragraph
        startNew = false
      }
      
      if startNew {
        flush()
        currentSize = run.fontSize
        currentBold = run.isBold
        currentPage = run.pageNumber
      }
      
      currentLines.append(text)
    }
    
    flush()
    return paragraphs
  }
  
  // MARK: - Text Cleaning
  
  private static func cleanText(_ text: String) -> String {
    var t = text
    
    // Remove URLs
    t = t.replacingOccurrences(of: "https?://[^\\s]+", with: "", options: .regularExpression)
    
    // Remove email addresses
    t = t.replacingOccurrences(of: "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}", with: "", options: .regularExpression)
    
    // Remove in-text citations like (Author, Year)
    t = t.replacingOccurrences(of: "\\([A-Za-z][^)]{0,100}\\d{4}[a-z]?[^)]{0,20}\\)", with: "", options: .regularExpression)
    
    // Remove bracket citations like [32, 135]
    t = t.replacingOccurrences(of: "\\[\\d+(?:,\\s*\\d+)*\\]", with: "", options: .regularExpression)
    
    // Remove date headers like "APRIL 2023"
    t = t.replacingOccurrences(of: "\\b(JANUARY|FEBRUARY|MARCH|APRIL|MAY|JUNE|JULY|AUGUST|SEPTEMBER|OCTOBER|NOVEMBER|DECEMBER)\\s+\\d{4}\\b", with: "", options: .regularExpression)
    
    // Fix double-spaces from removed citations
    t = t.replacingOccurrences(of: "\\s{2,}", with: " ", options: .regularExpression)
    
    // Join hyphenated line breaks
    t = t.replacingOccurrences(of: "-\\s+", with: "-", options: .regularExpression)
    
    return t.trimmingCharacters(in: .whitespacesAndNewlines)
  }
  
  // MARK: - Academic Marker Helpers
  
  private static let academicMarkers: Set<Character> = [
    "∗", "*", "†", "‡", "§", "¶", "‖",
    "¹", "²", "³", "⁴", "⁵", "⁶", "⁷", "⁸", "⁹", "⁰"
  ]
  
  private static func hasAcademicMarkers(_ text: String) -> Bool {
    text.contains(where: { academicMarkers.contains($0) })
  }
  
  private static func stripMarkers(_ text: String) -> String {
    String(text.filter { !academicMarkers.contains($0) })
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }
  
  private static func looksLikePersonName(_ text: String) -> Bool {
    let cleaned = stripMarkers(text)
    guard cleaned.count > 3 && cleaned.count < 50 else { return false }
    let words = cleaned.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
    guard words.count >= 2 && words.count <= 5 else { return false }
    return words.allSatisfy { word in
      let letters = word.filter { $0.isLetter }
      return letters.isEmpty || letters.first?.isUppercase == true
    }
  }
  
  /// Returns true if text looks like arXiv metadata, conference header, or similar
  /// first-page noise that should NOT be treated as the title.
  private static func isFirstPageNoise(_ text: String) -> Bool {
    let lower = text.lowercased()
    return lower.contains("arxiv")
      || lower.contains("preprint")
      || lower.contains("accepted")
      || lower.contains("submitted")
      || lower.contains("proceedings")
      || lower.contains("conference")
      || lower.contains("journal of")
      || lower.contains("vol.")
      || lower.contains("issn")
      || lower.contains("doi:")
      || lower.contains("©")
      || lower.contains("copyright")
      || lower.contains("licensed under")
      || lower.contains("creative commons")
      || lower.hasPrefix("cs.")         // arXiv category like "cs.CL"
      || text.range(of: "^\\d{4}\\.\\d{4,5}", options: .regularExpression) != nil  // arXiv ID
  }
  
  // MARK: - Heading Classification
  
  private static let sectionKeywords: [(pattern: String, kind: String)] = [
    ("^\\s*\\d*\\.?\\s*abstract\\s*:?\\s*$", "body"),
    ("^\\s*\\d*\\.?\\s*introduction\\s*:?\\s*$", "body"),
    ("^\\s*\\d*\\.?\\s*background\\s*:?\\s*$", "body"),
    ("^\\s*\\d*\\.?\\s*related\\s+work\\s*:?\\s*$", "body"),
    ("^\\s*\\d*\\.?\\s*methods?\\s*:?\\s*$", "body"),
    ("^\\s*\\d*\\.?\\s*methodology\\s*:?\\s*$", "body"),
    ("^\\s*\\d*\\.?\\s*results?\\s*:?\\s*$", "body"),
    ("^\\s*\\d*\\.?\\s*discussion\\s*:?\\s*$", "body"),
    ("^\\s*\\d*\\.?\\s*conclusions?\\s*:?\\s*$", "body"),
    ("^\\s*\\d*\\.?\\s*future\\s+work\\s*:?\\s*$", "body"),
    ("^\\s*\\d*\\.?\\s*acknowledgements?\\s*:?\\s*$", "body"),
    ("^\\s*\\d*\\.?\\s*ethical\\s+considerations\\s*:?\\s*$", "body"),
    ("^\\s*\\d*\\.?\\s*(references?|bibliography|works\\s+cited)\\s*:?\\s*$", "bib"),
    ("^\\s*\\d*\\.?\\s*appendi(x|ces)\\s*:?\\s*$", "appendix"),
  ]
  
  private static func classifyAsHeading(_ text: String, fontSize: CGFloat, isBold: Bool, bodyFontSize: CGFloat, pageNumber: Int) -> (isHeading: Bool, kind: String) {
    let lower = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Check known section keywords
    for (pattern, kind) in sectionKeywords {
      if lower.range(of: pattern, options: .regularExpression) != nil {
        return (true, kind)
      }
    }
    
    // Numbered sections like "1 Introduction" or "5.2 Results"
    if text.range(of: "^\\d+(\\.\\d+)*\\s+[A-Z]", options: .regularExpression) != nil
       && text.count < 80
       && (fontSize > bodyFontSize + 0.3 || isBold) {
      if lower.contains("reference") || lower.contains("bibliography") { return (true, "bib") }
      if lower.contains("appendix") { return (true, "appendix") }
      return (true, "body")
    }
    
    // Font-based: bold or larger, short, starts uppercase, no trailing period
    if (fontSize > bodyFontSize + 0.3 || isBold)
        && text.count < 80 && text.count > 3
        && text.first?.isUppercase == true
        && !text.hasSuffix(".") {
      // Don't classify title-sized text on page 1 as section heading
      if pageNumber == 1 && fontSize > bodyFontSize + 3 { return (false, "body") }
      if lower.contains("reference") || lower.contains("bibliography") { return (true, "bib") }
      if lower.contains("appendix") { return (true, "appendix") }
      return (true, "body")
    }
    
    return (false, "body")
  }
  
  // MARK: - Metadata Extraction
  
  private static func extractMetadata(from paragraphs: [Paragraph], bodyFontSize: CGFloat) -> Meta {
    let firstPage = paragraphs.filter { $0.pageNumber == 1 }
    guard !firstPage.isEmpty else { return Meta(title: "Untitled", auths: [], date: nil) }
    
    // --- TITLE ---
    // Find the largest font size on page 1, EXCLUDING first-page noise (arXiv, etc.)
    let candidateBlocks = firstPage.filter { !isFirstPageNoise($0.text) }
    let maxFontSize = candidateBlocks.map(\.fontSize).max() ?? bodyFontSize
    
    // Title = blocks at max font size that are clearly bigger than body text
    let titleThreshold = max(bodyFontSize + 1.5, maxFontSize - 1.0)
    
    var titleParts: [String] = []
    var titleEndIndex = 0
    
    for (index, para) in firstPage.enumerated() {
      // Skip noise (arXiv references, copyright notices, etc.)
      if isFirstPageNoise(para.text) {
        if !titleParts.isEmpty {
          titleEndIndex = index
          break
        }
        continue
      }
      
      if para.fontSize >= titleThreshold && para.text.count > 3 && !isFirstPageNoise(para.text) {
        titleParts.append(para.text)
        titleEndIndex = index + 1
      } else if !titleParts.isEmpty {
        // Title ended
        break
      }
    }
    
    // FALLBACK: if font sizes don't distinguish title, use text patterns
    if titleParts.isEmpty {
      for (index, para) in firstPage.prefix(15).enumerated() {
        let text = para.text
        if isFirstPageNoise(text) { continue }
        if text.count < 5 || text.contains("@") { continue }
        
        // Stop at authors
        if (hasAcademicMarkers(text) && text.count < 80) ||
           (looksLikePersonName(text) && !titleParts.isEmpty) {
          titleEndIndex = index
          break
        }
        // Stop at affiliations
        let lower = text.lowercased()
        if lower.contains("university") || lower.contains("institute") || lower.contains("department") {
          if !titleParts.isEmpty { titleEndIndex = index; break }
          continue
        }
        if lower.hasPrefix("abstract") { titleEndIndex = index; break }
        
        if text.first?.isUppercase == true && text.count < 150 {
          titleParts.append(text)
          titleEndIndex = index + 1
        } else if !titleParts.isEmpty {
          titleEndIndex = index
          break
        }
      }
    }
    
    let title = titleParts.isEmpty ? "Untitled" : titleParts.joined(separator: " ")
    
    // --- AUTHORS ---
    var authors: [String] = []
    let scanEnd = min(titleEndIndex + 15, firstPage.count)
    
    for i in titleEndIndex..<scanEnd {
      let text = firstPage[i].text
      let lower = text.lowercased()
      
      if lower.hasPrefix("abstract") || lower.hasPrefix("introduction") { break }
      if text.count > 200 { break }
      if isFirstPageNoise(text) { continue }
      
      // Skip affiliations
      if lower.contains("university") || lower.contains("institute") ||
         lower.contains("department") || lower.contains("college") ||
         text.contains("@") { continue }
      
      let hasMarkers = hasAcademicMarkers(text)
      let isName = looksLikePersonName(text)
      let hasCommas = text.contains(",") && !text.hasSuffix(",")
      let hasAnd = lower.contains(" and ")
      
      if hasMarkers || isName || ((hasCommas || hasAnd) && text.count < 150) {
        let cleaned = stripMarkers(text)
        let candidates = cleaned
          .replacingOccurrences(of: " and ", with: ",", options: .caseInsensitive)
          .components(separatedBy: ",")
          .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
          .filter { !$0.isEmpty && $0.count > 2 && $0.count < 50
            && !$0.lowercased().contains("university")
            && !$0.lowercased().contains("institute") }
        authors.append(contentsOf: candidates)
      } else if !authors.isEmpty {
        break
      }
    }
    authors = Array(authors.prefix(10))
    
    // --- DATE ---
    var date: String? = nil
    for para in firstPage {
      if let match = para.text.range(of: "\\d{1,2}\\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec|January|February|March|April|May|June|July|August|September|October|November|December)\\s+\\d{4}", options: .regularExpression) {
        date = String(para.text[match])
        break
      }
    }
    if date == nil {
      for para in firstPage {
        if let match = para.text.range(of: "\\b(19|20)\\d{2}\\b", options: .regularExpression) {
          date = String(para.text[match])
          break
        }
      }
    }
    
    return Meta(title: title, auths: authors, date: date)
  }
  
  // MARK: - Section Parsing
  
  private struct ParsedSections {
    var sections: [Sec]
    var sentences: [Sent]
  }
  
  private static func parseSections(from paragraphs: [Paragraph], bodyFontSize: CGFloat) -> ParsedSections {
    var sections: [Sec] = []
    var sentences: [Sent] = []
    
    var currentSection: (id: String, title: String, kind: String, sentIds: [String]) =
      ("main", "Main Content", "body", [])
    var sectionIndex = 0
    var inBibliography = false
    var startedContent = false
    
    for para in paragraphs {
      let text = para.text
      let lower = text.lowercased()
      
      // Skip until Abstract or Introduction
      if !startedContent {
        if lower.hasPrefix("abstract") || lower.hasPrefix("introduction") ||
           lower.range(of: "^\\d+\\.?\\s*(abstract|introduction)", options: .regularExpression) != nil {
          startedContent = true
        } else {
          continue
        }
      }
      
      // Skip short fragments
      if text.count < 10 { continue }
      
      // Skip figure/table captions
      if !inBibliography && (lower.hasPrefix("figure") || lower.hasPrefix("fig.") || lower.hasPrefix("table")) {
        continue
      }
      
      if para.isHeading {
        // Save previous section
        if !currentSection.sentIds.isEmpty {
          sections.append(Sec(
            id: currentSection.id,
            title: currentSection.title,
            kind: currentSection.kind,
            sentIds: currentSection.sentIds,
            defOn: currentSection.kind == "body"
          ))
        }
        
        if para.headingKind == "bib" { inBibliography = true }
        else if para.headingKind == "appendix" { inBibliography = false }
        
        sectionIndex += 1
        var cleanTitle = text
        if let numPrefix = cleanTitle.range(of: "^\\d+(\\.\\d+)*\\s+", options: .regularExpression) {
          cleanTitle = String(cleanTitle[numPrefix.upperBound...])
        }
        cleanTitle = cleanTitle.replacingOccurrences(of: ":", with: "").trimmingCharacters(in: .whitespaces)
        
        currentSection = (id: "sec\(sectionIndex)", title: cleanTitle, kind: para.headingKind, sentIds: [])
        
      } else if !inBibliography {
        // Body paragraph — split into sentences
        let sents = splitIntoSentences(text)
        
        for sentence in sents {
          if sentence.count < 20 { continue }
          
          let sentId = "sent\(sentences.count)"
          let figIds = extractFigureReferences(from: sentence)
          
          sentences.append(Sent(
            id: sentId,
            secId: currentSection.id,
            text: sentence,
            figIds: figIds.isEmpty ? nil : figIds
          ))
          currentSection.sentIds.append(sentId)
        }
      }
    }
    
    if !currentSection.sentIds.isEmpty {
      sections.append(Sec(
        id: currentSection.id,
        title: currentSection.title,
        kind: currentSection.kind,
        sentIds: currentSection.sentIds,
        defOn: currentSection.kind == "body"
      ))
    }
    
    return ParsedSections(sections: sections, sentences: sentences)
  }
  
  // MARK: - Sentence Splitting
  
  private static func splitIntoSentences(_ text: String) -> [String] {
    // The text is already a merged paragraph at this point.
    // Split on sentence-ending punctuation followed by a space and uppercase letter.
    // Be careful not to split on abbreviations like "Dr." "e.g." "et al." "U.S." etc.
    
    let pattern = "(?<=[.!?])\\s+(?=[A-Z])"
    guard let regex = try? NSRegularExpression(pattern: pattern) else {
      return [text]
    }
    
    let nsString = text as NSString
    let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
    
    var sentences: [String] = []
    var lastEnd = 0
    
    for match in matches {
      let end = match.range.location
      let candidate = nsString.substring(with: NSRange(location: lastEnd, length: end - lastEnd))
        .trimmingCharacters(in: .whitespacesAndNewlines)
      
      // Don't split if the "sentence" is very short (likely a split on abbreviation)
      if candidate.count < 15 && !sentences.isEmpty {
        // Merge with previous sentence instead
        sentences[sentences.count - 1] += " " + candidate
      } else if !candidate.isEmpty {
        sentences.append(candidate)
      }
      lastEnd = end
    }
    
    // Remaining text
    if lastEnd < nsString.length {
      let remaining = nsString.substring(from: lastEnd).trimmingCharacters(in: .whitespacesAndNewlines)
      if !remaining.isEmpty {
        if remaining.count < 15 && !sentences.isEmpty {
          sentences[sentences.count - 1] += " " + remaining
        } else {
          sentences.append(remaining)
        }
      }
    }
    
    return sentences.isEmpty ? [text] : sentences
  }
  
  // MARK: - Figure Extraction
  
  private static func extractFigureReferences(from text: String) -> [String] {
    let pattern = "(?i)fig(?:ure|\\.)?\\s*(\\d+[a-z]?)"
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
    let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
    return matches.compactMap { match in
      guard match.numberOfRanges > 1, let range = Range(match.range(at: 1), in: text) else { return nil }
      return "Figure \(text[range])"
    }
  }
  
  private static func extractFigures(from paragraphs: [Paragraph]) -> [Fig] {
    let pattern = "(?i)(fig(?:ure|\\.)?\\s*\\d+[a-z]?)[:.]?\\s*(.+)"
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
    
    var figures: [Fig] = []
    for para in paragraphs {
      let text = para.text
      for match in regex.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
        guard match.numberOfRanges > 2,
              let lr = Range(match.range(at: 1), in: text),
              let cr = Range(match.range(at: 2), in: text) else { continue }
        let label = String(text[lr]).trimmingCharacters(in: .whitespacesAndNewlines)
        let caption = String(text[cr]).trimmingCharacters(in: .whitespacesAndNewlines)
        figures.append(Fig(id: label, label: label, url: "", cap: caption))
      }
    }
    return figures
  }
}
