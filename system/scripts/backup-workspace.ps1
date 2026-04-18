# Backup .openclaw system + workspace to GitHub
$OpenClaw = "$env:USERPROFILE\.openclaw"
$TempClone = "$env:TEMP\openclaw_backup_$(Get-Date -Format 'yyyyMMddHHmmss')"

# Clone GitHub repo to temp dir
git clone "https://github.com/shumi-123/openclaw-mission-control.git" $TempClone --quiet 2>&1 | Out-Null
if (-not (Test-Path $TempClone)) {
    Write-Host "Clone failed"
    exit 1
}

# Copy workspace files to repo root
@("AGENTS.md","SOUL.md","IDENTITY.md","USER.md","TOOLS.md","HEARTBEAT.md") | ForEach-Object {
    $src = "$OpenClaw\workspace\$_"
    if (Test-Path $src) { Copy-Item $src "$TempClone\$_" -Force }
}

# Copy memory (exclude .dreams)
if (Test-Path "$OpenClaw\workspace\memory") {
    Get-ChildItem "$OpenClaw\workspace\memory" -Recurse -Directory | ForEach-Object { 
        if ($_.Name -ne '.dreams') { Copy-Item $_.FullName "$TempClone\memory\$($_.Name)" -Recurse -Force } 
    }
    Get-ChildItem "$OpenClaw\workspace\memory\*.md" | Copy-Item -Destination "$TempClone\memory\" -Force
}

# Copy system files to system/ subdir
$sysDest = "$TempClone\system"
New-Item -ItemType Directory -Force -Path $sysDest | Out-Null
@("openclaw.json","cron","scripts","identity") | ForEach-Object {
    $src = "$OpenClaw\$_"
    if (Test-Path $src) { Copy-Item $src "$sysDest\$_" -Recurse -Force }
}

Set-Location $TempClone

# Remove .dreams before commit
if (Test-Path "$TempClone\memory\.dreams") { Remove-Item "$TempClone\memory\.dreams" -Recurse -Force }

# Remove any embedded repos
git rm -rf --cached github 2>&1 | Out-Null
git commit -m "System + workspace backup $(Get-Date -Format 'yyyy-MM-dd HH:mm')" 2>&1 | Out-Null
git push origin master 2>&1 | Out-Null

# Cleanup
Set-Location "$env:USERPROFILE"
Remove-Item $TempClone -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Backup done at $(Get-Date -Format 'HH:mm:ss')"
