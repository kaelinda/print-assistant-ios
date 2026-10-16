# Print Assistant for iOS

Apple-native document scanner, OCR, PDF and print assistant for iOS.

**Current release: 0.2.0**

## Included workflows

- Scan documents with VisionKit and export them as PDF.
- Import, merge, split, compress, protect and unlock PDF files.
- Recognize text from images and PDFs with Vision.
- Copy an ID card to A4 with front/back capture, layout preview and optional watermark text.
- Create one-inch ID photo layouts for printing.
- Organize tools from the first tab and edit the order within each group.
- Save generated files to the local library for preview, sharing and printing.

## Product principles

- Local-first document processing and privacy by default
- Apple-native interaction and system surfaces
- SwiftUI architecture with explicit state machines
- VisionKit / Vision / PDFKit for document workflows
- Accessibility, Dynamic Type and dark mode as release requirements
- Design-to-build consistency tracked against the Figma FINAL baseline

## Status

The `main` branch is the release baseline. Version 0.2.0 includes the ID-copy workflow, watermark support, editable tool ordering, refreshed AppIcon assets and the first production-oriented UI polish pass.

## Build and test

The project uses XcodeGen to generate the Xcode project:

```bash
xcodegen generate
xcodebuild build -project PrintAssistant.xcodeproj -scheme PrintAssistant -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
xcodebuild test -project PrintAssistant.xcodeproj -scheme PrintAssistant -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

The app is local-first and does not upload documents or OCR content to a server.
