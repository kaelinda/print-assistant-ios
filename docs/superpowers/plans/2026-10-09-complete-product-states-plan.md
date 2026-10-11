# Print Assistant 完整产品状态与 App Icon Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete the missing Figma product states and ship a coherent App icon for the iOS app.

**Architecture:** Extend the existing explicit `AppModel.Route` state machine with focused feature views and small local persistence models. Reuse current PDF, document-library, PhotosUI, VisionKit, PDFKit, and UIKit adapters; keep system-owned surfaces native while matching the app’s Liquid Glass shell.

**Tech Stack:** Swift 6, SwiftUI, Observation, PDFKit, PhotosUI, VisionKit, UIKit, XcodeGen.

---

### Task 1: Add route data and local template models

**Files:**
- Create: `PrintAssistant/Domain/PrintTemplate.swift`
- Modify: `PrintAssistant/App/AppModel.swift`
- Modify: `PrintAssistant/App/AppRootView.swift`
- Test: `PrintAssistantTests/PrintTemplateTests.swift`

- [ ] Add Codable template fields for name, paper size, margin, scale, copies and category.
- [ ] Add routes for template center/editor/apply, batch processing, compression, protection, photo ID, image export, settings, privacy, feedback and clear-index confirmation.
- [ ] Add focused unit tests for template round-trip and default values.

### Task 2: Implement template center and settings surfaces

**Files:**
- Create: `PrintAssistant/Features/Templates/TemplateCenterView.swift`
- Create: `PrintAssistant/Features/Templates/TemplateEditorView.swift`
- Create: `PrintAssistant/Features/Templates/TemplateApplyView.swift`
- Create: `PrintAssistant/Features/Settings/SettingsView.swift`
- Create: `PrintAssistant/Features/Settings/PrivacyView.swift`
- Create: `PrintAssistant/Features/Settings/PrivacyPolicyView.swift`
- Create: `PrintAssistant/Features/Settings/FeedbackView.swift`
- Modify: `PrintAssistant/Features/OCR/ToolsView.swift`

- [ ] Add template list/filter chips with the Figma copy and sample presets.
- [ ] Make template editor save to local JSON and allow applying a template to a selected PDF/image workflow.
- [ ] Add settings entry, privacy details, feedback composer, and clear-index confirmation with explicit toast/error states.

### Task 3: Implement compression and password protection workflows

**Files:**
- Create: `PrintAssistant/Features/PDFTools/PDFCompressionSourceView.swift`
- Create: `PrintAssistant/Features/PDFTools/PDFCompressionProcessingView.swift`
- Create: `PrintAssistant/Features/PDFTools/PDFCompressionSuccessView.swift`
- Create: `PrintAssistant/Features/PDFTools/PDFProtectionSourceView.swift`
- Create: `PrintAssistant/Features/PDFTools/PDFProtectionView.swift`
- Create: `PrintAssistant/Features/PDFTools/PDFProtectionSuccessView.swift`
- Modify: `PrintAssistant/App/AppModel.swift`
- Modify: `PrintAssistant/App/AppRootView.swift`
- Modify: `PrintAssistant/Features/OCR/ToolsView.swift`

- [ ] Add source selection for library PDFs and external PDFs.
- [ ] Connect existing `PDFCompressionService` and `PDFProtectionService`.
- [ ] Register generated documents with correct identity and preserve sources.
- [ ] Expose invalid-password and already-protected states with retry/back recovery.

### Task 4: Implement batch processing and image export

**Files:**
- Create: `PrintAssistant/Domain/BatchJob.swift`
- Create: `PrintAssistant/Features/Batch/BatchSelectionView.swift`
- Create: `PrintAssistant/Features/Batch/BatchProcessingView.swift`
- Create: `PrintAssistant/Features/Batch/BatchSuccessView.swift`
- Create: `PrintAssistant/Features/PhotoPDF/ImageExportView.swift`
- Modify: `PrintAssistant/App/AppModel.swift`
- Modify: `PrintAssistant/App/AppRootView.swift`
- Modify: `PrintAssistant/Features/OCR/ToolsView.swift`
- Test: `PrintAssistantTests/BatchJobTests.swift`

- [ ] Add multi-file selection from library and Files.
- [ ] Process one file at a time with progress, cancellation-safe state and partial-result recovery.
- [ ] Export PDF pages to Photos with Photos permission fallback.

### Task 5: Implement photo ID workflow

**Files:**
- Create: `PrintAssistant/Domain/PhotoIDModels.swift`
- Create: `PrintAssistant/Features/PhotoID/PhotoIDSourceView.swift`
- Create: `PrintAssistant/Features/PhotoID/PhotoIDCropView.swift`
- Create: `PrintAssistant/Features/PhotoID/PhotoIDSuccessView.swift`
- Modify: `PrintAssistant/App/AppModel.swift`
- Modify: `PrintAssistant/App/AppRootView.swift`
- Modify: `PrintAssistant/Features/OCR/ToolsView.swift`

- [ ] Support photo picker and camera source.
- [ ] Provide aspect-ratio crop/alignment controls and generate an A4 sheet.
- [ ] Register the generated file and expose preview/share/return actions.

### Task 6: Add App icon assets

**Files:**
- Create: `PrintAssistant/Assets.xcassets/AppIcon.appiconset/Contents.json`
- Create: `PrintAssistant/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`
- Create: `PrintAssistant/Assets.xcassets/AppIcon.appiconset/AppIcon-1024-dark.png`
- Create: `PrintAssistant/Assets.xcassets/AppIcon.appiconset/AppIcon-1024-tinted.png`
- Modify: `project.yml`

- [ ] Create a flat, legible icon with one accent hue and no text.
- [ ] Provide the three iOS 18 icon appearances and wire the asset catalog to the target.

### Task 7: Verification and UI coverage

**Files:**
- Modify: `PrintAssistantUITests/PrintAssistantUITests.swift`
- Add or modify focused unit tests as needed.

- [ ] Cover new tool entries and settings/template entry.
- [ ] Run `git diff --check`.
- [ ] Run full Debug build.
- [ ] Run unit and UI tests on the iOS 26.5 simulator.
- [ ] Install and launch the app, then inspect the main navigation and App icon.
