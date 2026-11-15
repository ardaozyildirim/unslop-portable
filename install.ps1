# Installs unslop-portable once and links it into each agent's skills folder.
# Usage: install.ps1 [-Update] [-Uninstall] [-DryRun]
param(
  [switch]$Update,
  [switch]$Uninstall,
  [switch]$DryRun
)
$ErrorActionPreference = "Stop"

$name = "unslop-portable"
$source = Join-Path $PSScriptRoot "skills\$name"
$canonical = Join-Path $HOME ".agents\skills\$name"
$linkTargets = @(
  (Join-Path $HOME ".claude\skills\$name"),
  (Join-Path $HOME ".codex\skills\$name"),
  (Join-Path $HOME ".config\opencode\skills\$name")
)
# Antigravity does not follow junctions, so it gets real copies.
$copyTargets = @(
  (Join-Path $HOME ".gemini\config\skills\$name"),
  (Join-Path $HOME ".gemini\antigravity-cli\skills\$name")
)
$legacyDirs = @(
  (Join-Path $HOME ".agents\skills\unslop"),
  (Join-Path $HOME ".claude\skills\unslop"),
  (Join-Path $HOME ".codex\skills\unslop"),
  (Join-Path $HOME ".config\opencode\skills\unslop"),
  (Join-Path $HOME ".gemini\config\skills\unslop"),
  (Join-Path $HOME ".gemini\antigravity-cli\skills\unslop")
)

function Invoke-Step([scriptblock]$action, [string]$text) {
  if ($DryRun) { Write-Host "[dry-run] $text" } else { & $action }
}

function Remove-Path([string]$path) {
  if ((Get-Item $path -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
    (Get-Item $path -Force).Delete()   # removes the junction, not its target
  } else {
    Remove-Item -Recurse -Force $path
  }
}

# Only removes folders that are clearly this port, never upstream unslop.
function Clear-Legacy {
  foreach ($dir in $legacyDirs) {
    if (-not (Test-Path $dir)) { continue }
    $item = Get-Item $dir -Force
    $isLink = [bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
    $skill = Join-Path $dir "SKILL.md"
    $isPort = $isLink -or ((Test-Path $skill) -and (Select-String -Path $skill -Pattern "unofficial port" -Quiet))
    if ($isPort) {
      Invoke-Step { Remove-Path $dir } "remove $dir"
      Write-Host "Removed old build of this port: $dir"
    } else {
      Write-Host "Left alone (looks like upstream unslop, not this port): $dir"
    }
  }
}

if ($Uninstall) {
  foreach ($target in ($linkTargets + $copyTargets + $canonical)) {
    if (Test-Path $target) {
      Invoke-Step { Remove-Path $target } "remove $target"
      Write-Host "Removed $target"
    }
  }
  Clear-Legacy
  return
}

if (-not (Test-Path $source)) { throw "skills\$name not found next to this script." }

Clear-Legacy

if ((Test-Path $canonical) -and $Update) {
  Invoke-Step { Remove-Path $canonical } "remove $canonical"
}
if (Test-Path $canonical) {
  Write-Host "Skill already installed at $canonical (leaving it as is; use -Update to refresh)."
} else {
  Invoke-Step {
    New-Item -ItemType Directory -Force -Path (Split-Path $canonical) | Out-Null
    Copy-Item -Path $source -Destination $canonical -Recurse
  } "copy $source -> $canonical"
  Write-Host "Copied skill to $canonical"
}

foreach ($target in $linkTargets) {
  Invoke-Step { New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null } "mkdir $(Split-Path $target)"
  if (Test-Path $target) {
    Write-Host "Exists, skipped: $target"
    continue
  }
  Invoke-Step { New-Item -ItemType Junction -Path $target -Target $canonical | Out-Null } "link $target -> $canonical"
  Write-Host "Linked $target -> $canonical"
}

foreach ($target in $copyTargets) {
  Invoke-Step { New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null } "mkdir $(Split-Path $target)"
  if (Test-Path $target) {
    if ($Update) {
      Invoke-Step { Remove-Path $target } "remove $target"
    } else {
      Write-Host "Exists, skipped: $target (run with -Update to refresh this copy)"
      continue
    }
  }
  Invoke-Step { Copy-Item -Path $source -Destination $target -Recurse } "copy $source -> $target"
  Write-Host "Copied $target (Antigravity does not follow junctions)"
}
