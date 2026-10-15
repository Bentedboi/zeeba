# Publish a new version of the game to GitHub Releases (Bentedboi/zeeba). Players' games
# download it the next time they start (scripts/boot.gd), same as Rocket Leauge and F1 Game.
#   .\publish.ps1 "what changed"
#   .\publish.ps1 -ExportOnly        (build into build\ without uploading, to test)
# Needs a GitHub token saved in %USERPROFILE%\.rocket-leauge-github-token (kept outside the
# project so it never ships) with Contents read/write on the repo in release.json.

param([string]$Notes = "", [switch]$ExportOnly)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-Location $PSScriptRoot

$godot = "C:\Users\JulianJimenez\Desktop\Godot.exe"
$tokenFile = Join-Path $env:USERPROFILE ".rocket-leauge-github-token"
$utf8 = New-Object System.Text.UTF8Encoding($false)   # Godot's JSON parser doesn't like a BOM

function Write-Json($path, $obj) {
    [IO.File]::WriteAllText((Join-Path $PSScriptRoot $path), ($obj | ConvertTo-Json -Compress), $utf8)
}

$rel = Get-Content release.json -Raw | ConvertFrom-Json
if (-not $rel.repo) { throw "Set `"repo`" in release.json to your GitHub repo, like `"yourname/zeeba`"." }
if (-not $ExportOnly) {
    if (-not (Test-Path $tokenFile)) { throw "No GitHub token. Save one in $tokenFile (see the top of publish.ps1)." }
    $token = (Get-Content $tokenFile -Raw).Trim()
    $headers = @{ Authorization = "Bearer $token"; Accept = "application/vnd.github+json"; "X-GitHub-Api-Version" = "2022-11-28" }
}

$oldVersion = [int]$rel.version
$version = $oldVersion + 1
$godotVersion = ((Get-Item $godot).VersionInfo.ProductVersion -split "\.")[0..2] -join "."   # Godot.exe --version prints nothing to PowerShell
if ($godotVersion -notmatch '^\d+\.\d+\.\d+$') { throw "Couldn't read the Godot version from $godot." }
$release = $null
try {
    Write-Json "release.json" @{ version = $version; repo = $rel.repo }

    Write-Host "Exporting version $version..."
    if (Test-Path build) { Remove-Item -Recurse -Force build }
    New-Item -ItemType Directory -Force build\game, build\release | Out-Null
    & $godot --headless --path . --export-release "Windows Desktop" "build/game/Princess Zeeba.exe" | Out-Host
    if (-not (Test-Path "build\game\Princess Zeeba.pck")) { throw "Export failed (see Godot output above)." }

    Copy-Item "build\game\Princess Zeeba.pck" build\release\game.pck
    $pck = Get-Item build\release\game.pck
    Write-Json "build\release\version.json" @{
        version = $version; godot = $godotVersion; pck = "game.pck"; size = $pck.Length
        sha256 = (Get-FileHash $pck.FullName -Algorithm SHA256).Hash.ToLower()
    }
    Compress-Archive -Path build\game\* -DestinationPath build\release\Princess-Zeeba-Windows.zip
    if ($ExportOnly) {
        Write-Json "release.json" @{ version = $oldVersion; repo = $rel.repo }
        Write-Host "Exported to build\ (not published)."
        exit 0
    }

    Write-Host "Creating GitHub release v$version on $($rel.repo)..."
    $body = @{ tag_name = "v$version"; name = "Version $version"; body = $Notes; make_latest = "true" } | ConvertTo-Json
    $release = Invoke-RestMethod -Method Post -Uri "https://api.github.com/repos/$($rel.repo)/releases" -Headers $headers -Body $body -ContentType "application/json"
    $upload = $release.upload_url -replace "\{.*\}$", ""
    # curl.exe streams the file (Invoke-RestMethod buffers it and big uploads drop); a failed
    # upload leaves a broken asset behind, so delete it before trying again.
    foreach ($f in Get-ChildItem build\release) {
        for ($try = 1; ; $try++) {
            Write-Host "  uploading $($f.Name) ($([math]::Round($f.Length / 1MB, 1)) MB), try $try"
            $code = & curl.exe -s -o NUL -w "%{http_code}" -X POST -H "Authorization: Bearer $token" `
                -H "Content-Type: application/octet-stream" -T "$($f.FullName)" "$($upload)?name=$($f.Name)"
            if ($code -eq "201") { break }
            if ($try -ge 4) { throw "Uploading $($f.Name) failed (HTTP $code)." }
            Write-Warning "Upload failed (HTTP $code), retrying..."
            Start-Sleep 10
            foreach ($a in Invoke-RestMethod -Uri "$($release.url)/assets" -Headers $headers) {
                if ($a.name -eq $f.Name) { Invoke-RestMethod -Method Delete -Uri $a.url -Headers $headers | Out-Null }
            }
        }
    }
} catch {
    # Undo, so the next try reuses this version number.
    Write-Json "release.json" @{ version = $oldVersion; repo = $rel.repo }
    if ($release) {
        try {
            Invoke-RestMethod -Method Delete -Uri $release.url -Headers $headers | Out-Null
            Invoke-RestMethod -Method Delete -Uri "https://api.github.com/repos/$($rel.repo)/git/refs/tags/v$version" -Headers $headers | Out-Null
        } catch { Write-Warning "Couldn't remove the half-made release v$version - delete it on GitHub." }
    }
    throw
}

Write-Host ""
Write-Host "Published version $version."
Write-Host "New players download: https://github.com/$($rel.repo)/releases/latest/download/Princess-Zeeba-Windows.zip"
Write-Host "Existing players get it automatically next time they start the game."
