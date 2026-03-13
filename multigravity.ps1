<#
.SYNOPSIS
Run multiple Antigravity IDE profiles at the same time.
#>

param (
    [Parameter(Position = 0, Mandatory = $false)]
    [string]$cmd,
    
    [Parameter(Position = 1, Mandatory = $false)]
    [string]$arg1,

    [Parameter(Position = 2, Mandatory = $false)]
    [string]$arg2,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ForwardArgs
)

$BASE = if ($env:MULTIGRAVITY_HOME) { $env:MULTIGRAVITY_HOME } else { "$env:USERPROFILE\AntigravityProfiles" }

function Find-Antigravity {
    $paths = @(
        "$env:LOCALAPPDATA\Programs\Antigravity\Antigravity.exe",
        "$env:PROGRAMFILES\Antigravity\Antigravity.exe",
        "${env:ProgramFiles(x86)}\Antigravity\Antigravity.exe"
    )
    foreach ($p in $paths) {
        if (Test-Path $p) { return $p }
    }
    
    # Try to find in PATH
    $exeCommand = Get-Command antigravity.exe -ErrorAction SilentlyContinue
    if ($exeCommand) { return $exeCommand.Source }
    
    return $null
}

$APP = if ($env:MULTIGRAVITY_APP) { $env:MULTIGRAVITY_APP } else { Find-Antigravity }

function Get-DefaultUserDataDir {
    return "$env:APPDATA\Antigravity"
}

function Get-DefaultExtensionsDir {
    return "$env:USERPROFILE\.antigravity\extensions"
}

function Get-TemplatesDir {
    return "$BASE\.templates"
}

function Test-AuthOnly {
    param($PROFILE)
    return Test-Path "$BASE\$PROFILE\.auth-only"
}

function Write-Usage {
    Write-Host "Usage: multigravity <command> [args]"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  new <name> [options]    Create a new named profile + Start Menu shortcut"
    Write-Host "      --auth-only         Share extensions & settings, isolate only accounts"
    Write-Host "      --from <template>   Create from a saved template"
    Write-Host "  list                    List existing profiles"
    Write-Host "  status                  Show which profiles are running, type, last used"
    Write-Host "  rename <old> <new>      Rename a profile (updates shortcut if present)"
    Write-Host "  delete <name>           Delete a profile and its data"
    Write-Host "  clone <src> <dest>      Clone an existing profile"
    Write-Host "  template save <profile> <name>   Save a profile as a reusable template"
    Write-Host "  template list           List available templates"
    Write-Host "  template delete <name>  Delete a template"
    Write-Host "  export <name> [path]    Export a profile to a .zip archive"
    Write-Host "  import <archive> [name] Import a profile from a .zip archive"
    Write-Host "  update                  Update multigravity to the latest version"
    Write-Host "  doctor                  Run a system diagnosis"
    Write-Host "  stats                   Show storage usage per profile"
    Write-Host "  completion              Show setup instructions for shell completion"
    Write-Host "  <name>                  Launch Antigravity with the given profile"
    Write-Host "  help                    Show this help"
    Write-Host ""
    Write-Host "Profile names: alphanumeric and hyphens only (e.g. work, personal, test-1)"
}

function Validate-Name {
    param($name)
    if ([string]::IsNullOrWhiteSpace($name)) {
        Write-Error "Error: profile name required"
        exit 1
    }
    if ($name -notmatch "^[a-zA-Z0-9][a-zA-Z0-9-]*$") {
        Write-Error "Error: profile name must start with alphanumeric and contain only letters, numbers, or hyphens"
        exit 1
    }
}

function Invoke-CreateProfile {
    param($PROFILE)
    $PROFILE_DIR = "$BASE\$PROFILE"

    New-Item -ItemType Directory -Force -Path "$PROFILE_DIR\.antigravity\extensions" | Out-Null
    New-Item -ItemType Directory -Force -Path "$PROFILE_DIR\AppData\Roaming" | Out-Null
    New-Item -ItemType Directory -Force -Path "$PROFILE_DIR\AppData\Local" | Out-Null
}

