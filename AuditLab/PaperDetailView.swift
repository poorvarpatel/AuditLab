//
//  PaperDetailView.swift
//  AuditLab
//
//  Created by Poorva Patel on 2/7/26.
//

internal import SwiftUI

struct PaperDetailView: View {
  @Environment(\.dismiss) private var dis
  @EnvironmentObject var q: QueueStore
  @EnvironmentObject var lib: LibStore

  let rec: PaperRec

  var body: some View {
    NavigationStack {
      Group {
        if lib.loadingPackId == rec.id {
          loadingView
        } else if let pack = lib.getPack(id: rec.id) {
          detailContent(pack: pack)
        } else {
          unableToLoadView
        }
      }
      .padding(16)
      .navigationTitle(rec.title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") { dis() }
            .accessibilityIdentifier("document-detail-done")
        }
      }
      .onAppear { lib.ensurePackLoaded(id: rec.id) }
    }
  }

  private var loadingView: some View {
    VStack(spacing: 16) {
      ProgressView()
        .scaleEffect(1.2)
      Text("Loading document…")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Loading document")
    .accessibilityIdentifier("document-detail-loading")
  }

  private func detailContent(pack: ReadPack) -> some View {
    let meta = pack.meta
    return ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        // Metadata (AC1): title, authors, date
        VStack(alignment: .leading, spacing: 8) {
          Text(meta.title.isEmpty ? rec.title : meta.title)
            .font(.title3.weight(.semibold))
            .lineLimit(3)
            .accessibilityIdentifier("document-detail-title")
          Text(metadataSubtitle(meta))
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .accessibilityIdentifier("document-detail-metadata")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("document-detail-metadata-section")

        // Section structure (AC1): section titles and optionally kind
        if !pack.secs.isEmpty {
          VStack(alignment: .leading, spacing: 8) {
            Text("Sections")
              .font(.headline)
              .accessibilityIdentifier("document-detail-sections-header")
            VStack(spacing: 0) {
              ForEach(pack.secs) { sec in
                HStack {
                  Text(sec.title)
                    .lineLimit(1)
                    .accessibilityIdentifier("document-detail-section-title")
                  Spacer()
                  Text(sec.kind)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("document-detail-section-kind")
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(sec.title), \(sec.kind)")
                if sec.id != pack.secs.last?.id {
                  Divider()
                }
              }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .accessibilityIdentifier("document-detail-sections-list")
          }
          .accessibilityElement(children: .contain)
          .accessibilityIdentifier("document-detail-sections-section")
        }

        Spacer(minLength: 20)

        Button("Add to Queue") {
          q.add(pack.defaultQItem())
          dis()
        }
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier("document-detail-add-to-queue")

        Button("Play Now") {
          let it = pack.defaultQItem()
          q.add(it)
          q.idx = max(0, q.items.count - 1)
          dis()
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier("document-detail-play-now")
      }
    }
  }

  private var unableToLoadView: some View {
    VStack(spacing: 12) {
      Text("Unable to load document")
        .font(.headline)
      Text("Metadata and sections could not be loaded.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Unable to load document. Metadata and sections could not be loaded.")
    .accessibilityIdentifier("document-detail-unable-to-load")
  }

  private func metadataSubtitle(_ meta: Meta) -> String {
    var out: [String] = []
    if !meta.auths.isEmpty {
      if meta.auths.count <= 3 {
        out.append(meta.auths.joined(separator: ", "))
      } else {
        out.append("\(meta.auths[0]) et al.")
      }
    }
    if let d = meta.date { out.append(d) }
    if out.isEmpty { return "No metadata available" }
    return out.joined(separator: " • ")
  }
}
