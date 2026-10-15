# 身份证复印水印 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users edit a default ID-copy watermark and include the same diagonal watermark pattern in the layout preview and generated A4 PDF.

**Architecture:** Keep the watermark value on the value-type `IDCopyDraft`, add shared constants and normalization in the ID-copy domain model, and pass an updated draft from the layout screen to the existing generating route. Render the watermark through one deterministic layout definition in the PDF service and mirror the same pattern in SwiftUI preview.

**Tech Stack:** Swift 6, SwiftUI, PDFKit, UIKit/Core Graphics, Swift Testing.

---

### Task 1: Define watermark data and failing domain tests

**Files:**
- Modify: `PrintAssistant/Domain/IDCopyModels.swift`
- Modify: `PrintAssistantTests/IDCopyGeometryTests.swift`

- [ ] **Step 1: Write failing tests** for the localized default text, 40-character truncation, and whitespace-only normalization.
- [ ] **Step 2: Run the focused tests** with `xcodebuild test -project PrintAssistant.xcodeproj -scheme PrintAssistant -destination 'platform=iOS Simulator,id=241BA703-63E1-41DB-87DE-BF468B93F769' -only-testing:PrintAssistantTests/IDCopyGeometryTests` and confirm the new assertions fail because the model has no watermark behavior.
- [ ] **Step 3: Implement the minimal model API**: default `watermarkText`, shared layout constants, and a normalization helper that trims, truncates to 40 characters, and returns nil for empty text.
- [ ] **Step 4: Re-run the focused tests** and confirm they pass.

### Task 2: Add PDF watermark rendering with output regression tests

**Files:**
- Modify: `PrintAssistant/Infrastructure/PDFDocumentService.swift`
- Modify: `PrintAssistantTests/IDCopyPDFTests.swift`

- [ ] **Step 1: Write a failing test** that generates the same two-card draft with the default watermark and with an empty watermark, rasterizes both PDF pages at the same size, and asserts the rendered pixel data differs.
- [ ] **Step 2: Run the focused PDF test** and confirm it fails before watermark rendering exists.
- [ ] **Step 3: Implement the minimal renderer**: after drawing both ID images, draw the normalized text at the fixed 24 pt, 18% gray, -18° pattern using the fixed horizontal/vertical spacing; skip the layer for nil text.
- [ ] **Step 4: Re-run `IDCopyPDFTests`** and confirm all tests pass, including page size and missing-side cases.

### Task 3: Add editable layout UI and preserve the value through navigation

**Files:**
- Modify: `PrintAssistant/Features/IDCopy/IDCopyLayoutView.swift`
- Modify: `PrintAssistant/Features/IDCopy/IDCopyGeneratingView.swift` only if the generation call needs an explicit normalized value
- Modify: `PrintAssistant/Localizable.xcstrings`

- [ ] **Step 1: Add UI test coverage or a view-level test seam** for the default field label/value and the generate action passing the edited text; keep the test focused on route/data behavior rather than SwiftUI internals.
- [ ] **Step 2: Run the focused test and confirm it fails** because the layout screen has no watermark editor or updated draft handoff.
- [ ] **Step 3: Implement the layout UI** with a single-line, accessible text field initialized from the draft, a 40-character limit, a clearable value, and a preview overlay using the same constants as PDF rendering. On generate, copy the draft, write the normalized text, and push `.idCopyGenerating(updatedDraft)`.
- [ ] **Step 4: Add Chinese and English catalog entries** for the watermark field label, helper text, and default value, then build to verify catalog compilation.
- [ ] **Step 5: Run the focused unit tests and UI test target** and confirm the route still reaches the generating screen.

### Task 4: Full validation and simulator run

**Files:**
- Modify: none unless validation exposes an issue.

- [ ] **Step 1: Run all unit and UI tests** with the existing iPhone 17 Pro simulator destination.
- [ ] **Step 2: Build and launch the app** on the simulator, open 证件工具 → 身份证复印, and verify the editable default watermark and diagonal preview are visible before generation.
- [ ] **Step 3: Inspect the generated PDF** from the app library to confirm the watermark is visible and the page remains A4 with both ID-1 cards at actual size.
- [ ] **Step 4: Review `git diff` and `git status`**, ensuring only the watermark implementation, tests, localization, and plan/spec documentation changed.