function Invoke-CreateAuthOnlyProfile {
    param($PROFILE)
    $PROFILE_DIR = "$BASE\$PROFILE"
    $defaultData = Get-DefaultUserDataDir
    $defaultExt = Get-DefaultExtensionsDir

    New-Item -ItemType Directory -Force -Path $PROFILE_DIR | Out-Null

    # Mark as auth-only
    New-Item -ItemType File -Force -Path "$PROFILE_DIR\.auth-only" | Out-Null

    # Create app data dirs (holds isolated auth/account state)
    $dataDir = "$PROFILE_DIR\AppData\Roaming\Antigravity\User"
    New-Item -ItemType Directory -Force -Path $dataDir | Out-Null
    New-Item -ItemType Directory -Force -Path "$PROFILE_DIR\AppData\Local" | Out-Null

    # Symlink shared settings from default installation
    if (Test-Path "$defaultData\User") {
        foreach ($item in @("settings.json", "keybindings.json", "snippets")) {
            $src = "$defaultData\User\$item"
            $dest = "$dataDir\$item"
            if ((Test-Path $src) -and !(Test-Path $dest)) {
                New-Item -ItemType SymbolicLink -Path $dest -Target $src -ErrorAction SilentlyContinue | Out-Null
            }
        }
    }

    # Symlink extensions to default (shared, not copied)
    $extDir = "$PROFILE_DIR\.antigravity\extensions"
    if (Test-Path $defaultExt) {
        if (Test-Path $extDir) { Remove-Item $extDir -Force -ErrorAction SilentlyContinue }
        New-Item -ItemType Directory -Force -Path "$PROFILE_DIR\.antigravity" | Out-Null
        New-Item -ItemType SymbolicLink -Path $extDir -Target $defaultExt -ErrorAction SilentlyContinue | Out-Null
    } else {
        New-Item -ItemType Directory -Force -Path $extDir | Out-Null
    }
}

function Invoke-LaunchProfile {
    param($PROFILE, $ArgsToForward)
    $PROFILE_DIR = "$BASE\$PROFILE"

    if (!(Test-Path $PROFILE_DIR)) {
        Write-Error "Error: profile '$PROFILE' does not exist. Run: multigravity new $PROFILE"
        exit 1
    }

    if ([string]::IsNullOrEmpty($APP) -or !(Test-Path $APP)) {
        Write-Error "Error: Antigravity.exe not found"
        exit 1
    }

    Write-Host "Launching Antigravity profile '$PROFILE'"
    
    # Launch Antigravity with isolated USERPROFILE
    $env:USERPROFILE = $PROFILE_DIR
    $env:APPDATA = "$PROFILE_DIR\AppData\Roaming"
    $env:LOCALAPPDATA = "$PROFILE_DIR\AppData\Local"
    
    if ($ArgsToForward) {
        Start-Process -FilePath $APP -ArgumentList $ArgsToForward
    }
    else {
        Start-Process -FilePath $APP
    }
}

function Invoke-ListProfiles {
    Write-Host "Existing profiles:"
    if (Test-Path $BASE) {
        $profiles = Get-ChildItem -Directory -Path $BASE | Where-Object { $_.PSIsContainer -and $_.Name -ne ".templates" }
        if ($profiles.Count -gt 0) {
            foreach ($p in $profiles) {
                Write-Host $p.Name
            }
        }
        elseif ($profiles -is [System.IO.DirectoryInfo]) {
            Write-Host $profiles.Name
        }
        else {
            Write-Host "(none)"
        }
    }
    else {
        Write-Host "(none)"
    }
}

function Invoke-CreateShortcut {
    param($PROFILE)
    $APP_NAME = "Multigravity $PROFILE"
    $SHORTCUT_PATH = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\$APP_NAME.lnk"
    
    $SCRIPT_PATH = $MyInvocation.MyCommand.Path
    # If script path is empty (e.g. running from prompt), try to find it
    if ([string]::IsNullOrEmpty($SCRIPT_PATH)) {
        $cmdObj = Get-Command multigravity -ErrorAction SilentlyContinue
        if ($cmdObj) { $SCRIPT_PATH = $cmdObj.Source }
    }
    
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($SHORTCUT_PATH)
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -Command `"& '$SCRIPT_PATH' $PROFILE`""
    if ($APP) {
        $Shortcut.IconLocation = "$APP, 0"
    }
    $Shortcut.Save()

    Write-Host "Shortcut created: $SHORTCUT_PATH"
}

