# PROGRESS.md

## 记录格式
每次任务推进按以下结构追加：
- 时间
- 任务编号与任务名
- 状态流转
- 本轮目标
- 实施内容
- 验证证据（可复现）
- 阻塞/风险
- 下一步

---

### 2026-02-18 23:07:18 | T1 | 进行中 -> 待确认
- 本轮目标：搭建 Vibe Coding 流程管理文件，并把可执行规范固化到仓库。  
- 实施内容：  
  1. 新增 `AGENTS.md`，写入项目目标、开发流程、强约束、可复用清单。  
  2. 联网检索并补充 Vibe Coding 哲学，加入来源链接。  
  3. 新增 `TASK.md`，建立任务状态模型与初始任务池。  
  4. 新增 `PROGRESS.md` 并追加本轮记录。  
- 验证证据（可复现）：  
  1. 在仓库根目录可见 `AGENTS.md`、`TASK.md`、`PROGRESS.md` 三个文件。  
  2. `AGENTS.md` 中存在 “Vibe Coding 哲学” 章节与外部参考链接。  
  3. `TASK.md` 中 `T1` 状态已更新为 `待确认`。  
- 阻塞/风险：暂无硬阻塞。后续哲学条目可随项目经验持续迭代。  
- 下一步：等待用户确认 T1；确认后将 T1 标记为 `完成` 并进入 T2。

### 2026-02-18 23:18:06 | T1 | 待确认 -> 完成
- 本轮目标：根据用户确认关闭 T1，并细化后续任务为可执行子任务。  
- 实施内容：  
  1. 在 `TASK.md` 中将 `T1` 状态更新为 `完成`。  
  2. 将 `T2 ~ T7` 拆分为子任务，命名格式统一为“母任务编号 + 后缀”（如 `T2-1`）。  
  3. 子任务按母任务行后紧邻插入，母任务保留为汇总项。  
  4. 清理 `.gitignore` 中对 `AGENTS.md`、`TASK.md`、`PROGRESS.md` 的忽略规则，确保任务管理文件可被版本控制。  
- 验证证据（可复现）：  
  1. `TASK.md` 中 `T1` 行状态为 `完成`。  
  2. `TASK.md` 中可见 `T2-1` 到 `T7-4` 子任务行，并紧随对应母任务。  
  3. 子任务命名均符合“母任务 + 后缀”规则。  
  4. `git check-ignore -v AGENTS.md TASK.md PROGRESS.md` 输出 `not_ignored`。  
- 阻塞/风险：当前是计划层拆分，实际优先级仍需在执行中根据阻塞动态微调。  
- 下一步：领取 `T2-1` 并开始 Phase 1 的接口与模型实现。

### 2026-02-19 09:59:46 | T8 | 进行中 -> 待确认
- 本轮目标：按外部安装文档完成 superpowers 技能安装并验证链接生效。  
- 实施内容：  
  1. 拉取并阅读 `https://raw.githubusercontent.com/obra/superpowers/refs/heads/main/.codex/INSTALL.md`。  
  2. 执行克隆：`git clone https://github.com/obra/superpowers.git "$env:USERPROFILE\\.codex\\superpowers"`。  
  3. 执行 Windows 链接步骤：创建 `"$env:USERPROFILE\\.agents\\skills"`，并用 `mklink /J` 创建 `superpowers` Junction。  
  4. 检查旧 bootstrap：`$env:USERPROFILE\\.codex\\AGENTS.md` 不存在，无需迁移清理。  
- 验证证据（可复现）：  
  1. `Get-Item "$env:USERPROFILE\\.agents\\skills\\superpowers"` 显示 `LinkType: Junction`、`Target: C:\\Users\\languoer\\.codex\\superpowers\\skills`。  
  2. `Get-ChildItem "$env:USERPROFILE\\.agents\\skills\\superpowers"` 可列出技能目录（如 `brainstorming`、`systematic-debugging`）。  
  3. 克隆命令返回成功，目标目录已创建。  
