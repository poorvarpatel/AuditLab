# Deployment Configuration – AuditLab

**Generated:** 2026-03-02 (Deep Scan – Step 6)

## Build configuration

- **Product:** AuditLab.app (com.apple.product-type.application).
- **Platform:** iOS (iphoneos).
- **Deployment target:** IPHONEOS_DEPLOYMENT_TARGET = 26.1.
- **Configurations:** Debug, Release (from project.pbxproj).

## Signing

- **Development team:** Set in Xcode project (DEVELOPMENT_TEAM = 3L3LK8HZ46). Replace with your team ID for local and App Store builds.
- **Capabilities:** Not enumerated in scanned project; configure in Xcode (Signing & Capabilities) if needed (e.g. iCloud, push).

## CI/CD

- No `.github/workflows/`, `.gitlab-ci.yml`, Fastlane, or other CI config in the **app** tree.
- Optional: add a workflow to build with `xcodebuild` and archive for TestFlight/App Store.

## Distribution

- Standard iOS app distribution via Xcode: Archive → Distribute App (App Store Connect, Ad Hoc, Enterprise).
- No Docker or backend deployment (app-only).
