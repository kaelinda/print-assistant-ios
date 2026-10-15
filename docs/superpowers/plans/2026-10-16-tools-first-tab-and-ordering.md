# Tools First Tab and Group Ordering Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make 工具 the first and default tab, and add a native grouped editor that persists tool order within each existing group.

**Architecture:** Move the tool list from view-local closures into a stable `ToolCatalog` keyed by `ToolID`. Store only versioned string IDs in `ToolOrderStore`, normalize them against the catalog’s fixed group membership, and let `ToolsView` render the normalized order. Push a dedicated `ToolOrderEditorView` through the existing `NavigationStack`; edits stay local until 完成 is tapped.

**Tech Stack:** Swift 6, SwiftUI iOS 17, Observation, `UserDefaults` + Codable, XCTest/XCTest UI tests.

---

### Task 1: Add stable tool catalog and order persistence

**Files:**
- Create: `PrintAssistant/App/ToolCatalog.swift`
- Create: `PrintAssistant/Infrastructure/ToolOrderStore.swift`
- Modify: `PrintAssistant.xcodeproj/project.pbxproj` to add both files to the app target’s groups and Sources build phase
- Test: `PrintAssistantTests/ToolOrderStoreTests.swift`
- Modify: `PrintAssistant.xcodeproj/project.pbxproj` to add the new test file to the unit-test target’s group and Sources build phase

- [ ] **Step 1: Write failing persistence tests**

  Cover these behaviors with an injected `UserDefaults(suiteName:)`: defaults return all current tools in their documented group order; unknown IDs and duplicate IDs are removed; missing IDs are appended from defaults; IDs stored under another group are rejected; corrupt data and unsupported versions fall back to defaults; a saved normalized order can be loaded back.

- [ ] **Step 2: Run the focused tests to verify the expected failure**

  Run:

  ```bash
  xcodebuild test -project PrintAssistant.xcodeproj -scheme PrintAssistant \
    -destination 'platform=iOS Simulator,id=241BA703-63E1-41DB-87DE-BF468B93F769' \
    -derivedDataPath build/DerivedData \
    -only-testing:PrintAssistantTests/ToolOrderStoreTests
  ```

  Expected: compile/test failure because `ToolOrderStore` and the catalog do not exist.

- [ ] **Step 3: Implement the minimal catalog and store**

  Define `ToolID` as a `String`-backed `Hashable`/`CaseIterable` enum, `ToolGroup` as a `String`-backed enum with the three fixed groups, and `ToolCatalog` as the single runtime registry for title keys, subtitles, SF Symbols, tint, group, and `AppModel.Route` mapping. Keep navigation actions out of persistence.

  Define `ToolOrderStore` with key `print-assistant.tool-order`, payload version `1`, injected `UserDefaults`, `load()` and `save(_:)`. Decode raw strings so unknown future IDs do not invalidate the whole payload. Normalize each group by filtering valid membership, de-duplicating while preserving order, and appending missing defaults. Unsupported versions or decode failures return defaults.

- [ ] **Step 4: Run the focused tests to verify green**

  Run the same `xcodebuild test` command from Step 2. Expected: all store tests pass.

- [ ] **Step 5: Commit the isolated data layer**

  ```bash
  git add PrintAssistant/App/ToolCatalog.swift PrintAssistant/Infrastructure/ToolOrderStore.swift PrintAssistantTests/ToolOrderStoreTests.swift PrintAssistant.xcodeproj/project.pbxproj
  git commit -m "feat: add persistent tool ordering model"
  ```

### Task 2: Make tools the first tab and route the editor

**Files:**
- Modify: `PrintAssistant/App/AppModel.swift`
- Modify: `PrintAssistant/App/PrintAssistantApp.swift`
- Modify: `PrintAssistant/App/AppRootView.swift`
- Modify: `PrintAssistant/DesignSystem/GlassControls.swift`
- Test: `PrintAssistantTests/AppModelWorkTests.swift` or a focused AppModel test in `ToolOrderStoreTests.swift`

- [ ] **Step 1: Add the failing navigation assertions**

  Assert that a new `AppModel` starts with `.tools` selected and that pushing `.toolOrderEditor` is a valid route. Keep the route equatable/hashable through the existing enum.