- 阻塞/风险：技能发现需要重启 Codex 进程后才会生效，本轮无法在当前会话内完成“重启后发现”验证。  
- 下一步：你重启 Codex 后确认技能可见；确认后将 `T8` 更新为 `完成`。

### 2026-02-19 10:04:45 | T8 | 待确认 -> 完成
- 本轮目标：根据用户确认关闭 T8。  
- 实施内容：在 `TASK.md` 将 `T8` 状态更新为 `完成`，并记录确认时间。  
- 验证证据（可复现）：`TASK.md` 的 `T8` 行状态为 `完成`。  
- 阻塞/风险：无。  
- 下一步：进入 `T9` 头脑风暴任务。

### 2026-02-19 10:04:45 | T9 | 待进行 -> 进行中
- 本轮目标：启动 ULPV 项目头脑风暴，形成可执行设计方向。  
- 实施内容：  
  1. 按技能流程使用 `using-superpowers`，确认技能优先与使用顺序。  
  2. 使用 `brainstorming`，先完成上下文探索（项目文件、任务列表、README、最近提交）。  
  3. 准备进入“一次一个问题”的澄清阶段。  
- 验证证据（可复现）：  
  1. `TASK.md` 新增 `T9` 且状态为 `进行中`。  
  2. 项目上下文已被扫描（含 `README.md`、`TASK.md`、`PROGRESS.md`、最近提交记录）。  
- 阻塞/风险：若目标边界不清晰，会导致方案发散，需先锁定 V1 成功标准。  
- 下一步：向用户提出第一个澄清问题（仅一问），再给出 2-3 个方案对比。

### 2026-02-19 17:45:36 | T2-1 | 进行中 -> 待确认
- 本轮目标：完成 Flutter 项目骨架初始化与 smoke 测试基线（TDD）。  
- 实施内容：  
  1. 领取 `T2-1` 并写入失败测试：`test/smoke/project_bootstrap_test.dart`。  
  2. 执行 RED：`flutter test test/smoke/project_bootstrap_test.dart -r expanded`，首次失败原因为缺少 Flutter 环境。  
  3. 安装本地 Flutter SDK 到 `C:\\Users\\languoer\\flutter-sdk`（不修改系统全局 PATH）。  
  4. 再次执行 RED，失败原因为项目未初始化（缺少 `pubspec.yaml`），满足 TDD 预期。  
  5. 执行最小实现：`flutter create .` 初始化项目；新增 `lib/application/.gitkeep`、`lib/data/.gitkeep`、`lib/domain/.gitkeep`、`lib/ui/.gitkeep`。  
  6. 更新 `pubspec.yaml`，加入 V1 关键依赖：`provider`、`file_picker`、`extended_image`、`video_player`、`ffmpeg_kit_flutter`、`xml`、`exif`。  
  7. 执行 GREEN：`flutter test test/smoke/project_bootstrap_test.dart -r expanded` 通过。  
  8. 将 `TASK.md` 中 `T2-1` 更新为 `待确认`。  
- 验证证据（可复现）：  
  1. RED 证据：`Error: No pubspec.yaml file found.`  
  2. GREEN 证据：`All tests passed!`（`test/smoke/project_bootstrap_test.dart`）。  
  3. 目录证据：`lib/application`、`lib/data`、`lib/domain`、`lib/ui` 已创建。  
- 阻塞/风险：`ffmpeg_kit_flutter` 目前为 discontinued 包；后续 `T6-1` 需要评估替代方案与兼容性。  
- 下一步：等待你确认 `T2-1`；确认后进入 `T2-2`（Domain 实体与解析接口）。  

