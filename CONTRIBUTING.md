# Contributing

## Branch model

- `main`: release baseline only
- `develop`: integrated, CI-green product baseline
- `feature/<task>`: one coherent user task or infrastructure change
- `fix/<problem>`: isolated defect correction

Do not develop directly on `main`.

## Pull requests

A PR should represent one reviewable vertical slice. Prefer a complete user task over a collection of unrelated screens.

Before merge:

- Xcode project generation succeeds
- iOS Simulator build succeeds
- automated tests succeed
- new async actions are single-flight
- generated/opened/shared/printed files retain the same document identity
- native iOS surfaces are used where the platform owns the interaction
- accessibility labels exist for icon-only primary controls
- known real-device gaps are tracked explicitly

Use **squash merge** into `develop` so the integration history stays task-oriented.

## Definition of Done

A feature is not "done" because the screen exists.

It is done when:

1. The user can discover the entry point.
2. The happy path reaches an explicit result.
3. Back/cancel/retry paths preserve user work where appropriate.
4. Processing cannot be submitted twice.
5. Data survives the lifecycle promised by the UI.
6. Automated evidence covers deterministic behavior.
7. Device-only behavior has an evidence issue/checklist.
8. The implementation is consistent with the Figma FINAL baseline.

## Architecture principles

- Local-first and privacy-preserving by default.
- Explicit state over hidden view mutation.
- Small platform adapters around VisionKit, Vision, PDFKit, PhotosUI and UIKit.
- Domain/file identity flows through navigation; never hardcode demo content into result screens.
- Prefer semantic system colors, materials, Dynamic Type and native system presentations.
- Avoid premature abstractions until at least two real call sites need them.
