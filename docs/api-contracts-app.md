# API Contracts – app (AuditLab)

**Generated:** 2026-03-02 (Deep Scan – Step 4)

## Summary

This app does **not** expose or consume HTTP/REST/GraphQL APIs. All data is local.

## Local “contracts”

| Surface | Type | Description |
|---------|------|-------------|
| `PDFParser.parse(url: URL) async throws -> ReadPack` | Local PDF parsing | Parses a PDF file (local URL) into a `ReadPack` (sections, sentences, figures). |
| `LibStore`, `QueueStore`, `FoldStore`, `AppSet` | In-app state | ObservableObject stores; no network layer. |
| `SpchPlayer` | Playback | Consumes `ReadPack` and `AppSet` (e.g. words-per-second); uses AVSpeechSynthesizer. |

## Integration scan (mobile)

- **integration_scan_patterns:** No `*client.ts`, `*api.ts`, `fetch*.ts` (this is Swift; no TypeScript).
- **Result:** No remote API endpoints to document.