- [ ] **Step 2: Run the focused test and verify it fails**

  Run:

  ```bash
  xcodebuild test -project PrintAssistant.xcodeproj -scheme PrintAssistant \
    -destination 'platform=iOS Simulator,id=241BA703-63E1-41DB-87DE-BF468B93F769' \
    -derivedDataPath build/DerivedData \
    -only-testing:PrintAssistantTests/AppModelWorkTests
  ```

  Expected: the default-tab assertion fails and the route is unavailable.

- [ ] **Step 3: Implement the navigation changes**

  Change `selectedTab`’s default to `.tools`, add `.toolOrderEditor` to `AppModel.Route`, render `ToolOrderEditorView()` in `AppRootView.navigationDestination`, and reorder `GlassTabBar` buttons to tools, recent, files. Keep search as the independent circular button and keep accessibility identifiers unchanged. In `PrintAssistantApp`, recognize `-UITestResetToolOrder` and remove `ToolOrderStore.storageKey` before creating the app model so UI tests can isolate defaults without changing production behavior.

- [ ] **Step 4: Run the focused navigation tests**

  Run the same command from Step 2. Expected: all selected tests pass.

- [ ] **Step 5: Commit the navigation change**

  ```bash
  git add PrintAssistant/App/AppModel.swift PrintAssistant/App/PrintAssistantApp.swift PrintAssistant/App/AppRootView.swift PrintAssistant/DesignSystem/GlassControls.swift PrintAssistantTests/AppModelWorkTests.swift
  git commit -m "feat: promote tools to the primary tab"
  ```

### Task 3: Render the ordered tools and add the native editor

**Files:**
- Modify: `PrintAssistant/Features/OCR/ToolsView.swift`
- Create: `PrintAssistant/Features/OCR/ToolOrderEditorView.swift`
- Modify: `PrintAssistant.xcodeproj/project.pbxproj` to add the editor view to the app target’s group and Sources build phase
- Modify: `PrintAssistant/Localizable.xcstrings` with Chinese and English entries for all new ordering copy

- [ ] **Step 1: Add view-level failing coverage**

  Extend the UI test to launch into 工具, open “调整顺序”, verify the navigation title and helper copy, and verify all three group headers. Add an accessibility identifier and descriptive VoiceOver label/hint to the editor entry button and each reorder row. Treat the native `List` handle and reorder action as system-provided; assert the stable row identifiers/labels and group-local row membership without depending on private handle identifiers or screen coordinates.

- [ ] **Step 2: Run the UI test before implementation**

  Run:

  ```bash
  xcodebuild test -project PrintAssistant.xcodeproj -scheme PrintAssistant \
    -destination 'platform=iOS Simulator,id=241BA703-63E1-41DB-87DE-BF468B93F769' \
    -derivedDataPath build/DerivedData \
    -only-testing:PrintAssistantUITests/PrintAssistantUITests/testToolOrderEditorScreenRenders
  ```

  Expected: failure because the editor button, route, and screen do not exist.

- [ ] **Step 3: Refactor `ToolsView` to use catalog IDs**

  Replace the private closure-based `ToolDefinition` arrays with the normalized order from an injected `ToolOrderStore` (production uses `UserDefaults.standard`; unit tests pass an isolated suite). Render each group through `ToolCatalog.entry(for:)`, dispatching the catalog route through `appModel.push`. Keep the existing `GlassCard`/`GlassActionRow` visual treatment and add a top-right “调整顺序” button with a stable accessibility identifier.

- [ ] **Step 4: Implement `ToolOrderEditorView`**

  Initialize a local normalized order snapshot from the injected store. Render `List` sections in the fixed group order with a row for each tool. Put the list in active edit mode so native reorder handles are visible; attach `.onMove` to each group’s `ForEach`, allowing moves only within that group. Give each row a stable identifier, visible label and VoiceOver hint; rely on the system `List` reorder action rather than a private custom handle. Use a navigation title, the “仅调整组内顺序” helper text, and a “完成” toolbar action. Save only from 完成, set the existing transient message, and pop the editor route. System back, the navigation-bar back button, and interactive side-swipe back all leave the store untouched.