### 2026-02-19 18:09:33 | T2-2 | 进行中 -> 待确认
- 本轮目标：完成 Domain 层实体与解析接口（`LivePhotoType`、`LivePhotoEntity`、`LivePhotoParser`）。  
- 实施内容：  
  1. 领取任务：`T2-1` 标记为 `完成`，`T2-2` 标记为 `进行中`。  
  2. 按 TDD 写 RED 测试：新增 `test/domain/live_photo_entity_test.dart` 与 `test/domain/live_photo_parser_contract_test.dart`。  
  3. 执行 RED：`flutter test test/domain -r expanded`，确认因缺失 `lib/domain/*.dart` 编译失败。  
  4. 写最小实现：新增 `lib/domain/live_photo_type.dart`、`lib/domain/live_photo_entity.dart`、`lib/domain/live_photo_parser.dart`。  
  5. 执行 GREEN：`flutter test test/domain -r expanded`，全部通过。  
  6. 更新看板：`T2-2` 标记为 `待确认`。  
- 验证证据（可复现）：  
  1. RED 证据：测试输出 `Error when reading 'lib/domain/live_photo_entity.dart'`。  
  2. GREEN 证据：`00:00 +4: All tests passed!`（`test/domain`）。  
  3. 文件证据：`lib/domain/live_photo_type.dart`、`lib/domain/live_photo_entity.dart`、`lib/domain/live_photo_parser.dart` 存在。  
- 阻塞/风险：使用 PowerShell `Set-Content` 更新 `TASK.md` 时出现文件锁，曾导致文件被截断；后续统一改用补丁方式更新看板。  
- 下一步：等待你确认 `T2-2`；确认后进入 `T2-3`（Application Ports 与用例编排）。  

### 2026-02-19 19:02:24 | T2-3 | 进行中 -> 待确认
- 本轮目标：完成 Application Ports 与核心用例编排（插件隔离边界）。  
- 实施内容：  
  1. 更新看板状态：`T2-2` 设为 `完成`，`T2-3` 设为 `进行中`。  
  2. 按 TDD 写 RED 测试：新增 `test/application/scan_live_photos_use_case_test.dart`、`test/application/export_live_photo_use_case_test.dart`。  
  3. 执行 RED：`flutter test test/application -r expanded`，确认缺少 `lib/application/ports/*` 与 `lib/application/use_cases/*`。  
  4. 写最小实现：新增 Ports（`file_system_port.dart`、`media_picker_port.dart`、`video_playback_port.dart`、`export_port.dart`）与 Use Cases（`scan_live_photos_use_case.dart`、`export_live_photo_use_case.dart`）。  
  5. 执行 GREEN：`flutter test test/application -r expanded` 通过。  
  6. 回归验证：`flutter test test/smoke test/domain test/application -r compact` 全部通过。  
  7. 更新看板：`T2-3` 设为 `待确认`。  
- 验证证据（可复现）：  
  1. RED 证据：测试输出 `Error when reading 'lib/application/ports/export_port.dart'`。  
  2. GREEN 证据：`test/application` 输出 `All tests passed!`。  
  3. 回归证据：`test/smoke + test/domain + test/application` 输出 `All tests passed!`。  
- 阻塞/风险：当前 `.gitignore` 包含 `test/` 与 `docs/`，会导致新增测试和文档默认不纳入版本管理；建议后续单开任务修正。  
- 下一步：等待你确认 `T2-3`；确认后进入 `T2-4`（iOS Parser 骨架）。  

### 2026-02-19 19:12:27 | T2-4 | 进行中 -> 待确认
- 本轮目标：完成 iOS Parser 骨架，实现“UUID 优先、文件名兜底”匹配与统一错误码。  
- 实施内容：  
  1. 更新看板状态：`T2-3` 标记为 `完成`，`T2-4` 标记为 `进行中`。  
  2. 按 TDD 写 RED 测试：新增 `test/data/parsers/ios_parser_test.dart`，覆盖 4 个场景（样本匹配、样本解析、无配对错误码、UUID 优先）。  
  3. 执行 RED：`flutter test test/data/parsers/ios_parser_test.dart -r expanded`，确认缺少 parser 实现。  
  4. 写最小实现：新增 `lib/data/parsers/parser_errors.dart`（统一错误码）与 `lib/data/parsers/ios_parser.dart`。  
  5. 修复一次编译问题（`latin1.decode` 参数名），再次执行 GREEN。  
  6. 执行回归：`flutter test test/smoke test/domain test/application test/data/parsers/ios_parser_test.dart -r compact` 全绿。  
  7. 更新看板：`T2-4` 标记为 `待确认`。  