function Invoke-NewProfile {
    param($PROFILE, [string[]]$ExtraArgs)

    # Parse flags from extra args
    $authOnly = $false
    $fromTemplate = ""
    $i = 0
    while ($i -lt $ExtraArgs.Count) {
        switch ($ExtraArgs[$i]) {
            "--auth-only" { $authOnly = $true }
            "--from" {
                $i++
                if ($i -lt $ExtraArgs.Count) { $fromTemplate = $ExtraArgs[$i] }
            }
        }
        $i++
    }

    # If profile wasn't the first positional arg, it might be in ExtraArgs
    if ([string]::IsNullOrWhiteSpace($PROFILE)) {
        Write-Error "Error: profile name required"
        exit 1
    }

    Validate-Name $PROFILE

    $PROFILE_DIR = "$BASE\$PROFILE"
    if (Test-Path $PROFILE_DIR) {
        Write-Error "Error: profile '$PROFILE' already exists"
        exit 1
    }

    New-Item -ItemType Directory -Force -Path $BASE | Out-Null

    if ($fromTemplate) {
        $tplPath = "$(Get-TemplatesDir)\$fromTemplate"
        if (!(Test-Path $tplPath)) {
            Write-Error "Error: template '$fromTemplate' does not exist. Run: multigravity template list"
            exit 1
        }
        Write-Host "Creating profile '$PROFILE' from template '$fromTemplate'..."
        Copy-Item -Path $tplPath -Destination $PROFILE_DIR -Recurse
    } elseif ($authOnly) {
        Invoke-CreateAuthOnlyProfile $PROFILE
    } else {
        Invoke-CreateProfile $PROFILE
    }

    Write-Host "Created profile '$PROFILE'"
    Invoke-CreateShortcut $PROFILE
}

function Invoke-DeleteProfile {
    param($PROFILE)
    Validate-Name $PROFILE

    $PROFILE_DIR = "$BASE\$PROFILE"
    if (!(Test-Path $PROFILE_DIR)) {
        Write-Error "Error: profile '$PROFILE' does not exist"
        exit 1
    }

    $confirm = Read-Host "Delete profile '$PROFILE' and all its data? [y/N]"
    if ($confirm -match "^[Yy]$") {
        try {
            Remove-Item -Recurse -Force $PROFILE_DIR -ErrorAction Stop
            
            $SHORTCUT_PATH = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Multigravity $PROFILE.lnk"
            if (Test-Path $SHORTCUT_PATH) {
                Remove-Item -Force $SHORTCUT_PATH
                Write-Host "Removed shortcut: $SHORTCUT_PATH"
            }
            Write-Host "Deleted profile '$PROFILE'"
        } catch {
            Write-Error "Error: could not delete profile directory. Ensure Antigravity is closed and no files are in use."
            Write-Host "Details: $_"
        }
    }
    else {
        Write-Host "Aborted."
    }
}

function Invoke-RenameProfile {
    param($OLD, $NEW)
    Validate-Name $OLD
    Validate-Name $NEW

    $OLD_DIR = "$BASE\$OLD"
    $NEW_DIR = "$BASE\$NEW"

    if (!(Test-Path $OLD_DIR)) {
        Write-Error "Error: profile '$OLD' does not exist"
        exit 1
    }
    if (Test-Path $NEW_DIR) {
        Write-Error "Error: profile '$NEW' already exists"
        exit 1
    }

    Rename-Item -Path $OLD_DIR -NewName $NEW

    $OLD_SHORTCUT = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Multigravity $OLD.lnk"
    if (Test-Path $OLD_SHORTCUT) {
        Remove-Item -Force $OLD_SHORTCUT
        Invoke-CreateShortcut $NEW
    }

    Write-Host "Renamed profile '$OLD' to '$NEW'"
}

