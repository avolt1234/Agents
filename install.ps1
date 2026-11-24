<#
.SYNOPSIS
  Installs the Dev Team agents and /devteam command for Claude Code.

.EXAMPLE
  # Install into a specific project (recommended)
  .\install.ps1 -Target "C:\code\my-project"

.EXAMPLE
  # Install globally for your user (available in every project)
  .\install.ps1 -Global
#>
param(
    [string]$Target,
    [switch]$Global,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$Source = Join-Path $PSScriptRoot ".claude"

if ($Global) {
    $Dest = Join-Path $HOME ".claude"
} elseif ($Target) {
    $Dest = Join-Path (Resolve-Path $Target) ".claude"
} else {
    Write-Host "Usage: .\install.ps1 -Target <project-folder>   or   .\install.ps1 -Global"
    exit 1
}

foreach ($sub in @("agents", "commands", "security")) {
    $from = Join-Path $Source $sub
    $to   = Join-Path $Dest $sub
    New-Item -ItemType Directory -Force -Path $to | Out-Null
    foreach ($file in Get-ChildItem -Path $from -Filter *.md) {
        $outFile = Join-Path $to $file.Name
        if ((Test-Path $outFile) -and -not $Force) {
            Write-Host "skip   $outFile (exists; use -Force to overwrite)"
        } else {
            Copy-Item $file.FullName $outFile -Force
            Write-Host "copied $outFile"
        }
    }
}

# Security permission rules (deny reading secrets, git push, destructive commands, ...)
$settingsOut = Join-Path $Dest "settings.json"
if ((Test-Path $settingsOut) -and -not $Force) {
    Write-Host "skip   $settingsOut (exists; merge the 'permissions' block from this repo's .claude\settings.json by hand)"
} else {
    if (Test-Path $settingsOut) { Copy-Item $settingsOut "$settingsOut.bak" -Force; Write-Host "backup $settingsOut.bak" }
    Copy-Item (Join-Path $Source "settings.json") $settingsOut -Force
    Write-Host "copied $settingsOut"
}

if ($Target -and -not $Global) {
    $claudeMd = Join-Path (Resolve-Path $Target) "CLAUDE.md"
    if (-not (Test-Path $claudeMd)) {
        Copy-Item (Join-Path $PSScriptRoot "CLAUDE.md") $claudeMd
        Write-Host "copied $claudeMd"
    } else {
        Write-Host "skip   $claudeMd (exists; merge the 'Dev Team' section from this repo's CLAUDE.md by hand)"
    }
}

Write-Host ""
Write-Host "Done. Restart Claude Code in the project and ask: 'Which subagents are available?'"
Write-Host "Expect: senior-dev, junior-dev-1, junior-dev-2, security-reviewer, tester. Then try: /devteam <task>"