- 验证证据（可复现）：  
  1. RED 证据：`Error when reading 'lib/data/parsers/ios_parser.dart'`。  
  2. GREEN 证据：`test/data/parsers/ios_parser_test.dart` 输出 `00:00 +4: All tests passed!`。  
  3. 回归证据：`smoke + domain + application + ios_parser` 输出 `All tests passed!`。  
- 阻塞/风险：当前 UUID 提取为“从文件文本中正则提取 UUID”的骨架实现，后续需要在真实厂商样本上增强鲁棒性（特别是二进制结构化元数据）。  
- 下一步：等待你确认 `T2-4`；确认后进入 `T2-5`（Motion Photo Parser 骨架）。  

### 2026-02-19 19:19:55 | T2-5 | 进行中 -> 待确认
- 本轮目标：完成 Motion Photo Parser 骨架，支持从 XMP `MicroVideoOffset` 切片生成临时 MP4。  
- 实施内容：  
  1. 根据用户确认，将 `T2-3` 标记为 `完成`，`T2-4` 标记为 `完成`，并将 `T2-5` 标记为 `进行中`。  
  2. 按 TDD 写 RED 测试：新增 `test/data/parsers/motion_photo_parser_test.dart`，覆盖 4 个场景（样本匹配、样本切片、普通图不匹配、缺失元数据报错）。  
  3. 执行 RED：`flutter test test/data/parsers/motion_photo_parser_test.dart -r expanded`，确认缺少 parser 实现。  
  4. 写最小实现：新增 `lib/data/parsers/motion_photo_parser.dart`；更新 `lib/data/parsers/parser_errors.dart` 增加 `metadataNotFound`。  
  5. 执行 GREEN：`flutter test test/data/parsers/motion_photo_parser_test.dart -r expanded` 通过。  
  6. 执行回归：`flutter test test/smoke test/domain test/application test/data/parsers -r compact` 全绿。  
  7. 更新看板：`T2-5` 标记为 `待确认`。  
- 验证证据（可复现）：  
  1. RED 证据：`Error when reading 'lib/data/parsers/motion_photo_parser.dart'`。  
  2. GREEN 证据：`test/data/parsers/motion_photo_parser_test.dart` 输出 `00:00 +4: All tests passed!`。  
  3. 回归证据：`smoke + domain + application + data/parsers` 输出 `All tests passed!`。  
- 阻塞/风险：当前切片逻辑按 `MicroVideoOffset`（文件末尾回推）实现，后续需补充更多非小米样本验证兼容性。  
- 下一步：等待你确认 `T2-5`；确认后进入 `T2-6`（Parser Registry + CLI 验证入口）。  

### 2026-02-19 19:26:11 | T2-6 | 进行中 -> 待确认
- 本轮目标：完成 Parser Registry 与 CLI 验证入口，输出结构化扫描结果。  
- 实施内容：  
  1. 按 TDD 写 RED 测试：新增 `test/integration/verify_live_photo_cli_test.dart`。  
  2. 执行 RED：`flutter test test/integration/verify_live_photo_cli_test.dart -r expanded`，确认缺少 `live_photo_parser_registry.dart` 与 `verify_live_photo.dart`。  
  3. 写最小实现：新增 `lib/data/services/live_photo_parser_registry.dart`，实现默认 parser 注册、递归扫描、匹配分发、失败收集。  
  4. 新增 `bin/verify_live_photo.dart`，实现 `buildScanSummary` 与 CLI JSON 输出。  
  5. 执行 GREEN：`flutter test test/integration/verify_live_photo_cli_test.dart -r expanded` 通过。  
  6. 执行回归：`flutter test test/smoke test/domain test/application test/data/parsers test/integration/verify_live_photo_cli_test.dart -r compact` 全绿。  
  7. 更新看板：`T2-6` 标记为 `待确认`。  
