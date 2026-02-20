# V1 质量门禁与发布前检查

## 1. 一键门禁命令

在仓库根目录执行：

```powershell
powershell -ExecutionPolicy Bypass -File tool/test_matrix.ps1
```

仅查看将要执行的命令（不实际运行）：

```powershell
powershell -ExecutionPolicy Bypass -File tool/test_matrix.ps1 -DryRun
```

## 2. 门禁步骤（脚本内顺序）

1. `test/smoke`
2. `test/domain`
3. `test/application`
4. `test/data/parsers`
5. `test/integration`

任一步骤失败即终止，并返回非零退出码。

## 3. V1 发布前检查清单

1. 门禁脚本执行通过（`failed=0`）。
2. 使用 V1 样本执行统计脚本并达标：
   - `recognition_rate >= 0.95`
   - `playable_rate == 1.0`
3. 失败报告脚本可输出结构化失败项（`file_path/error_code/stage/reproduce_command`）。
4. 生成发布包并记录：
   - 版本号
   - 构建时间
   - 提交哈希（`git rev-parse --short HEAD`）
   - 已知限制
5. 发布附件包含回滚说明（回滚到上一个稳定提交或上一个发布包）。

## 4. 推荐复核命令

```powershell
$env:USERPROFILE\flutter-sdk\bin\dart.bat run bin/evaluate_v1_samples.dart sample
$env:USERPROFILE\flutter-sdk\bin\dart.bat run bin/report_v1_failures.dart sample
git rev-parse --short HEAD
```

## 5. GitHub Actions Windows 构建

工作流文件：`.github/workflows/windows-build.yml`

触发方式：
1. 推送到 `main`（命中工作流路径过滤）。
2. 在 GitHub Actions 页面手动执行 `workflow_dispatch`。

产物位置：
1. Actions 运行详情 -> Artifacts -> `ulpv-windows-release-<sha>`。
2. 内容目录：`build/windows/x64/runner/Release`。