function Invoke-CloneProfile {
    param($SRC, $DEST)
    Validate-Name $SRC
    Validate-Name $DEST

    $SRC_DIR = "$BASE\$SRC"
    $DEST_DIR = "$BASE\$DEST"

    if (!(Test-Path $SRC_DIR)) {
        Write-Error "Error: source profile '$SRC' does not exist"
        exit 1
    }
    if (Test-Path $DEST_DIR) {
        Write-Error "Error: destination profile '$DEST' already exists"
        exit 1
    }

    Write-Host "Cloning profile '$SRC' to '$DEST'..."
    Copy-Item -Path $SRC_DIR -Destination $DEST_DIR -Recurse
    Invoke-CreateShortcut $DEST

    Write-Host "Successfully cloned '$SRC' to '$DEST'"
}

function Get-FolderSize {
    param($Path)
    $files = Get-ChildItem $Path -Recurse -File -ErrorAction SilentlyContinue
    $size = 0
    if ($files) {
        $size = ($files | Measure-Object -Property Length -Sum).Sum
    }
    if ($size -ge 1GB) { "{0:N2} GB" -f ($size / 1GB) }
    elseif ($size -ge 1MB) { "{0:N2} MB" -f ($size / 1MB) }
    elseif ($size -ge 1KB) { "{0:N2} KB" -f ($size / 1KB) }
    else { "$size B" }
}

function Invoke-ProfileStats {
    if (!(Test-Path $BASE)) {
        Write-Host "No profiles found."
        return
    }

    Write-Host "Profile Storage Usage:"
    Write-Host ("{0,-20} {1,-10} {2,-10}" -f "PROFILE", "SIZE", "EXTENSIONS")
    Write-Host ("{0,-20} {1,-10} {2,-10}" -f "-------", "----", "----------")

    $profiles = Get-ChildItem -Directory -Path $BASE | Where-Object { $_.Name -ne ".templates" }
    foreach ($p in $profiles) {
        $size = Get-FolderSize $p.FullName
        $extPath = Join-Path $p.FullName ".antigravity\extensions"
        $extCount = if (Test-Path $extPath) { (Get-ChildItem $extPath).Count } else { 0 }
        Write-Host ("{0,-20} {1,-10} {2,-10}" -f $p.Name, $size, $extCount)
    }

    Write-Host ""
    $total = Get-FolderSize $BASE
    Write-Host "Total usage: $total"
}

function Invoke-DoctorCli {
    $errors = 0
    $warnings = 0

    Write-Host "Checking multigravity environment..."

    # 1. Antigravity Installation
    if ($APP -and (Test-Path $APP)) {
        Write-Host "  [OK] Antigravity: Found at $APP"
    } else {
        Write-Host "  [FAIL] Antigravity: Not found. Ensure it is installed or set MULTIGRAVITY_APP."
        $errors++
    }

    # 2. Path Check
    $cmdObj = Get-Command multigravity -ErrorAction SilentlyContinue
    if ($cmdObj) {
        Write-Host "  [OK] Global Binary: $($cmdObj.Source)"
    } else {
        Write-Host "  [WARN] Global Binary: Not found in PATH. Run install script or update PATH."
        $warnings++
    }

    # 3. Base Directory
    if (Test-Path $BASE) {
        # Check writability
        try {
            $testFile = Join-Path $BASE ".write-test"
            New-Item -ItemType File -Path $testFile -Force -ErrorAction Stop | Out-Null
            Remove-Item $testFile -Force
            Write-Host "  [OK] Profile storage: $BASE (writable)"
        } catch {
            Write-Host "  [FAIL] Profile storage: $BASE (NOT writable)"
            $errors++
        }
    } else {
        Write-Host "  [WARN] Profile storage: $BASE (Not yet created)"
    }

    Write-Host ""
    if ($errors -eq 0) {
        if ($warnings -eq 0) {
            Write-Host "Your environment looks perfect!"
        } else {
            Write-Host "Found $warnings warning(s). Multigravity should still work, but some features might be degraded."
        }
    } else {
        Write-Host "Found $errors error(s) and $warnings warning(s). Please fix the errors above."
    }
}

