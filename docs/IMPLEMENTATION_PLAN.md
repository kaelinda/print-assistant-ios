# Implementation plan

The Figma Design RC remains the visual and behavioral source of truth.

## Release gate

The app is not considered implementation-complete until build evidence exists for:

1. Core scan-to-print task completion
2. Correct file context through preview/share/print
3. Native Photos/Files/Share/Print/permission surfaces
4. Async single-flight behavior and recovery
5. Light/dark/Dynamic Type/accessibility parity
6. Error states that preserve user work

## Delivery order

### Milestone 1 — App foundation + scan-to-print
- App shell and navigation state
- Local document model
- VisionKit document scanner
- Scan review
- PDF generation
- Recent/file detail
- PDF preview
- Native Share and Print

### Milestone 2 — OCR
- Vision text recognition
- OCR camera/photos/files inputs
- Processing/result/copy/export states
- Search index

### Milestone 3 — document tools
- Photos → PDF
- ID front/back capture and A4 layout
- Batch processing
- PDF merge/split/compress/page management/protection

### Milestone 4 — validation
- XCUITest for five core journeys
- Snapshot tests
- Failure injection
- Accessibility checks
- Moderated usability evidence
