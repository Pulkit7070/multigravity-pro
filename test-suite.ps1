$ErrorActionPreference = 'Continue'
$testDir = 'C:\Users\Asus\Desktop\project\mg-prodtest'
$env:MULTIGRAVITY_HOME = $testDir
$script = 'C:\Users\Asus\Desktop\project\multigravity-pro\multigravity.ps1'
$pass = 0; $fail = 0

function Test-Case($name, $scriptBlock) {
    Write-Host "TEST: $name" -NoNewline
    try {
        $result = & $scriptBlock 2>&1
        $output = $result -join "`n"
        Write-Host " -> PASS" -ForegroundColor Green
        $script:pass++
        return $output
    } catch {
        Write-Host " -> FAIL: $_" -ForegroundColor Red
        $script:fail++
        return ''
    }
}

# ─── HELP ───
Test-Case 'help shows all new commands' {
    $out = & $script help *>&1 | Out-String
    if ($out -notmatch 'auth-only') { throw 'missing --auth-only' }
    if ($out -notmatch 'template') { throw 'missing template' }
    if ($out -notmatch 'export') { throw 'missing export' }
    if ($out -notmatch 'import') { throw 'missing import' }
    if ($out -notmatch 'status') { throw 'missing status' }
}

# ─── NEW (basic) ───
Test-Case 'new creates full profile' {
    & $script new prod1 *>&1 | Out-Null
    if (!(Test-Path "$testDir\prod1")) { throw 'dir not created' }
    if (!(Test-Path "$testDir\prod1\.antigravity\extensions")) { throw 'extensions dir missing' }
    if (!(Test-Path "$testDir\prod1\AppData\Roaming")) { throw 'AppData missing' }
}

Test-Case 'new second profile' {
    & $script new prod2 *>&1 | Out-Null
    if (!(Test-Path "$testDir\prod2")) { throw 'dir not created' }
}

Test-Case 'new duplicate name blocked' {
    $out = & $script new prod1 *>&1 | Out-String
    if ($out -notmatch 'already exists') { throw 'no duplicate error' }
}

Test-Case 'new invalid name blocked (special chars)' {
    $out = & $script new '!bad' *>&1 | Out-String
    if ($out -notmatch 'alphanumeric') { throw 'no validation error' }
}

Test-Case 'new invalid name blocked (path traversal)' {
    $out = & $script new '../escape' *>&1 | Out-String
    if ($out -notmatch 'alphanumeric') { throw 'no validation error' }
}

Test-Case 'new empty name blocked' {
    $out = & $script new '' *>&1 | Out-String
    if ($out -notmatch 'name required') { throw 'no empty name error' }
}

# ─── NEW --auth-only ───
Test-Case 'new --auth-only creates marker + user dir' {
    & $script new authprof --auth-only *>&1 | Out-Null
    if (!(Test-Path "$testDir\authprof\.auth-only")) { throw 'marker missing' }
    if (!(Test-Path "$testDir\authprof\AppData\Roaming\Antigravity\User")) { throw 'User dir missing' }
}

Test-Case 'new --auth-only duplicate blocked' {
    $out = & $script new authprof --auth-only *>&1 | Out-String
    if ($out -notmatch 'already exists') { throw 'no duplicate error' }
}

# ─── LIST ───
Test-Case 'list shows profiles' {
    $out = & $script list *>&1 | Out-String
    if ($out -notmatch 'prod1') { throw 'prod1 missing' }
    if ($out -notmatch 'prod2') { throw 'prod2 missing' }
    if ($out -notmatch 'authprof') { throw 'authprof missing' }
}

Test-Case 'list hides .templates dir' {
    New-Item -ItemType Directory -Force "$testDir\.templates\dummy" | Out-Null
    $out = & $script list *>&1 | Out-String
    if ($out -match '\.templates') { throw '.templates should be hidden' }
    Remove-Item "$testDir\.templates\dummy" -Recurse -Force
}

# ─── STATUS ───
Test-Case 'status shows correct types' {
    $out = & $script status *>&1 | Out-String
    if ($out -notmatch 'prod1\s+stopped\s+full') { throw 'prod1 not showing as full' }
    if ($out -notmatch 'authprof\s+stopped\s+auth-only') { throw 'authprof not showing as auth-only' }
}

Test-Case 'status shows all profiles' {
    $out = & $script status *>&1 | Out-String
    if ($out -notmatch 'prod2') { throw 'prod2 missing from status' }
}

# ─── CLONE ───
Test-Case 'clone creates copy' {
    & $script clone prod1 prod1-copy *>&1 | Out-Null
    if (!(Test-Path "$testDir\prod1-copy")) { throw 'clone not created' }
    if (!(Test-Path "$testDir\prod1-copy\.antigravity\extensions")) { throw 'extensions missing in clone' }
}

Test-Case 'clone nonexistent source blocked' {
    $out = & $script clone ghost cloned *>&1 | Out-String
    if ($out -notmatch 'does not exist') { throw 'no error for nonexistent source' }
}

Test-Case 'clone duplicate dest blocked' {
    $out = & $script clone prod1 prod2 *>&1 | Out-String
    if ($out -notmatch 'already exists') { throw 'no error for existing dest' }
}

# ─── RENAME ───
Test-Case 'rename works' {
    & $script new rename-me *>&1 | Out-Null
    & $script rename rename-me renamed *>&1 | Out-Null
    if (Test-Path "$testDir\rename-me") { throw 'old dir still exists' }
    if (!(Test-Path "$testDir\renamed")) { throw 'new dir not created' }
}

Test-Case 'rename nonexistent blocked' {
    $out = & $script rename ghost newname *>&1 | Out-String
    if ($out -notmatch 'does not exist') { throw 'no error' }
}

