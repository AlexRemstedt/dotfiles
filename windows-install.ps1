<#
.SYNOPSIS
    Bootstraps a fresh Windows host.

.DESCRIPTION
    Installs WSL and the Windows-side applications used alongside these
    dotfiles:

        - WSL2 (with the default Ubuntu distribution)
        - PowerToys
        - kanata      (keyboard remapper)
        - GlazeWM     (tiling window manager)
        - Obsidian

    The Linux/WSL side of the setup is managed by chezmoi; run this script
    on the Windows host first, then bootstrap the dotfiles from inside WSL:

        sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply <github-username>

.NOTES
    Run from an elevated PowerShell prompt:

        powershell -ExecutionPolicy Bypass -File .\windows-install.ps1

    The script is idempotent: apps already present are skipped.
#>

[CmdletBinding()]
param(
    # Skip the `wsl --install` step (e.g. WSL is already configured).
    [switch]$SkipWsl
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-Administrator {
    $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-WingetApp {
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Name
    )

    # `winget list` exits non-zero when the package is not found.
    winget list --id $Id --exact --accept-source-agreements *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [skip] $Name is already installed." -ForegroundColor DarkGray
        return
    }

    Write-Host "  [install] $Name ($Id)..." -ForegroundColor Cyan
    winget install --id $Id --exact --silent `
        --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to install $Name ($Id). winget exit code: $LASTEXITCODE"
    }
}

# --- Preflight ------------------------------------------------------------

if (-not $IsWindows -and $PSVersionTable.PSVersion.Major -ge 6) {
    throw "This script must be run on Windows."
}

if (-not (Test-Administrator)) {
    throw "This script must be run from an elevated (Administrator) PowerShell prompt."
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "winget was not found. Install 'App Installer' from the Microsoft Store, then re-run."
}

# --- WSL ------------------------------------------------------------------

if ($SkipWsl) {
    Write-Host "Skipping WSL install (-SkipWsl)." -ForegroundColor DarkGray
}
else {
    Write-Host "Installing WSL..." -ForegroundColor Green
    # `wsl --install` enables the required features and installs the default
    # Ubuntu distribution. A reboot may be required to finish the setup.
    wsl --install
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "wsl --install returned exit code $LASTEXITCODE. A reboot may be required; re-run afterwards if needed."
    }
}

# --- Windows applications -------------------------------------------------

Write-Host "Installing Windows applications..." -ForegroundColor Green

$apps = [ordered]@{
    'Microsoft.PowerToys' = 'PowerToys'
    'jtroo.kanata'        = 'kanata'
    'glzr-io.glazewm'     = 'GlazeWM'
    'Obsidian.Obsidian'   = 'Obsidian'
}

foreach ($id in $apps.Keys) {
    Install-WingetApp -Id $id -Name $apps[$id]
}

Write-Host ""
Write-Host "Done. If WSL was just installed, reboot and then bootstrap the dotfiles from inside WSL." -ForegroundColor Green
