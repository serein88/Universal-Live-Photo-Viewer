# Windows 本地冒烟脚本（最小路径）

本文档说明如何在 Windows 本地执行 `tool/windows_smoke_check.ps1`，以及执行完成后需要上传哪些产物用于结果复核。

## 1. 前置条件

- PowerShell 5.1+ 或 PowerShell 7+
- 已拿到可执行应用（例如 `build/windows/x64/runner/Release/universal_live_photo_viewer.exe`）
- 已准备样本目录（建议使用 `docs/testing/v1-sample-spec.md` 约定结构）
- 当前仓库可执行 `git` 命令（用于记录 commit hash）

## 2. 运行命令

在仓库根目录执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\windows_smoke_check.ps1 `
  -AppPath "C:\path\to\universal_live_photo_viewer.exe" `
  -SamplePath "C:\path\to\sample" `
  -AppVersion "v0.1.0-local"
```

> 可选参数：
>
> - `-StepTimeoutSec`：每个手工步骤的超时时间（秒），默认 `180`。

## 3. 脚本固定步骤

脚本会按固定顺序执行并记录日志：

1. `start_app`：启动应用。
2. `import_sample_directory`：在应用中导入样本目录（手工确认）。
3. `switch_photo`：执行一次切图（手工确认）。
4. `play_live_photo`：执行一次播放（手工确认）。
5. `export_live_photo`：执行一次最小导出路径（手工确认）。
6. `exit_app`：退出应用。

日志写入：`logs/windows_smoke_yyyyMMdd_HHmmss.log`。

## 4. 日志字段（固定字段名）

每行日志为一条 JSON，字段名固定，便于自动比对：

- `timestamp`
- `app_version`
- `commit_hash`
- `sample_path`
- `step`
- `result`
- `started_at`
- `ended_at`
- `duration_ms`
- `error_code`
- `error_stack`
- `message`

## 5. 执行完成后上传内容

请将以下文件（或压缩包）上传到任务记录/PR：

1. 冒烟日志：`logs/windows_smoke_*.log`
2. 导出产物截图或文件列表（证明导出步骤实际执行）
3. 若失败，附加失败时的界面截图与错误说明

建议附上本次执行信息：

- 应用版本（`-AppVersion`）
- 使用样本路径（`-SamplePath`）
- 机器与系统版本（Windows 版本号）