# ─── TEMPLATE SAVE ───
Test-Case 'template save works' {
    & $script template save prod1 my-tpl *>&1 | Out-Null
    if (!(Test-Path "$testDir\.templates\my-tpl")) { throw 'template not saved' }
}

Test-Case 'template save strips auth-only marker' {
    & $script template save authprof auth-tpl *>&1 | Out-Null
    if (Test-Path "$testDir\.templates\auth-tpl\.auth-only") { throw 'auth-only marker should be stripped from template' }
}

Test-Case 'template save duplicate blocked' {
    $out = & $script template save prod1 my-tpl *>&1 | Out-String
    if ($out -notmatch 'already exists') { throw 'no duplicate error' }
}

Test-Case 'template save nonexistent profile blocked' {
    $out = & $script template save ghost tpl-x *>&1 | Out-String
    if ($out -notmatch 'does not exist') { throw 'no error' }
}

# ─── TEMPLATE LIST ───
Test-Case 'template list shows saved templates' {
    $out = & $script template list *>&1 | Out-String
    if ($out -notmatch 'my-tpl') { throw 'my-tpl missing from list' }
    if ($out -notmatch 'auth-tpl') { throw 'auth-tpl missing from list' }
}

# ─── NEW --from template ───
Test-Case 'new --from template creates profile' {
    & $script new from-tpl --from my-tpl *>&1 | Out-Null
    if (!(Test-Path "$testDir\from-tpl")) { throw 'profile not created from template' }
}

Test-Case 'new --from nonexistent template blocked' {
    $out = & $script new ghost-prof --from ghost-tpl *>&1 | Out-String
    if ($out -notmatch 'does not exist') { throw 'no error' }
}

Test-Case 'new --from duplicate name blocked' {
    $out = & $script new from-tpl --from my-tpl *>&1 | Out-String
    if ($out -notmatch 'already exists') { throw 'no duplicate error' }
}

# ─── TEMPLATE DELETE ───
Test-Case 'template delete works' {
    & $script template save prod1 del-me *>&1 | Out-Null
    & $script template delete del-me *>&1 | Out-Null
    if (Test-Path "$testDir\.templates\del-me") { throw 'template still exists after delete' }
}

Test-Case 'template delete nonexistent blocked' {
    $out = & $script template delete nope *>&1 | Out-String
    if ($out -notmatch 'does not exist') { throw 'no error' }
}

# ─── TEMPLATE bare ───
Test-Case 'template no subcommand shows error' {
    $out = & $script template '' *>&1 | Out-String
    if ($out -notmatch 'usage') { throw 'no usage message' }
}

# ─── EXPORT ───
Test-Case 'export creates zip file' {
    & $script export prod1 "$testDir\prod1-export.zip" *>&1 | Out-Null
    if (!(Test-Path "$testDir\prod1-export.zip")) { throw 'zip not created' }
}

Test-Case 'export default path (current dir)' {
    Push-Location $testDir
    & $script export prod2 *>&1 | Out-Null
    Pop-Location
    if (!(Test-Path "$testDir\prod2.zip")) { throw 'default zip not created' }
}

Test-Case 'export nonexistent profile blocked' {
    $out = & $script export nope *>&1 | Out-String
    if ($out -notmatch 'does not exist') { throw 'no error' }
}

# ─── IMPORT ───
Test-Case 'import with explicit name' {
    & $script import "$testDir\prod1-export.zip" imported1 *>&1 | Out-Null
    if (!(Test-Path "$testDir\imported1")) { throw 'import not created' }
}

Test-Case 'import auto-detect name from filename' {
    & $script import "$testDir\prod2.zip" imported2 *>&1 | Out-Null
    if (!(Test-Path "$testDir\imported2")) { throw 'import not created' }
}

Test-Case 'import duplicate name blocked' {
    $out = & $script import "$testDir\prod1-export.zip" imported1 *>&1 | Out-String
    if ($out -notmatch 'already exists') { throw 'no duplicate error' }
}

Test-Case 'import nonexistent file blocked' {
    $out = & $script import 'C:\nope\fake.zip' test *>&1 | Out-String
    if ($out -notmatch 'not found') { throw 'no error' }
}

Test-Case 'import no args blocked' {
    $out = & $script import '' *>&1 | Out-String
    if ($out -notmatch 'usage') { throw 'no usage message' }
}

# ─── DOCTOR ───
Test-Case 'doctor runs' {
    $out = & $script doctor *>&1 | Out-String
    if ($out -notmatch 'Checking|environment') { throw 'doctor did not run' }
}

# ─── STATS ───
Test-Case 'stats shows profiles with sizes' {
    $out = & $script stats *>&1 | Out-String
    if ($out -notmatch 'prod1') { throw 'prod1 missing' }
    if ($out -notmatch 'Total usage') { throw 'total missing' }
}

# ─── FINAL STATUS ───
Test-Case 'final status - all profiles correct types' {
    $out = & $script status *>&1 | Out-String
    if ($out -notmatch 'auth-only') { throw 'missing auth-only type' }
    if ($out -notmatch '\bfull\b') { throw 'missing full type' }
}

# ─── SUMMARY ───
Write-Host ''
Write-Host "==============================="
Write-Host "  PASSED: $pass" -ForegroundColor Green
Write-Host "  FAILED: $fail" -ForegroundColor $(if ($fail -gt 0) { 'Red' } else { 'Green' })
Write-Host "  TOTAL:  $($pass + $fail)"
Write-Host "==============================="

# Cleanup
Remove-Item "$testDir" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Multigravity *.lnk" -Force -ErrorAction SilentlyContinue

if ($fail -gt 0) { exit 1 } else { exit 0 }
