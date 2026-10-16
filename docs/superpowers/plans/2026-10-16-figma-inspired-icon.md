# Figma-inspired Print Assistant Icon Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Replace the exploratory app icon with a restrained, product-ready document mark that remains recognizable in light, dark, and tinted iOS appearances.

**Architecture:** Keep one editable SVG as the geometry source of truth. Rasterize the shared geometry into the existing universal, dark, and tinted AppIcon PNG slots, leaving `Contents.json` unchanged. Validate the raster output at 1024 px, 180 px, and 60 px before building the app.

**Tech Stack:** SVG, `rsvg-convert`, ImageMagick/Pillow for raster inspection, Xcode asset catalogs, `xcodebuild`.

---

### Task 1: Replace the exploratory SVG with the approved minimalist geometry

**Files:**
- Modify: `output/icon/print-assistant-figma-inspired.svg`

- [x] **Step 1: Write the approved geometry**

  Use a full-bleed `#F5F3FF` background, a centered white document card at `(300,144)` sized `500 × 736`, a `136 × 136` folded corner, three `136 × 136` circular modules at `x=220` and `y=286/446/606`, and one dark content bar at `(428,350)` sized `188 × 26`. Add one restrained document-only shadow (`dy=18`, `stdDeviation=18`, `#4A3C85` at 14% opacity); do not add any other shadow or decoration.

- [x] **Step 2: Render the source at 1024 px**

  Run:

  ```bash
  rsvg-convert -w 1024 -h 1024 output/icon/print-assistant-figma-inspired.svg -o output/icon/print-assistant-figma-inspired.png
  ```

  Expected: the PNG renders without transparent corners, background circles, printer body, plus symbol, fourth module, or extra content bars.

### Task 2: Generate the three Xcode AppIcon variants

**Files:**
- Modify: `PrintAssistant/Assets.xcassets/AppIcon.appiconset/AppIcon.png`
- Modify: `PrintAssistant/Assets.xcassets/AppIcon.appiconset/AppIcon-dark.png`
- Modify: `PrintAssistant/Assets.xcassets/AppIcon.appiconset/AppIcon-tinted.png`

- [x] **Step 1: Export the full-color variant**

  Copy the approved 1024 px raster output to `AppIcon.png`.

- [x] **Step 2: Create the dark variant from the same geometry**

  Preserve the document/module silhouette, use canvas `#171827`, document `#FFFFFF`, fold `#4B4774`, content bar `#24263B`, and modules `#FF6A6C`, `#FFAD59`, and `#8A73FF`. Export as `AppIcon-dark.png`.

- [x] **Step 3: Create the tinted variant from the same geometry**

  Preserve the silhouette and simplify every foreground element to a single neutral tone suitable for iOS tinted rendering. Export as `AppIcon-tinted.png`.

- [x] **Step 4: Confirm asset catalog metadata**

  Run:

  ```bash
  cat PrintAssistant/Assets.xcassets/AppIcon.appiconset/Contents.json
  ```

  Expected: the existing universal, dark, and tinted entries remain unchanged and point to the three generated filenames.

### Task 3: Verify visual quality and app integration

**Files:**
- Create: `output/icon/check-180.png`
- Create: `output/icon/check-60.png`

- [x] **Step 1: Render inspection sizes**

  Resize the full-color PNG to 180 × 180 and 60 × 60 on a neutral background.

- [x] **Step 2: Inspect acceptance criteria**

  Resize all three variants to 180 × 180 and 60 × 60. At 180 px, the light and dark variants must show a distinct document, fold, and three modules; the tinted variant must show a distinct document silhouette and module rhythm as one neutral tone. At 60 px, the light and dark variants must retain the document silhouette and three-color vertical rhythm, while the tinted variant must retain only the silhouette and module rhythm without claiming color separation. No variant may show noisy internal detail.

- [x] **Step 3: Build the app**

  Run:

  ```bash
  xcodebuild build -project PrintAssistant.xcodeproj -scheme PrintAssistant -destination 'platform=iOS Simulator,id=241BA703-63E1-41DB-87DE-BF468B93F769' -derivedDataPath build/DerivedData
  ```

  Expected: `BUILD SUCCEEDED`.

- [x] **Step 4: Inspect the simulator home screen**

  Install and launch the built app, then verify the icon appears in light, dark, and tinted appearance previews where supported.

- [x] **Step 5: Commit the icon asset change**

  ```bash
  git add output/icon PrintAssistant/Assets.xcassets/AppIcon.appiconset
  git commit -m "feat: simplify app icon geometry"
  ```
