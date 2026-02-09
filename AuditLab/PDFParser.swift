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
  
  // Parse a PDF file and return a ReadPack
  static func parse(url: URL) async throws -> ReadPack {
    guard let document = PDFDocument(url: url) else {
      throw PDFParserError.invalidPDF
    }
    
    let pageCount = document.pageCount
    guard pageCount > 0 else {
      throw PDFParserError.invalidPDF
    }
    
    // Extract all text with positions
    var allText = ""
    for pageIndex in 0..<pageCount {
      guard let page = document.page(at: pageIndex),
            let pageText = page.string else { continue }
      allText += pageText + "\n"
    }
    
    guard !allText.isEmpty else {
      throw PDFParserError.noText
    }
    
    // Clean and structure the text
    let cleanedText = cleanText(allText)
    
    // Extract metadata
    let meta = extractMetadata(from: cleanedText)
    
    // Parse sections
    let sections = parseSections(from: cleanedText)
    
    // Extract figures (placeholder for now)
    let figures = extractFigures(from: cleanedText)
    
    let paperId = UUID().uuidString
    
    return ReadPack(
      id: paperId,
      meta: meta,
      secs: sections.sections,
      sents: sections.sentences,
      figs: figures
    )
  }
  
  // MARK: - Text Cleaning
  
  private static func cleanText(_ text: String) -> String {
    var cleaned = text
    
    // Remove URLs
    let urlPattern = "https?://[^\\s]+"
    cleaned = cleaned.replacingOccurrences(of: urlPattern, with: "", options: .regularExpression)
    
    // Remove email addresses
    let emailPattern = "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
    cleaned = cleaned.replacingOccurrences(of: emailPattern, with: "", options: .regularExpression)
    
    // Remove dates in format "MONTH YEAR" (e.g., "APRIL 2023")
    let datePattern = "\\b(JANUARY|FEBRUARY|MARCH|APRIL|MAY|JUNE|JULY|AUGUST|SEPTEMBER|OCTOBER|NOVEMBER|DECEMBER)\\s+\\d{4}\\b"
    cleaned = cleaned.replacingOccurrences(of: datePattern, with: "", options: .regularExpression)
    
    // Join hyphenated words at line breaks
    cleaned = cleaned.replacingOccurrences(of: "-\\s*\\n\\s*", with: "", options: .regularExpression)
    
    // Process lines: remove page numbers and join paragraphs
    let lines = cleaned.components(separatedBy: .newlines)
    var joinedLines: [String] = []
    var currentParagraph = ""
    
    for line in lines {
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      guard !trimmed.isEmpty else { continue }
      
      // Skip page numbers (lines that are just numbers)
      if trimmed.allSatisfy({ $0.isNumber }) && trimmed.count < 5 {
        continue
      }
      
      // Check if this line starts a new section/paragraph
      let startsNewParagraph = trimmed.first?.isUppercase == true &&
                               (currentParagraph.hasSuffix(".") ||
                                currentParagraph.hasSuffix(":") ||
                                currentParagraph.isEmpty ||
                                trimmed.count < 60) // Short lines are often headers
      
      if startsNewParagraph && !currentParagraph.isEmpty {
        joinedLines.append(currentParagraph)
        currentParagraph = trimmed
      } else {
        if !currentParagraph.isEmpty {
          currentParagraph += " "
        }
        currentParagraph += trimmed
      }
    }
    
    if !currentParagraph.isEmpty {
      joinedLines.append(currentParagraph)
    }
    
    return joinedLines.joined(separator: "\n")
  }
  
  // MARK: - Metadata Extraction
  
  private static func extractMetadata(from text: String) -> Meta {
    let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    
    // Title is usually the first or second line, often all caps or title case
    var title = "Untitled"
    var titleLineIndex = 0
    
    for (index, line) in lines.prefix(5).enumerated() {
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      // Title characteristics:
      // - Between 10-200 characters
      // - No periods at end
      // - Not a URL or date
      if trimmed.count > 10 && trimmed.count < 200 &&
         !trimmed.hasSuffix(".") &&
         !trimmed.contains("http") &&
         !trimmed.contains("@") {
        title = trimmed
        titleLineIndex = index
        break
      }
    }
    
    // Authors: look for names after title (before Abstract/Introduction)
    var authors: [String] = []
    // For now, skip author extraction as it's tricky
    
    // Date: look for 4-digit year
    var date: String? = nil
    for line in lines.prefix(10) {
      if let match = line.range(of: "\\b(19|20)\\d{2}\\b", options: .regularExpression) {
        date = String(line[match])
        break
      }
    }
    
    return Meta(title: title, auths: authors, date: date)
  }
  
  // MARK: - Section Parsing
  
  private struct ParsedSections {
    var sections: [Sec]
    var sentences: [Sent]
  }
  
  private static func parseSections(from text: String) -> ParsedSections {
    var sections: [Sec] = []
    var sentences: [Sent] = []
    
    let paragraphs = text.components(separatedBy: .newlines).filter {
      !$0.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    // Section header patterns
    let sectionPatterns: [(pattern: String, kind: String)] = [
      ("^\\s*abstract\\s*:?\\s*$", "body"),
      ("^\\s*introduction\\s*:?\\s*$", "body"),
      ("^\\s*background\\s*:?\\s*$", "body"),
      ("^\\s*methods?\\s*:?\\s*$", "body"),
      ("^\\s*methodology\\s*:?\\s*$", "body"),
      ("^\\s*results?\\s*:?\\s*$", "body"),
      ("^\\s*discussion\\s*:?\\s*$", "body"),
      ("^\\s*conclusions?\\s*:?\\s*$", "body"),
      ("^\\s*(references?|bibliography|works cited)\\s*:?\\s*$", "bib"),
      ("^\\s*appendi(x|ces)\\s*:?\\s*$", "appendix"),
      ("^\\s*policy highlights?\\s*:?\\s*$", "body")
    ]
    
    var currentSection: (id: String, title: String, kind: String, sentIds: [String]) =
      ("main", "Main Content", "body", [])
    var sectionIndex = 0
    var skipNextParagraphs = 0
    
    for (paraIndex, para) in paragraphs.enumerated() {
      if skipNextParagraphs > 0 {
        skipNextParagraphs -= 1
        continue
      }
      
      let trimmed = para.trimmingCharacters(in: .whitespaces)
      
      // Skip very short paragraphs that might be metadata
      if trimmed.count < 15 { continue }
      
      // Skip figure captions
      if trimmed.lowercased().hasPrefix("figure") ||
         trimmed.lowercased().hasPrefix("fig.") ||
         trimmed.lowercased().hasPrefix("table") {
        continue
      }
      
      // Check if this is a section header
      let lowerPara = trimmed.lowercased()
      var isHeader = false
      var headerTitle = ""
      var headerKind = "body"
      
      for (pattern, kind) in sectionPatterns {
        if let _ = lowerPara.range(of: pattern, options: .regularExpression) {
          isHeader = true
          headerTitle = trimmed
          headerKind = kind
          break
        }
      }
      
      // Also detect headers by format: short, title case, ends with colon
      if !isHeader && trimmed.count < 50 && trimmed.hasSuffix(":") {
        isHeader = true
        headerTitle = trimmed
        headerKind = "body"
      }
      
      if isHeader {
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
        
        // Start new section
        sectionIndex += 1
        currentSection = (
          id: "sec\(sectionIndex)",
          title: headerTitle.replacingOccurrences(of: ":", with: ""),
          kind: headerKind,
          sentIds: []
        )
      } else {
        // Regular paragraph - split into sentences
        let sents = splitIntoSentences(trimmed)
        
        for sentence in sents {
          // Skip very short sentences (likely fragments)
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
    
    // Add final section
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
    // Split on sentence-ending punctuation followed by space and capital letter
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
      let sentence = nsString.substring(with: NSRange(location: lastEnd, length: end - lastEnd))
        .trimmingCharacters(in: .whitespacesAndNewlines)
      
      if !sentence.isEmpty && sentence.count > 10 {
        sentences.append(sentence)
      }
      lastEnd = end
    }
    
    // Add remaining text
    if lastEnd < nsString.length {
      let remaining = nsString.substring(from: lastEnd).trimmingCharacters(in: .whitespacesAndNewlines)
      if !remaining.isEmpty && remaining.count > 10 {
        sentences.append(remaining)
      }
    }
    
    // If no sentences were found, return the whole text
    return sentences.isEmpty ? [text] : sentences
  }
  
  // MARK: - Figure Extraction
  
  private static func extractFigureReferences(from text: String) -> [String] {
    let pattern = "(?i)fig(?:ure|\\.)?\\s*(\\d+[a-z]?)"
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
    
    let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
    
    return matches.compactMap { match in
      guard match.numberOfRanges > 1 else { return nil }
      let numberRange = Range(match.range(at: 1), in: text)
      guard let range = numberRange else { return nil }
      return "Figure \(text[range])"
    }
  }
  
  private static func extractFigures(from text: String) -> [Fig] {
    // Look for figure captions
    let pattern = "(?i)(fig(?:ure|\\.)?\\s*\\d+[a-z]?)[:.]?\\s*([^\n]+)"
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
    
    let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
    
    var figures: [Fig] = []
    
    for match in matches {
      guard match.numberOfRanges > 2 else { continue }
      
      let labelRange = Range(match.range(at: 1), in: text)
      let captionRange = Range(match.range(at: 2), in: text)
      
      guard let lr = labelRange, let cr = captionRange else { continue }
      
      let label = String(text[lr]).trimmingCharacters(in: .whitespacesAndNewlines)
      let caption = String(text[cr]).trimmingCharacters(in: .whitespacesAndNewlines)
      
      figures.append(Fig(
        id: label,
        label: label,
        url: "", // TODO: Extract actual image
        cap: caption
      ))
    }
    
    return figures
  }
}
