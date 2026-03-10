$ErrorActionPreference = "Stop"

$REPO = "Pulkit7070/multigravity-pro"
$BRANCH = "main"
$RAW = "https://raw.githubusercontent.com/$REPO/$BRANCH"
$INSTALL_DIR = "$env:USERPROFILE\.local\bin"

function Write-Step ($message) {
    Write-Host "  -> $message"
}

function Abort ($message) {
    Write-Error "Error: $message"
    exit 1
}

Write-Host "Installing Multigravity to $INSTALL_DIR ..."

if (!(Test-Path $INSTALL_DIR)) {
    New-Item -ItemType Directory -Force -Path $INSTALL_DIR | Out-Null
}

$IN_PATH = $false
foreach ($path in ($env:PATH -split ';')) {
    if ($path.TrimEnd('\') -eq $INSTALL_DIR.TrimEnd('\')) {
        $IN_PATH = $true
        break
    }
}

if (!$IN_PATH) {
    Write-Step "Adding $INSTALL_DIR to user PATH..."
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    $newPath = if ($userPath) { "$userPath;$INSTALL_DIR" } else { "$INSTALL_DIR" }
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    $env:PATH = "$env:PATH;$INSTALL_DIR"
    Write-Host "  Added to PATH! You may need to restart your terminal for changes to take effect."
    Write-Host ""
}

Write-Step "Downloading multigravity.ps1..."
# Use -UseBasicParsing for compatibility with PS 5.1 on some systems
# We download to a string first to ensure we can save with the correct encoding
try {
    $scriptContent = Invoke-WebRequest -Uri "$RAW/multigravity.ps1" -UseBasicParsing -ErrorAction Stop
    [System.IO.File]::WriteAllText("$INSTALL_DIR\multigravity.ps1", $scriptContent.Content, [System.Text.Encoding]::UTF8)
} catch {
    Abort "Failed to download multigravity.ps1: $_"
}

Write-Step "Creating wrapper script..."
$wrapper = @"
@echo off
powershell.exe -ExecutionPolicy Bypass -File "%~dp0multigravity.ps1" %*
"@

# Save wrapper as ASCII for widest compatibility with cmd.exe
[System.IO.File]::WriteAllText("$INSTALL_DIR\multigravity.cmd", $wrapper, [System.Text.Encoding]::ASCII)

Write-Host ""
Write-Host "✓ Multigravity installed successfully!"
Write-Host ""
Write-Host "Usage:"
Write-Host "  multigravity help"
Write-Host "  multigravity new <profile-name>"
Write-Host "  multigravity <profile-name>"
