# Figma-inspired Print Assistant Icon

## Goal

Create a product-ready iOS app icon for Print Assistant with a restrained, Figma-inspired geometric language. The icon should communicate document handling while staying recognizable at small sizes.

## Direction

Use a single white document card as the dominant silhouette. Place three equal rounded color modules along its left edge to create a compact, collaborative-design-tool rhythm. Keep the palette to coral, orange, and violet with a muted lavender canvas. Remove the printer body, plus symbol, background circles, and internal document copy from the previous exploration.

## Geometry

- 1024 × 1024 square canvas.
- Full-bleed opaque soft lavender background; the iOS mask provides the final corner treatment.
- Centered white document card at `(300, 144)` with size `500 × 736` and corner radius `76`.
- Folded upper-right corner is `136 × 136`, rendered above the document body.
- Three equal circular modules are `136 × 136`, aligned at `x = 220`, with centers at `y = 286, 446, 606`; they overlap the document by 68 px and render above it.
- One dark horizontal bar at `(428, 350)` with size `188 × 26` and radius `13` preserves a document cue without introducing text.
- Keep every colored module and the document body at least 96 px from the canvas edge to preserve iOS safe-area breathing room.
- No visible wordmark, letter, label, watermark, or direct Figma logo recreation.

## Color and finish

- Background: soft lavender `#F5F3FF`.
- Modules: coral `#F15B5D`, orange `#FF9E42`, violet `#7056E8`.
- Document: white with a subtle cool-lavender fold.
- Content bar: deep slate `#30324A`.
- Use one restrained shadow under the document only. Avoid gradients, background circles, a printer body, a plus symbol, a fourth module, extra content bars, and excessive depth.

## Existing asset plan

The final rasterized variants replace the current app icon files in `PrintAssistant/Assets.xcassets/AppIcon.appiconset/`:

- `AppIcon.png`: full-color variant.
- `AppIcon-dark.png`: same three-module silhouette on a deep slate background, preserving the white document and using slightly brighter module colors.
- `AppIcon-tinted.png`: monochrome-compatible silhouette with the document and modules rendered as a single neutral shape for iOS tinted mode.

The SVG is the source of truth. Rasterize it at 1024 × 1024 with `rsvg-convert`, then export the dark and tinted variants from the same geometry. Keep `Contents.json` unchanged so Xcode continues selecting the three appearance variants.

The existing exploratory files in `output/icon/print-assistant-figma-inspired.svg` and `.png` are superseded by the final source and should be overwritten after implementation; their current extra circles, blue module, printer tray, plus sign, and multiple bars are not part of this direction.

## Deliverables

- Editable SVG source.
- 1024 × 1024 PNG preview and the three Xcode AppIcon raster variants.
- Visual check using `rsvg-convert` output resized to 180 × 180 and 60 × 60, viewed at 100% on a neutral background.
- At 180 px, the document silhouette, fold, and all three modules must be distinct with no merged edges.
- At 60 px, the document silhouette and the three-color vertical rhythm must remain recognizable; the internal bar may be secondary but must not create visual noise.
- Verify the icon in light, dark, and tinted appearance modes through the simulator home screen or Xcode asset preview.
