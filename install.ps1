# Install wq-workflow into a DeepSeek Harness skill root.
#
# Usage:
#   .\install.ps1                  # install to $env:DSH_HOME\skills (or ~\.dsh\skills)
#   .\install.ps1 -Project         # install to <cwd>\.dsh\skills
#   .\install.ps1 -Agents          # install to ~\.agents\skills (shared with Codex)
#   .\install.ps1 -Dest D:\my\skills
#   .\install.ps1 -Force           # overwrite an existing copy
#
# If script execution is blocked, run:
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1

[CmdletBinding()]
param(
    [switch]$Project,
    [switch]$Agents,
    [string]$Dest,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$source = Join-Path $scriptDir 'skills\wq-workflow'

if (-not (Test-Path (Join-Path $source 'SKILL.md'))) {
    throw "Cannot find skill source directory: $source"
}

function Resolve-DefaultRoot {
    if ($Project) { return (Join-Path (Get-Location).Path '.dsh\skills') }
    if ($Agents) { return (Join-Path $HOME '.agents\skills') }

    $dshHome = $env:DSH_HOME
    if ([string]::IsNullOrWhiteSpace($dshHome)) {
        $dshHome = Join-Path $HOME '.dsh'
    }
    return (Join-Path $dshHome 'skills')
}

if ([string]::IsNullOrWhiteSpace($Dest)) {
    $root = Resolve-DefaultRoot
} else {
    $root = $Dest
}

$target = Join-Path $root 'wq-workflow'

Write-Host "Source : $source"
Write-Host "Target : $target"

# Warn about same-name copies in other discoverable roots (DSH merges by rank)
$candidates = @(
    (Join-Path $HOME '.dsh\skills'),
    (Join-Path $HOME '.agents\skills'),
    (Join-Path (Get-Location).Path '.dsh\skills'),
    (Join-Path (Get-Location).Path '.agents\skills')
)

foreach ($r in $candidates) {
    if ($r -eq $root) { continue }
    $dup = Join-Path $r 'wq-workflow'
    if (Test-Path $dup) {
        Write-Warning "Same-name skill found in another discoverable root: $dup"
        Write-Warning "DSH picks one by rank; keep a single copy."
    }
}

if (Test-Path $target) {
    if (-not $Force) {
        Write-Host ''
        Write-Host "Already installed, nothing changed: $target" -ForegroundColor Yellow
        Write-Host 'Pass -Force to overwrite, or back up your local changes first.'
        exit 1
    }
    Write-Host "Removing previous copy: $target" -ForegroundColor Yellow
    Remove-Item $target -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $root | Out-Null
Copy-Item $source $target -Recurse -Force

$check = Join-Path $target 'SKILL.md'
if (-not (Test-Path $check)) {
    throw "SKILL.md missing after install: $check"
}

Write-Host ''
Write-Host "Installed: $target" -ForegroundColor Green
Get-ChildItem $target -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($target.Length + 1)
    Write-Host ("  {0}  ({1} bytes)" -f $rel, $_.Length)
}

Write-Host ''
Write-Host 'Next: call /wq-workflow in a DSH session, or just describe a development task.'
Write-Host 'DSH watches skill roots, so a restart is usually unnecessary; reopen the session if / shows nothing.'
