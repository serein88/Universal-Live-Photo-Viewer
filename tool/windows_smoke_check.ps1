param(
    [Parameter(Mandatory = $true)]
    [string]$AppPath,

    [Parameter(Mandatory = $true)]
    [string]$SamplePath,

    [string]$AppVersion = "unknown",

    [int]$StepTimeoutSec = 180
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repoRoot = Split-Path -Parent $PSScriptRoot
$logDir = Join-Path $repoRoot "logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logPath = Join-Path $logDir "windows_smoke_$timestamp.log"
$commitHash = "unknown"
try {
    $commitHash = (git -C $repoRoot rev-parse --short HEAD).Trim()
}
catch {
    $commitHash = "unknown"
}

function Write-LogEntry {
    param(
        [string]$Step,
        [string]$Result,
        [datetime]$StartedAt,
        [datetime]$EndedAt,
        [long]$DurationMs,
        [string]$ErrorCode = "",
        [string]$ErrorStack = "",
        [string]$Message = ""
    )

    $entry = [ordered]@{
        timestamp = (Get-Date).ToString("o")
        app_version = $AppVersion
        commit_hash = $commitHash
        sample_path = $SamplePath
        step = $Step
        result = $Result
        started_at = $StartedAt.ToString("o")
        ended_at = $EndedAt.ToString("o")
        duration_ms = $DurationMs
        error_code = $ErrorCode
        error_stack = $ErrorStack
        message = $Message
    }

    ($entry | ConvertTo-Json -Compress) | Add-Content -Path $logPath -Encoding UTF8
}

function Invoke-SmokeStep {
    param(
        [string]$Step,
        [scriptblock]$Action
    )

    $startedAt = Get-Date
    try {
        & $Action
        $endedAt = Get-Date
        $durationMs = [long]($endedAt - $startedAt).TotalMilliseconds
        Write-LogEntry -Step $Step -Result "success" -StartedAt $startedAt -EndedAt $endedAt -DurationMs $durationMs
    }
    catch {
        $endedAt = Get-Date
        $durationMs = [long]($endedAt - $startedAt).TotalMilliseconds
        $errorCode = if ($_.Exception.HResult) { $_.Exception.HResult.ToString() } else { "UNHANDLED" }
        $errorStack = ($_ | Out-String).Trim()
        Write-LogEntry -Step $Step -Result "failed" -StartedAt $startedAt -EndedAt $endedAt -DurationMs $durationMs -ErrorCode $errorCode -ErrorStack $errorStack
        throw
    }
}

function Wait-ManualConfirm {
    param(
        [string]$Prompt
    )

    $deadline = (Get-Date).AddSeconds($StepTimeoutSec)
    while ((Get-Date) -lt $deadline) {
        $answer = Read-Host "$Prompt (输入 y 继续，输入 n 记为失败)"
        if ($answer -eq "y") {
            return
        }
        if ($answer -eq "n") {
            throw "Manual step not confirmed: $Prompt"
        }
        Write-Host "仅支持输入 y / n，请重试。"
    }

    throw "Manual step timeout after $StepTimeoutSec seconds: $Prompt"
}

$sessionStartedAt = Get-Date
Write-LogEntry -Step "meta" -Result "success" -StartedAt $sessionStartedAt -EndedAt $sessionStartedAt -DurationMs 0 -Message "Windows smoke check session started"

if (-not (Test-Path $AppPath)) {
    throw "AppPath not found: $AppPath"
}
if (-not (Test-Path $SamplePath)) {
    throw "SamplePath not found: $SamplePath"
}

$appProcess = $null

try {
    Invoke-SmokeStep -Step "start_app" -Action {
        $script:appProcess = Start-Process -FilePath $AppPath -PassThru
        Start-Sleep -Seconds 3
        if ($script:appProcess.HasExited) {
            throw "Application exited unexpectedly right after launch."
        }
    }

    Invoke-SmokeStep -Step "import_sample_directory" -Action {
        Wait-ManualConfirm -Prompt "请在应用中导入样本目录：$SamplePath，完成后"
    }

    Invoke-SmokeStep -Step "switch_photo" -Action {
        Wait-ManualConfirm -Prompt "请在应用中执行一次切图（下一张/上一张任一），完成后"
    }

    Invoke-SmokeStep -Step "play_live_photo" -Action {
        Wait-ManualConfirm -Prompt "请在应用中播放当前实况图（可见视频层开始播放），完成后"
    }

    Invoke-SmokeStep -Step "export_live_photo" -Action {
        Wait-ManualConfirm -Prompt "请在应用中执行一次最小导出路径（任一导出格式），完成后"
    }

    Invoke-SmokeStep -Step "exit_app" -Action {
        if ($null -ne $script:appProcess -and -not $script:appProcess.HasExited) {
            $script:appProcess.CloseMainWindow() | Out-Null
            Start-Sleep -Seconds 2
            if (-not $script:appProcess.HasExited) {
                Stop-Process -Id $script:appProcess.Id -Force
            }
        }
    }
}
catch {
    Write-Host "Smoke check failed. See log: $logPath"
    throw
}
finally {
    $sessionEndedAt = Get-Date
    $durationMs = [long]($sessionEndedAt - $sessionStartedAt).TotalMilliseconds
    Write-LogEntry -Step "session" -Result "finished" -StartedAt $sessionStartedAt -EndedAt $sessionEndedAt -DurationMs $durationMs -Message "Windows smoke check session ended"
    Write-Host "Smoke check log generated: $logPath"
}