function Invoke-UpdateCli {
    $script_url = "https://raw.githubusercontent.com/Pulkit7070/multigravity-pro/main/multigravity.ps1"
    $checksum_url = "https://raw.githubusercontent.com/Pulkit7070/multigravity-pro/main/multigravity.ps1.sha256"
    $target = $MyInvocation.MyCommand.Path
    if ([string]::IsNullOrEmpty($target)) {
        $cmdObj = Get-Command multigravity -ErrorAction SilentlyContinue
        if ($cmdObj) { $target = $cmdObj.Source }
    }

    if ([string]::IsNullOrEmpty($target)) {
        Write-Error "Error: could not determine script path for update"
        exit 1
    }

    Write-Host "Updating multigravity from $script_url ..."
    try {
        $tmp = "$target.tmp"
        $checksumTmp = "$target.tmp.sha256"
        $backup = "$target.bak"

        Invoke-WebRequest -Uri $script_url -OutFile $tmp -UseBasicParsing -ErrorAction Stop
        Invoke-WebRequest -Uri $checksum_url -OutFile $checksumTmp -UseBasicParsing -ErrorAction Stop

        $expectedLine = Get-Content -Path $checksumTmp -TotalCount 1 -ErrorAction Stop
        $expected = (($expectedLine -split '\s+')[0]).Trim()
        if ([string]::IsNullOrWhiteSpace($expected)) {
            throw "Invalid checksum file format."
        }

        $actual = (Get-FileHash -Algorithm SHA256 -Path $tmp -ErrorAction Stop).Hash.ToLowerInvariant()
        if ($actual -ne $expected.ToLowerInvariant()) {
            throw "Checksum verification failed."
        }

        if (Test-Path $target) {
            Copy-Item -Path $target -Destination $backup -Force
        }

        $content = Get-Content -Path $tmp -Raw -ErrorAction Stop
        [System.IO.File]::WriteAllText($target, $content, [System.Text.Encoding]::UTF8)
        if (Test-Path $backup) { Remove-Item -Force $backup }
        if (Test-Path $tmp) { Remove-Item -Force $tmp }
        if (Test-Path $checksumTmp) { Remove-Item -Force $checksumTmp }
        Write-Host "Successfully updated multigravity!"
    } catch {
        if (Test-Path "$target.bak") {
            Move-Item -Path "$target.bak" -Destination $target -Force
        }
        if (Test-Path "$target.tmp") { Remove-Item -Force "$target.tmp" -ErrorAction SilentlyContinue }
        if (Test-Path "$target.tmp.sha256") { Remove-Item -Force "$target.tmp.sha256" -ErrorAction SilentlyContinue }
        Write-Error "Error: update failed: $_"
        exit 1
    }
}

function Invoke-HelpCompletion {
    Write-Host "To enable autocompletion in PowerShell, add the following to your `$PROFILE:"
    Write-Host ""
    Write-Host '  Invoke-Expression (& multigravity completion powershell)'
    Write-Host ""
    Write-Host "Then restart your terminal or run: . `$PROFILE"
}

function Invoke-GenerateCompletion {
    param($shell)
    if ($shell -eq "powershell") {
        @"
Register-ArgumentCompleter -Native -CommandName multigravity -ScriptBlock {
    param(`$wordToComplete, `$commandAst, `$cursorPosition)
    `$opts = @('new', 'list', 'status', 'rename', 'delete', 'clone', 'template', 'export', 'import', 'update', 'doctor', 'stats', 'completion', 'help')
    `$profiles = if (Test-Path '$BASE') { Get-ChildItem -Directory -Path '$BASE' | Select-Object -ExpandProperty Name } else { @() }
    (`$opts + `$profiles) | Where-Object { `$_ -like "`$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new(`$_, `$_, 'ParameterValue', `$_)
    }
}
"@
    } else {
        Write-Host "Only 'powershell' completion is supported on Windows."
    }
}

# ─── Template commands ────────────────────────────────────────────────────────

