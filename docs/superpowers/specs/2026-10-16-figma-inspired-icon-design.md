# Centered Color-Block App Icon

## Goal

Create a product-ready iOS app icon for Print Assistant with a centered, Figma-inspired rhythm of rounded color blocks. The icon should be instantly recognizable as a design-tool mark while remaining an original composition.

## Direction

Use five rounded square modules centered on an opaque soft-lavender canvas. The first two rows contain two modules each; the third row contains one module aligned to the left column. Use coral, orange, violet, blue, and mint in that order. Remove the previous document and printer metaphors so the mark stays minimal at small sizes.

## Geometry

- 1024 × 1024 square canvas with full-bleed background `#F7F5FF`.
- Each module is `164 × 164` with a `62` px corner radius.
- Module positions are `(330,242)`, `(530,242)`, `(330,430)`, `(530,430)`, and `(330,618)`.
- Horizontal and vertical gaps are `36` px and `24` px respectively.
- The overall bounding box is centered on the 1024 px canvas.
- No shadows, text, wordmark, document outline, printer symbol, or direct Figma logo recreation.

## Color and appearance variants

- Light: coral `#F25B62`, orange `#FF9F43`, violet `#7056E8`, blue `#32A7E9`, mint `#2BCB9C`.
- Dark: canvas `#171827`, modules `#FF6A72`, `#FFB15C`, `#8A73FF`, `#53B9F5`, `#43D8B0`.
- Tinted: canvas `#E4E1FF`, all modules `#4B4774`.

The editable SVG is the source of truth for geometry. Rasterize each variant at 1024 × 1024 with `rsvg-convert` and replace the existing files in `PrintAssistant/Assets.xcassets/AppIcon.appiconset/` without changing `Contents.json`.

## Acceptance criteria

- The five-module composition is visually centered with at least 242 px top and bottom breathing room.
- At 180 px, all module boundaries and color order remain distinct.
- At 60 px, the two-column rhythm and single lower-left module remain recognizable without visual noise.
- Light, dark, and tinted assets retain identical geometry and differ only in the defined palette.
- The iOS asset catalog builds successfully and the new icon appears on the simulator home screen.
