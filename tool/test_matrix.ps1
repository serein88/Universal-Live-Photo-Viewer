param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Resolve-FlutterCommand {
    $globalFlutter = Get-Command flutter -ErrorAction SilentlyContinue
    if ($null -ne $globalFlutter) {
        return "flutter"
    }

    $localFlutter = Join-Path $env:USERPROFILE "flutter-sdk\bin\flutter.bat"
    if (Test-Path $localFlutter) {
        return $localFlutter
    }

    throw "Flutter command not found. Expected global 'flutter' or '$localFlutter'."
}

function Invoke-Step {
    param(
        [string]$Name,
        [string]$Command,
        [string]$WorkingDirectory
    )

    Write-Host "==> [$Name]"
    Write-Host "    $Command"

    if ($DryRun) {
        return [pscustomobject]@{
            Name = $Name
            Success = $true
            ExitCode = 0
        }
    }

    Push-Location $WorkingDirectory
    try {
        Invoke-Expression $Command | Out-Host
        $exitCode = $LASTEXITCODE
        if ($null -eq $exitCode) {
            $exitCode = 0
        }
        if ($exitCode -ne 0) {
            return [pscustomobject]@{
                Name = $Name
                Success = $false
                ExitCode = $exitCode
            }
        }
    }
    finally {
        Pop-Location
    }

    return [pscustomobject]@{
        Name = $Name
        Success = $true
        ExitCode = 0
    }
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$flutter = Resolve-FlutterCommand
$flutterCmd = if ($flutter -eq "flutter") { "flutter" } else { "& `"$flutter`"" }

$steps = @(
    @{ Name = "Smoke tests"; Command = "$flutterCmd test test/smoke -r compact" },
    @{ Name = "Domain tests"; Command = "$flutterCmd test test/domain -r compact" },
    @{ Name = "Application tests"; Command = "$flutterCmd test test/application -r compact" },
    @{ Name = "Parser tests"; Command = "$flutterCmd test test/data/parsers -r compact" },
    @{ Name = "Integration tests"; Command = "$flutterCmd test test/integration -r compact" }
)

$results = @()
foreach ($step in $steps) {
    $results += Invoke-Step -Name $step.Name -Command $step.Command -WorkingDirectory $repoRoot
    if (-not $results[-1].Success) {
        break
    }
}

$passed = ($results | Where-Object { $_.Success -eq $true }).Count
$failed = ($results | Where-Object { $_.Success -eq $false }).Count

Write-Host ""
Write-Host "Gate Summary: passed=$passed failed=$failed total=$($results.Count)"

if ($failed -gt 0) {
    $firstFailure = $results | Where-Object { -not $_.Success } | Select-Object -First 1
    Write-Error "Gate failed at '$($firstFailure.Name)' with exit code $($firstFailure.ExitCode)."
}

Write-Host "All gate steps passed."
