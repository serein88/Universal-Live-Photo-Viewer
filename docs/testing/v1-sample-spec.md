# ULPV V1 Sample Specification

## Purpose
Define a stable sample structure and metadata manifest for V1 parser and acceptance verification.

## Scope
- iOS live photo samples: 3 groups
- Xiaomi motion photo samples: 3 files
- Normal non-live images: 6 files

## Directory Rule
- Root sample directory: `sample/`
- Keep original source files unchanged.
- Do not rename sample files after they are listed in manifest.

## Manifest File
- File path: `sample/v1-sample-manifest.csv`
- One row = one logical sample item.
- iOS row contains both image and video file names.
- Xiaomi/normal row keeps `video_file` empty when not applicable.

## Required Fields
The manifest must contain these columns:

1. `sample_id`
2. `vendor`
3. `category`
4. `is_live_expected`
5. `image_file`
6. `video_file`
7. `expected_type`
8. `pair_group`
9. `notes`

## Value Constraints
- `vendor`: `ios` / `xiaomi` / `generic`
- `category`: `live` / `normal`
- `is_live_expected`: `true` / `false`
- `expected_type`: `ios` / `motionPhoto` / `unknown`
- `pair_group`: required for iOS paired files, empty otherwise

## Acceptance Mapping
- Parser match expectation comes from `is_live_expected`.
- Parser type expectation comes from `expected_type`.
- Pair matching expectation comes from `pair_group` + `video_file`.
- Failure triage uses `sample_id` as unique key.