function Invoke-TemplateSave {
    param($PROFILE, $TPL_NAME)
    Validate-Name $PROFILE
    Validate-Name $TPL_NAME

    $PROFILE_DIR = "$BASE\$PROFILE"
    if (!(Test-Path $PROFILE_DIR)) {
        Write-Error "Error: profile '$PROFILE' does not exist"
        exit 1
    }

    $tplDir = Get-TemplatesDir
    $tplPath = "$tplDir\$TPL_NAME"

    if (Test-Path $tplPath) {
        Write-Error "Error: template '$TPL_NAME' already exists"
        exit 1
    }

    New-Item -ItemType Directory -Force -Path $tplDir | Out-Null
    Write-Host "Saving profile '$PROFILE' as template '$TPL_NAME'..."
    Copy-Item -Path $PROFILE_DIR -Destination $tplPath -Recurse

    # Remove auth-only marker from template
    $marker = "$tplPath\.auth-only"
    if (Test-Path $marker) { Remove-Item $marker -Force }

    Write-Host "Template '$TPL_NAME' saved"
}

function Invoke-TemplateList {
    $tplDir = Get-TemplatesDir
    Write-Host "Available templates:"

    if (!(Test-Path $tplDir)) {
        Write-Host "  (none)"
        return
    }

    $templates = Get-ChildItem -Directory -Path $tplDir -ErrorAction SilentlyContinue
    if ($templates.Count -eq 0) {
        Write-Host "  (none)"
        return
    }

    foreach ($t in $templates) {
        $size = Get-FolderSize $t.FullName
        Write-Host ("  {0}  ({1})" -f $t.Name, $size)
    }
}

function Invoke-TemplateDelete {
    param($TPL_NAME)
    Validate-Name $TPL_NAME

    $tplPath = "$(Get-TemplatesDir)\$TPL_NAME"
    if (!(Test-Path $tplPath)) {
        Write-Error "Error: template '$TPL_NAME' does not exist"
        exit 1
    }

    Remove-Item -Recurse -Force $tplPath
    Write-Host "Deleted template '$TPL_NAME'"
}

# ─── Status command ───────────────────────────────────────────────────────────

function Invoke-StatusProfiles {
    if (!(Test-Path $BASE)) {
        Write-Host "No profiles found."
        return
    }

    Write-Host ("{0,-16} {1,-10} {2,-12} {3,-20} {4}" -f "PROFILE", "STATUS", "TYPE", "LAST USED", "SIZE")
    Write-Host ("{0,-16} {1,-10} {2,-12} {3,-20} {4}" -f "-------", "------", "----", "---------", "----")

    $profiles = Get-ChildItem -Directory -Path $BASE -ErrorAction SilentlyContinue
    foreach ($p in $profiles) {
        # Skip .templates directory
        if ($p.Name -eq ".templates") { continue }

        # Check if running
        $status = "stopped"
        $dataDir = "$($p.FullName)\AppData\Roaming\Antigravity"
        $procs = Get-Process -Name "Antigravity" -ErrorAction SilentlyContinue
        if ($procs) {
            foreach ($proc in $procs) {
                try {
                    $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($proc.Id)" -ErrorAction SilentlyContinue).CommandLine
                    if ($cmdLine -and $cmdLine -like "*$($p.Name)*") {
                        $status = "running"
                        break
                    }
                } catch { }
            }
        }

        # Type
        $ptype = "full"
        if (Test-Path "$($p.FullName)\.auth-only") {
            $ptype = "auth-only"
        }

        # Last used
        $lastUsed = $p.LastWriteTime.ToString("yyyy-MM-dd HH:mm")

        # Size
        $size = Get-FolderSize $p.FullName

        # Color for running
        if ($status -eq "running") {
            Write-Host ("{0,-16} " -f $p.Name) -NoNewline
            Write-Host ("{0,-10} " -f $status) -NoNewline -ForegroundColor Green
            Write-Host ("{0,-12} {1,-20} {2}" -f $ptype, $lastUsed, $size)
        } else {
            Write-Host ("{0,-16} {1,-10} {2,-12} {3,-20} {4}" -f $p.Name, $status, $ptype, $lastUsed, $size)
        }
    }
}

# ─── Export / Import ──────────────────────────────────────────────────────────