- 验证证据（可复现）：  
  1. RED 证据：`Error when reading 'lib/data/services/live_photo_parser_registry.dart'`。  
  2. GREEN 证据：`test/integration/verify_live_photo_cli_test.dart` 输出 `00:04 +2: All tests passed!`。  
  3. 回归证据：跨 `smoke + domain + application + data/parsers + integration` 输出 `All tests passed!`。  
- 阻塞/风险：CLI 当前输出基础摘要字段，后续可在 `T3` 阶段扩展统计维度（失败类型聚类、品牌识别分布、耗时）。  
- 下一步：等待你确认 `T2-6`；确认后将 `T2` 母任务推进至 `待确认` 并进入 `T3-1`。  

### 2026-02-19 19:53:27 | T3-2 | 进行中 -> 完成
- 本轮目标：完成样本统计脚本并验证“识别率/可播放率/失败分布”可稳定输出。  
- 实施内容：  
  1. 新增 `test/integration/v1_sample_metrics_test.dart`，覆盖统计字段完整性与比率区间校验。  
  2. 新增 `bin/evaluate_v1_samples.dart`，实现清单读取、目录扫描、指标计算与 CLI JSON 输出。  
  3. 执行任务测试：`$env:USERPROFILE\\flutter-sdk\\bin\\flutter.bat test test/integration/v1_sample_metrics_test.dart -r expanded`。  
  4. 执行脚本验证：`$env:USERPROFILE\\flutter-sdk\\bin\\dart.bat run bin/evaluate_v1_samples.dart sample`。  
  5. 执行重复运行对比（两次运行比率与计数比对）。  
- 验证证据（可复现）：  
  1. 测试通过：`00:05 +2: All tests passed!`。  
  2. 统计输出：`total_manifest_items=12`、`expected_live_count=6`、`recognized_live_count=6`、`playable_live_count=6`。  
  3. 比率输出：`recognition_rate=1.0`、`playable_rate=1.0`。  
  4. 重复运行一致性：`same_totals=True`。  
- 阻塞/风险：CSV 解析当前为轻量实现（支持基础引号场景），后续若引入更复杂字段需补充边界测试。  
- 下一步：进入 `T3-3`，补齐失败样本明细报告与可复现命令输出。  

### 2026-02-19 19:58:57 | T3-3 | 进行中 -> 完成
- 本轮目标：实现失败样本报告，满足 `file_path + error_code + stage + reproduce_command`。  
- 实施内容：  
  1. 新增 RED 测试 `test/integration/v1_failure_report_test.dart`，构造“清单声明 live 但样本缺失”的失败场景。  
  2. 执行 RED：`$env:USERPROFILE\\flutter-sdk\\bin\\flutter.bat test test/integration/v1_failure_report_test.dart -r expanded`（缺少 `bin/report_v1_failures.dart`）。  
  3. 新增 `bin/report_v1_failures.dart`：实现失败项聚合（recognition/parsing/playability）、错误码提取与 `--focus` 复现过滤。  
  4. 执行 GREEN：`$env:USERPROFILE\\flutter-sdk\\bin\\flutter.bat test test/integration/v1_failure_report_test.dart -r expanded`。  
  5. 执行集成回归：`$env:USERPROFILE\\flutter-sdk\\bin\\flutter.bat test test/integration -r compact`。  
  6. 执行 CLI 样例验证（注入一条故意缺失样本）并确认报告字段完整。  
- 验证证据（可复现）：  
  1. GREEN 证据：`00:02 +1: All tests passed!`（`test/integration/v1_failure_report_test.dart`）。  
  2. 集成回归证据：`00:09 +5: All tests passed!`（`test/integration`）。  
  3. CLI 输出证据：`total_failures=1`，`failures_by_stage.recognition=1`，并包含 `file_path/error_code/stage/reproduce_command`。  
