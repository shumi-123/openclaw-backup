# GitHub backup script using gh api (bypasses git push)
$token = gh auth token
$headers = @{"Authorization"="Bearer $token"; "Accept"="application/vnd.github.v3+json"}

$repo = "shumi-123/openclaw-mission-control"
$baseDir = "$env:USERPROFILE\.openclaw"

# Files to backup with their dest paths
$files = @(
    @{src="$baseDir\openclaw.json"; dest="system/openclaw.json"},
    @{src="$baseDir\cron\jobs.json"; dest="system/cron/jobs.json"},
    @{src="$baseDir\scripts\backup-workspace.ps1"; dest="system/scripts/backup-workspace.ps1"},
    @{src="$baseDir\scripts\gh-backup.ps1"; dest="system/scripts/gh-backup.ps1"},
    @{src="$baseDir\scripts\poll_tencent_doc.js"; dest="system/scripts/poll_tencent_doc.js"},
    @{src="$baseDir\workspace\AGENTS.md"; dest="AGENTS.md"},
    @{src="$baseDir\workspace\SOUL.md"; dest="SOUL.md"},
    @{src="$baseDir\workspace\IDENTITY.md"; dest="IDENTITY.md"},
    @{src="$baseDir\workspace\USER.md"; dest="USER.md"},
    @{src="$baseDir\workspace\TOOLS.md"; dest="TOOLS.md"},
    @{src="$baseDir\workspace\HEARTBEAT.md"; dest="HEARTBEAT.md"},
    @{src="$baseDir\workspace\memory\2026-04-18.md"; dest="memory/2026-04-18.md"},
    @{src="$baseDir\workspace\memory\2026-04-17.md"; dest="memory/2026-04-17.md"}
)

function Upload-File($src, $dest) {
    $uri = "https://api.github.com/repos/$repo/contents/$dest"
    
    # Get current SHA if exists
    $sha = $null
    try {
        $existing = Invoke-RestMethod -Uri $uri -Headers $headers -Method GET
        $sha = $existing.sha
    } catch { }
    
    $base64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($src))
    $body = @{message="Backup $dest"; content=$base64; branch="main"} | ConvertTo-Json -Compress
    
    if ($sha) { $body = @{message="Update $dest"; content=$base64; branch="main"; sha=$sha} | ConvertTo-Json -Compress }
    
    try {
        $r = Invoke-WebRequest -Uri $uri -Method PUT -Headers $headers -Body $body -ContentType "application/json" -TimeoutSec 15
        Write-Host "OK: $dest"
    } catch {
        Write-Host "FAIL: $dest - $($_.Exception.Message)"
    }
}

foreach ($f in $files) {
    if (Test-Path $f.src) {
        Upload-File $f.src $f.dest
    }
}

Write-Host "Backup completed at $(Get-Date -Format 'HH:mm:ss')"
