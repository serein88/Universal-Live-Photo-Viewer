# ULPV V1 Foundation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the V1 technical foundation for ULPV with clear layer boundaries, adapter-based dependencies, and high-intensity test gates.

**Architecture:** Use a 4-layer structure (`UI -> Application -> Domain -> Data/Parser`) with one-way dependencies. Domain and Application stay plugin-agnostic through Ports; Data provides parser implementations and adapters. V1 supports iOS dual-file and Xiaomi/Google Motion Photo only.

**Tech Stack:** Flutter (Dart 3.x), `video_player`, `file_picker`, `ffmpeg_kit_flutter`, `xml`, `exif`, `flutter_test`

---

### Task 1: 项目骨架与测试基线

**Files:**
- Create: `lib/domain/.gitkeep`
- Create: `lib/application/.gitkeep`
- Create: `lib/data/.gitkeep`
- Create: `lib/ui/.gitkeep`
- Modify: `pubspec.yaml`
- Test: `test/smoke/project_bootstrap_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('project bootstrap smoke', () {
    expect(true, isTrue);
  });
}
```

**Step 2: Run test to verify it fails (before Flutter scaffold exists)**

Run: `flutter test test/smoke/project_bootstrap_test.dart -r expanded`
Expected: FAIL with missing Flutter project files (if scaffold not yet created)

**Step 3: Write minimal implementation**

- Initialize Flutter app in repo root if missing: `flutter create .`
- Create 4-layer placeholder directories and `.gitkeep` files.
- Add required dependencies in `pubspec.yaml`.

**Step 4: Run test to verify it passes**

Run: `flutter test test/smoke/project_bootstrap_test.dart -r expanded`
Expected: PASS

**Step 5: Commit**

```bash
git add pubspec.yaml lib/ test/smoke/project_bootstrap_test.dart
git commit -m "T2-1: bootstrap layered project skeleton"
```

---

### Task 2: Domain 层实体与解析接口

**Files:**
- Create: `lib/domain/live_photo_type.dart`
- Create: `lib/domain/live_photo_entity.dart`
- Create: `lib/domain/live_photo_parser.dart`
- Test: `test/domain/live_photo_entity_test.dart`
- Test: `test/domain/live_photo_parser_contract_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_live_photo_viewer/domain/live_photo_type.dart';

void main() {
  test('live photo types include v1 and future vendors', () {
    expect(LivePhotoType.values.map((e) => e.name), containsAll(['ios', 'motionPhoto', 'vivo', 'huawei', 'oppo']));
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/domain/live_photo_entity_test.dart -r expanded`
Expected: FAIL with missing type/entity definitions

**Step 3: Write minimal implementation**

- Add `LivePhotoType` enum including V1 and future placeholders.
- Add immutable `LivePhotoEntity` with temp-file cleanup contract.
- Add `LivePhotoParser` abstract interface with `match` and `parse`.

**Step 4: Run test to verify it passes**