- 阻塞/风险：当前失败复现命令以 CLI 维度复现，不含更细粒度的单文件诊断日志；后续可在门禁阶段补充 verbose 模式。  
- 下一步：进入 `T3-4`，补齐质量门禁脚本与发布前检查文档。  

### 2026-02-19 20:03:25 | T3-4 | 进行中 -> 完成
- 本轮目标：交付可执行质量门禁脚本，并补齐发布前检查文档与 README 入口。  
- 实施内容：  
  1. 先执行 RED 检查：`powershell -ExecutionPolicy Bypass -File tool/test_matrix.ps1`（脚本不存在，符合预期失败）。  
  2. 新增 `tool/test_matrix.ps1`，实现 V1 门禁命令矩阵（smoke/domain/application/parsers/integration）与失败即停。  
  3. 新增 `docs/testing/v1-gates.md`，固化门禁执行方式、发布前检查项与复核命令。  
  4. 更新 `README.md` 增加“质量门禁与发布检查”入口。  
  5. 验证中发现脚本聚合逻辑误判（测试输出被计入结果），修复 `Invoke-Expression` 输出处理与统计条件后重跑。  
  6. 执行 `-DryRun` 与真实执行两种验证，确认门禁命令可执行并返回成功。  
- 验证证据（可复现）：  
  1. RED 证据：`The argument 'tool/test_matrix.ps1' to the -File parameter does not exist.`  
  2. DryRun 证据：`Gate Summary: passed=5 failed=0 total=5`。  
  3. 实跑证据：`Gate Summary: passed=5 failed=0 total=5` 且 `All gate steps passed.`。  
  4. 文档入口证据：`README.md` 已包含 `tool/test_matrix.ps1` 与 `docs/testing/v1-gates.md` 引用。  
- 阻塞/风险：当前门禁未自动统计覆盖率阈值（85%/80%），现阶段仍依赖测试套件通过与样本指标脚本。  
- 下一步：进入 `T4-1`（Windows MVP 工程初始化）。  

### 2026-02-19 20:09:47 | T4-1 | 进行中 -> 失败
- 本轮目标：完成 Windows MVP 工程初始化，验证“可启动运行 + 窗口能力生效”。  
- 实施内容：  
  1. 新增 RED 测试 `test/smoke/windows_runner_bootstrap_test.dart`，约束窗口标题与最小尺寸消息处理。  
  2. 执行 RED：`flutter test test/smoke/windows_runner_bootstrap_test.dart -r expanded`（标题断言失败）。  
  3. 更新 `windows/runner/main.cpp`：窗口标题改为 `Universal Live Photo Viewer`，起始位置调整为 `(80,60)`。  
  4. 更新 `windows/runner/win32_window.cpp`：新增 `WM_GETMINMAXINFO`，设置最小尺寸 `960x640`。  
  5. 执行 GREEN：`flutter test test/smoke/windows_runner_bootstrap_test.dart -r expanded` 通过。  
  6. 回归验证：`flutter test test/smoke test/widget_test.dart -r compact` 通过。  
  7. 尝试运行 Windows 构建：`flutter build windows --debug`，被本机环境阻塞。  
- 验证证据（可复现）：  
  1. GREEN 证据：`00:00 +1: All tests passed!`（`windows_runner_bootstrap_test.dart`）。  
  2. 回归证据：`All tests passed!`（`test/smoke + test/widget_test.dart`）。  
  3. 阻塞证据：`Unable to find suitable Visual Studio toolchain.`。  
  4. `flutter doctor -v` 证据：`Visual Studio not installed; install Desktop development with C++`。  
- 阻塞/风险：当前环境缺少 Windows C++ 工具链，无法完成“可启动运行”实机构建验证。  
- 下一步建议：  
  1. 安装 Visual Studio（Desktop development with C++，默认组件）。  
  2. 重新执行 `flutter doctor -v` 直到 Windows toolchain 变为通过。  
  3. 重试 `flutter build windows --debug`，通过后将 `T4-1` 从 `失败` 改为 `完成` 并继续 `T4-2`。  