- [ ] **Step 5: Run the UI test to verify green**

  Run the command from Step 2. Expected: the editor opens, shows all groups, exposes the native reorder handles through the system List, exposes stable row labels/hints, and keeps rows scoped to their original section.

- [ ] **Step 6: Commit the feature UI**

  ```bash
  git add PrintAssistant/Features/OCR/ToolsView.swift PrintAssistant/Features/OCR/ToolOrderEditorView.swift PrintAssistant/Localizable.xcstrings PrintAssistantUITests/PrintAssistantUITests.swift PrintAssistant.xcodeproj/project.pbxproj
  git commit -m "feat: add grouped tool ordering editor"
  ```

### Task 4: Verify cancellation, persistence, accessibility, and regression behavior

**Files:**
- Modify: `PrintAssistantUITests/PrintAssistantUITests.swift`
- Modify: `PrintAssistantTests/ToolOrderStoreTests.swift` if additional edge cases are needed

- [ ] **Step 1: Add behavioral checks**

  Cover a completed reorder surviving a fresh app launch, a navigation-bar back without saving, an interactive side-swipe back without saving, and a programmatic/system return without saving. Assert row accessibility labels/hints identify the group and tool, group membership stays fixed, and the tab test expects tools first/default. The app recognizes `-UITestResetToolOrder` and clears `ToolOrderStore.storageKey`; each test launches with that argument unless it is deliberately relaunching without it to verify persistence.

- [ ] **Step 2: Run focused unit and UI tests**

  ```bash
  xcodebuild test -project PrintAssistant.xcodeproj -scheme PrintAssistant \
    -destination 'platform=iOS Simulator,id=241BA703-63E1-41DB-87DE-BF468B93F769' \
    -derivedDataPath build/DerivedData \
    -only-testing:PrintAssistantTests/ToolOrderStoreTests \
    -only-testing:PrintAssistantUITests/PrintAssistantUITests/testMainTabsRenderAndNavigate \
    -only-testing:PrintAssistantUITests/PrintAssistantUITests/testToolOrderEditorScreenRenders
  ```

  Expected: all selected tests pass.

- [ ] **Step 3: Run the localization baseline separately**

  ```bash
  xcodebuild test -project PrintAssistant.xcodeproj -scheme PrintAssistant \
    -destination 'platform=iOS Simulator,id=241BA703-63E1-41DB-87DE-BF468B93F769' \
    -derivedDataPath build/DerivedData \
    -only-testing:PrintAssistantTests/LocalizationCatalogTests
  ```

  Expected: the newly added ordering strings are present in Chinese and English; any remaining failures are reported as the pre-existing catalog baseline and are not folded into this feature.

- [ ] **Step 4: Run the full regression suite**

  ```bash
  xcodebuild test -project PrintAssistant.xcodeproj -scheme PrintAssistant \
    -destination 'platform=iOS Simulator,id=241BA703-63E1-41DB-87DE-BF468B93F769' \
    -derivedDataPath build/DerivedData \
    -skip-testing:PrintAssistantTests/LocalizationCatalogTests
  ```

  Expected: build succeeds, all non-baseline unit/UI tests pass, and the existing localization-catalog baseline is reported separately if it still has unrelated missing translations.

- [ ] **Step 5: Build and launch the current app on the simulator**

  ```bash
  xcodebuild build -project PrintAssistant.xcodeproj -scheme PrintAssistant \
    -destination 'platform=iOS Simulator,id=241BA703-63E1-41DB-87DE-BF468B93F769' \
    -derivedDataPath build/DerivedData
  xcrun simctl install 241BA703-63E1-41DB-87DE-BF468B93F769 \
    build/DerivedData/Build/Products/Debug-iphonesimulator/PrintAssistant.app
  xcrun simctl launch 241BA703-63E1-41DB-87DE-BF468B93F769 com.kaelinda.printassistant
  ```

- [ ] **Step 6: Commit the verification updates**

  ```bash
  git add PrintAssistantTests/ToolOrderStoreTests.swift PrintAssistantUITests/PrintAssistantUITests.swift
  git commit -m "test: verify grouped tool ordering behavior"
  ```
