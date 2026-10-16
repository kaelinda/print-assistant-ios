# Centered Color-Block App Icon

## Goal

Create a product-ready iOS app icon for Print Assistant with a centered, Figma-inspired rhythm of rounded color blocks. The icon should be instantly recognizable as a design-tool mark while remaining an original composition.

## Direction

Use a central violet rounded module with a small white focus dot, surrounded by four rounded color modules placed at the cardinal directions. Use coral at the top, orange at the right, mint at the bottom, and blue at the left. This creates an original focus-mark composition while preserving the colorful geometric language.

## Geometry

- 1024 × 1024 square canvas with full-bleed background `#F7F5FF`.
- Outer modules are `152 × 152` with a `58` px corner radius at `(436,220)`, `(652,436)`, `(436,652)`, and `(220,436)`.
- The center module is `196 × 196` with a `72` px corner radius at `(414,414)`.
- The white focus dot is a 34 px radius circle centered at `(512,512)`.
- The overall cross composition is centered on the 1024 px canvas with no shadows or overlap.
- No text, wordmark, document outline, printer symbol, or direct Figma logo recreation.

## Color and appearance variants

- Light: coral `#F25B62`, orange `#FF9F43`, violet `#7056E8`, blue `#32A7E9`, mint `#2BCB9C`.
- Dark: canvas `#171827`, modules `#FF6A72`, `#FFB15C`, `#8A73FF`, `#53B9F5`, `#43D8B0`.
- Tinted: canvas `#E4E1FF`, all modules `#4B4774`.

The editable SVG is the source of truth for geometry. Rasterize each variant at 1024 × 1024 with `rsvg-convert` and replace the existing files in `PrintAssistant/Assets.xcassets/AppIcon.appiconset/` without changing `Contents.json`.

## Acceptance criteria

- The five-module cross is visually centered with at least 220 px top and bottom breathing room.
- At 180 px, all module boundaries, the central focus dot, and color order remain distinct.
- At 60 px, the cross rhythm and central focus dot remain recognizable without visual noise.
- Light, dark, and tinted assets retain identical geometry and differ only in the defined palette.
- The iOS asset catalog builds successfully and the new icon appears on the simulator home screen.