Run: `flutter test test/domain -r expanded`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/domain test/domain
git commit -m "T2-1: add domain entities and parser contract"
```

---

### Task 3: Application 层 Ports 与用例编排

**Files:**
- Create: `lib/application/ports/file_system_port.dart`
- Create: `lib/application/ports/media_picker_port.dart`
- Create: `lib/application/ports/video_playback_port.dart`
- Create: `lib/application/ports/export_port.dart`
- Create: `lib/application/use_cases/scan_live_photos_use_case.dart`
- Create: `lib/application/use_cases/export_live_photo_use_case.dart`
- Test: `test/application/scan_live_photos_use_case_test.dart`
- Test: `test/application/export_live_photo_use_case_test.dart`

**Step 1: Write the failing test**

```dart
test('scan use case returns parsed entities from parser registry', () async {
  // arrange fake ports + fake parser registry
  // act
  // assert
  expect(true, isFalse);
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/application -r expanded`
Expected: FAIL with missing use cases/ports

**Step 3: Write minimal implementation**

- Define all Port interfaces.
- Implement scan and export use cases against interfaces only.
- No plugin imports in `application` layer.

**Step 4: Run test to verify it passes**

Run: `flutter test test/application -r expanded`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/application test/application
git commit -m "T2-1: add application ports and core use cases"
```

---

### Task 4: Data 层 iOS Parser 骨架

**Files:**
- Create: `lib/data/parsers/ios_parser.dart`
- Create: `lib/data/parsers/parser_errors.dart`
- Test: `test/data/parsers/ios_parser_test.dart`
- Test Fixture: `test/fixtures/ios/.gitkeep`

**Step 1: Write the failing test**

```dart
test('ios parser matches uuid pair first, filename as fallback', () async {
  // fixture-driven expectations
  expect(false, isTrue);
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/data/parsers/ios_parser_test.dart -r expanded`
Expected: FAIL

**Step 3: Write minimal implementation**

- Implement match strategy priority: UUID first, filename fallback.
- Return unified parser error codes on failure.

**Step 4: Run test to verify it passes**

Run: `flutter test test/data/parsers/ios_parser_test.dart -r expanded`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/data/parsers test/data/parsers test/fixtures/ios
git commit -m "T2-2: add ios parser skeleton with deterministic matching"
```

---

### Task 5: Data 层 Motion Photo Parser 骨架

**Files:**
- Create: `lib/data/parsers/motion_photo_parser.dart`
- Modify: `lib/data/parsers/parser_errors.dart`
- Test: `test/data/parsers/motion_photo_parser_test.dart`
- Test Fixture: `test/fixtures/motion/.gitkeep`

**Step 1: Write the failing test**

```dart
test('motion parser reads MicroVideoOffset and slices mp4 payload', () async {
  expect(false, isTrue);
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/data/parsers/motion_photo_parser_test.dart -r expanded`
Expected: FAIL

**Step 3: Write minimal implementation**

- Parse XMP for `MicroVideoOffset` / `GCamera:MicroVideo`.
- Slice video payload into temp `.mp4` via `FileSystemPort`.

**Step 4: Run test to verify it passes**

Run: `flutter test test/data/parsers/motion_photo_parser_test.dart -r expanded`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/data/parsers test/data/parsers test/fixtures/motion
git commit -m "T2-3: add motion photo parser skeleton with offset slicing"
```

---

### Task 6: Parser Registry + CLI 验证入口

**Files:**
- Create: `lib/data/services/live_photo_parser_registry.dart`
- Create: `bin/verify_live_photo.dart`
- Test: `test/integration/verify_live_photo_cli_test.dart`

**Step 1: Write the failing test**

```dart
test('cli prints structured summary for scan results', () async {
  expect(false, isTrue);
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/integration/verify_live_photo_cli_test.dart -r expanded`
Expected: FAIL

**Step 3: Write minimal implementation**

- Registry dispatches parser by `match` result.
- CLI accepts input directory and prints JSON summary.

**Step 4: Run test to verify it passes**

Run: `flutter test test/integration/verify_live_photo_cli_test.dart -r expanded`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/data/services bin test/integration
git commit -m "T2-4: add parser registry and cli verification entry"
```

---

### Task 7: 质量门禁与回归命令集

**Files:**
- Create: `tool/test_matrix.ps1`
- Create: `docs/testing/v1-gates.md`
- Modify: `README.md`

**Step 1: Write the failing test/check**

```text
Manual gate check list exists but not executable
```

**Step 2: Run check to verify it fails**

Run: `powershell -ExecutionPolicy Bypass -File tool/test_matrix.ps1`
Expected: FAIL before script exists

**Step 3: Write minimal implementation**

- Add scripted sequence for unit/use-case/widget/smoke commands.
- Document release gates and pass/fail criteria.

**Step 4: Run check to verify it passes**

Run: `powershell -ExecutionPolicy Bypass -File tool/test_matrix.ps1`
Expected: PASS with all planned command lines printed/executed

**Step 5: Commit**

```bash
git add tool/test_matrix.ps1 docs/testing/v1-gates.md README.md
git commit -m "T3: add v1 quality gates and test matrix script"
```

---

## Notes for Execution

- Keep commits small and reversible.
- Follow @superpowers:test-driven-development for each task.
- Use @superpowers:verification-before-completion before claiming each task complete.
- If failures appear, use @superpowers:systematic-debugging before fixing.
