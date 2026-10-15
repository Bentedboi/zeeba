# Export the game and publish it as a new GitHub release on Bentedboi/zeeba.
#   .\publish.ps1 "what changed"
# Needs a GitHub token saved in %USERPROFILE%\.rocket-leauge-github-token (kept outside the project).

param([string]$Notes = "")
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-Location $PSScriptRoot

$repo = "Bentedboi/zeeba"
$godot = "C:\Users\JulianJimenez\Desktop\Godot.exe"
$tokenFile = Join-Path $env:USERPROFILE ".rocket-leauge-github-token"
if (-not (Test-Path $tokenFile)) { throw "No GitHub token. Save one in $tokenFile." }
$token = (Get-Content $tokenFile -Raw).Trim()
$headers = @{ Authorization = "Bearer $token"; Accept = "application/vnd.github+json"; "X-GitHub-Api-Version" = "2022-11-28" }

# Next version = latest release tag + 1 (v1 if there are none yet).
$version = 1
$releases = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases" -Headers $headers
foreach ($r in $releases) { if ($r.tag_name -match '^v(\d+)$' -and [int]$Matches[1] -ge $version) { $version = [int]$Matches[1] + 1 } }

Write-Host "Exporting version $version..."
if (Test-Path build) { Remove-Item -Recurse -Force build }
New-Item -ItemType Directory -Force build\game, build\release | Out-Null
& $godot --headless --path . --export-release "Windows Desktop" "build/game/Princess Zeeba.exe" | Out-Host
if (-not (Test-Path "build\game\Princess Zeeba.exe")) { throw "Export failed (see Godot output above)." }
$zip = "build\release\Princess-Zeeba-Windows.zip"
Compress-Archive -Path build\game\* -DestinationPath $zip

Write-Host "Creating GitHub release v$version on $repo..."
$body = @{ tag_name = "v$version"; name = "Version $version"; body = $Notes; make_latest = "true" } | ConvertTo-Json
$release = Invoke-RestMethod -Method Post -Uri "https://api.github.com/repos/$repo/releases" -Headers $headers -Body $body -ContentType "application/json"
try {
    $upload = $release.upload_url -replace "\{.*\}$", ""
    $f = Get-Item $zip
    Write-Host "  uploading $($f.Name) ($([math]::Round($f.Length / 1MB, 1)) MB)"
    Invoke-RestMethod -Method Post -Uri "$($upload)?name=$($f.Name)" -Headers $headers -InFile $f.FullName -ContentType "application/zip" | Out-Null
} catch {
    try {
        Invoke-RestMethod -Method Delete -Uri $release.url -Headers $headers | Out-Null
        Invoke-RestMethod -Method Delete -Uri "https://api.github.com/repos/$repo/git/refs/tags/v$version" -Headers $headers | Out-Null
    } catch { Write-Warning "Couldn't remove the half-made release v$version - delete it on GitHub." }
    throw
}

Write-Host ""
Write-Host "Published version $version."
Write-Host "Download: https://github.com/$repo/releases/latest/download/Princess-Zeeba-Windows.zip"
