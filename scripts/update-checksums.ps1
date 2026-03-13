$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Write-ChecksumFile {
    param(
        [Parameter(Mandatory = $true)][string]$SourceFile,
        [Parameter(Mandatory = $true)][string]$ChecksumFile
    )

    $hash = (Get-FileHash -Path $SourceFile -Algorithm SHA256).Hash.ToLowerInvariant()
    "$hash  $SourceFile" | Set-Content -Path $ChecksumFile -NoNewline
}

Write-ChecksumFile -SourceFile "multigravity" -ChecksumFile "multigravity.sha256"
Write-ChecksumFile -SourceFile "multigravity.ps1" -ChecksumFile "multigravity.ps1.sha256"

Write-Host "Updated checksum files:"
Write-Host "  multigravity.sha256"
Write-Host "  multigravity.ps1.sha256"
