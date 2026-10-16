# Centered Color-Block App Icon Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the document-based app icon with an original centered focus-mark composition for all iOS appearance variants.

**Architecture:** Keep one editable SVG as the geometry source of truth. Generate light, dark, and tinted SVG variants by deterministic palette substitution, rasterize each to 1024 × 1024 PNG, and replace the existing AppIcon files while leaving `Contents.json` unchanged.

**Tech Stack:** SVG, `rsvg-convert`, ImageMagick, Xcode asset catalogs, `xcodebuild`.

---

### Task 1: Author the centered focus-mark geometry

**Files:**
- Modify: `output/icon/print-assistant-figma-inspired.svg`

- [x] **Step 1: Write the source geometry**

  Use a full-bleed `#F7F5FF` background, four `152 × 152` outer modules at the cardinal directions, one centered `196 × 196` violet module, and a 34 px white focus dot.

- [x] **Step 2: Render the light source**

  ```bash
  rsvg-convert -w 1024 -h 1024 output/icon/print-assistant-figma-inspired.svg -o output/icon/print-assistant-figma-inspired.png
  ```

### Task 2: Generate appearance variants and AppIcon assets

**Files:**
- Modify: `output/icon/print-assistant-figma-inspired-dark.svg`
- Modify: `output/icon/print-assistant-figma-inspired-tinted.svg`
- Modify: `PrintAssistant/Assets.xcassets/AppIcon.appiconset/AppIcon.png`
- Modify: `PrintAssistant/Assets.xcassets/AppIcon.appiconset/AppIcon-dark.png`
- Modify: `PrintAssistant/Assets.xcassets/AppIcon.appiconset/AppIcon-tinted.png`

- [x] **Step 1: Generate deterministic palette variants**

  Keep the geometry byte-for-byte identical and apply the documented dark and tinted palettes.

- [x] **Step 2: Rasterize and replace the three PNGs**

  Rasterize each SVG at 1024 × 1024 and copy the outputs to the existing AppIcon filenames.

- [x] **Step 3: Validate asset metadata**

  Confirm `Contents.json` still references the universal, dark, and tinted files.

### Task 3: Verify visual quality and integration

**Files:**
- Create: `output/icon/check-180.png`
- Create: `output/icon/check-60.png`

- [x] **Step 1: Render inspection sizes**

  Resize the light variant to 180 × 180 and 60 × 60 with ImageMagick and inspect both previews.

- [x] **Step 2: Build the app and asset catalog**

  ```bash
  xcodebuild build -project PrintAssistant.xcodeproj -scheme PrintAssistant -destination 'platform=iOS Simulator,id=241BA703-63E1-41DB-87DE-BF468B93F769' -derivedDataPath build/DerivedData
  ```

  Expected: `BUILD SUCCEEDED`.

- [x] **Step 3: Install and inspect the simulator home screen**

  Install the built app, return to the simulator home screen, and verify the centered color-block icon is visible.