function Invoke-ExportProfile {
    param($PROFILE, $OutputPath)
    Validate-Name $PROFILE

    $PROFILE_DIR = "$BASE\$PROFILE"
    if (!(Test-Path $PROFILE_DIR)) {
        Write-Error "Error: profile '$PROFILE' does not exist"
        exit 1
    }

    if ([string]::IsNullOrWhiteSpace($OutputPath)) {
        $OutputPath = ".\$PROFILE.zip"
    }

    Write-Host "Exporting profile '$PROFILE'..."
    Compress-Archive -Path $PROFILE_DIR -DestinationPath $OutputPath -Force
    Write-Host "Exported to $OutputPath"
}

function Invoke-ImportProfile {
    param($ArchivePath, $PROFILE)

    if ([string]::IsNullOrWhiteSpace($ArchivePath)) {
        Write-Error "Error: usage: multigravity import <archive> [profile-name]"
        exit 1
    }

    if (!(Test-Path $ArchivePath)) {
        Write-Error "Error: file '$ArchivePath' not found"
        exit 1
    }

    # Auto-detect profile name from archive if not provided
    if ([string]::IsNullOrWhiteSpace($PROFILE)) {
        $PROFILE = [System.IO.Path]::GetFileNameWithoutExtension($ArchivePath)
    }

    Validate-Name $PROFILE

    $PROFILE_DIR = "$BASE\$PROFILE"
    if (Test-Path $PROFILE_DIR) {
        Write-Error "Error: profile '$PROFILE' already exists"
        exit 1
    }

    New-Item -ItemType Directory -Force -Path $BASE | Out-Null

    Write-Host "Importing profile as '$PROFILE'..."

    # Extract to temp, then move to correct name
    $tempDir = "$BASE\_import_temp_$(Get-Random)"
    Expand-Archive -Path $ArchivePath -DestinationPath $tempDir -Force

    $extracted = Get-ChildItem -Directory -Path $tempDir
    if ($extracted.Count -eq 1) {
        # Archive had a single root dir — move it
        Move-Item -Path $extracted[0].FullName -Destination $PROFILE_DIR
        Remove-Item $tempDir -Recurse -Force
    } else {
        # Archive had loose files — rename temp dir
        Rename-Item -Path $tempDir -NewName $PROFILE
    }

    Invoke-CreateShortcut $PROFILE
    Write-Host "Imported profile '$PROFILE'"
}

switch ($cmd) {
    "new" {
        $extraArgs = @()
        if ($arg2) { $extraArgs += $arg2 }
        if ($ForwardArgs) { $extraArgs += $ForwardArgs }
        Invoke-NewProfile $arg1 $extraArgs
    }
    "list" {
        Invoke-ListProfiles
    }
    "status" {
        Invoke-StatusProfiles
    }
    "rename" {
        Invoke-RenameProfile $arg1 $arg2
    }
    "delete" {
        Invoke-DeleteProfile $arg1
    }
    "clone" {
        Invoke-CloneProfile $arg1 $arg2
    }
    "template" {
        switch ($arg1) {
            "save" { Invoke-TemplateSave $arg2 $ForwardArgs[0] }
            "list" { Invoke-TemplateList }
            "delete" { Invoke-TemplateDelete $arg2 }
            default {
                Write-Error "Error: usage: multigravity template <save|list|delete>"
                exit 1
            }
        }
    }
    "export" {
        Invoke-ExportProfile $arg1 $arg2
    }
    "import" {
        Invoke-ImportProfile $arg1 $arg2
    }
    "update" {
        Invoke-UpdateCli
    }
    "doctor" {
        Invoke-DoctorCli
    }
    "stats" {
        Invoke-ProfileStats
    }
    "completion" {
        if ($arg1) {
            Invoke-GenerateCompletion $arg1
        } else {
            Invoke-HelpCompletion
        }
    }
    "help" {
        Write-Usage
    }
    "--help" {
        Write-Usage
    }
    "-h" {
        Write-Usage
    }
    "" {
        Write-Usage
        exit 1
    }
    default {
        $AllArgs = @()
        if ($arg1) { $AllArgs += $arg1 }
        if ($arg2) { $AllArgs += $arg2 }
        if ($ForwardArgs) { $AllArgs += $ForwardArgs }
        
        Invoke-LaunchProfile $cmd $AllArgs
    }
}
