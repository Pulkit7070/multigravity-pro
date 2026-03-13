$ErrorActionPreference = "Stop"

$REPO = "Pulkit7070/multigravity-pro"
$BRANCH = "main"
$RAW = "https://raw.githubusercontent.com/$REPO/$BRANCH"
$INSTALL_DIR = "$env:USERPROFILE\.local\bin"
$TEMP_DIR = Join-Path ([System.IO.Path]::GetTempPath()) ("multigravity-install-" + [System.Guid]::NewGuid().ToString("N"))

function Write-Step ($message) {
    Write-Host "  -> $message"
}

function Abort ($message) {
    Write-Error "Error: $message"
    exit 1
}

function Download-File {
    param(
        [string]$FileUrl,
        [string]$OutPath,
        [string]$Label
    )

    Write-Step "Downloading $Label..."
    Invoke-WebRequest -Uri $FileUrl -OutFile $OutPath -UseBasicParsing -ErrorAction Stop
}

function Install-WithBackup {
    param(
        [string]$Source,
        [string]$Destination,
        [System.Text.Encoding]$Encoding
    )

    $backup = "$Destination.bak"
    if (Test-Path $Destination) {
        Copy-Item -Path $Destination -Destination $backup -Force
    }

    try {
        $content = Get-Content -Path $Source -Raw -ErrorAction Stop
        [System.IO.File]::WriteAllText($Destination, $content, $Encoding)
        if (Test-Path $backup) { Remove-Item -Force $backup }
    } catch {
        if (Test-Path $backup) {
            Move-Item -Path $backup -Destination $Destination -Force
        }
        Abort "Failed to install $Destination. Previous version was restored."
    }
}

Write-Host "Installing Multigravity to $INSTALL_DIR ..."
New-Item -ItemType Directory -Force -Path $TEMP_DIR | Out-Null

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

try {
    $scriptTemp = Join-Path $TEMP_DIR "multigravity.ps1"
    Download-File "$RAW/multigravity.ps1" $scriptTemp "multigravity.ps1"
    Install-WithBackup $scriptTemp "$INSTALL_DIR\multigravity.ps1" ([System.Text.Encoding]::UTF8)
} catch {
    Abort "Failed to install multigravity.ps1: $_"
} finally {
    if (Test-Path $TEMP_DIR) { Remove-Item -Recurse -Force $TEMP_DIR -ErrorAction SilentlyContinue }
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
