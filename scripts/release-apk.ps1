#
# release-apk.ps1 — Build Flutter APK and publish as a GitHub Release (Windows)
#
# Prerequisites:
#   - flutter CLI on PATH
#   - gh CLI installed and authenticated (gh auth login)
#   - Run from the repo root
#
# Usage:
#   .\scripts\release-apk.ps1
#   .\scripts\release-apk.ps1 -Version "1.2.0"
#   .\scripts\release-apk.ps1 -BuildNumber 5
#   .\scripts\release-apk.ps1 -Notes "Bug fixes and improvements"
#

param(
    [string]$Version = "",
    [string]$BuildNumber = "",
    [string]$Notes = ""
)

$ErrorActionPreference = "Stop"

$MobileDir = "apps/mobile"
$Pubspec = "$MobileDir/pubspec.yaml"

# ── Read current version from pubspec.yaml ──
$PubspecContent = Get-Content $Pubspec -Raw
if ($PubspecContent -match 'version:\s*(\S+)') {
    $Current = $Matches[1]
    $Parts = $Current -split '\+'
    $CurrentVersion = $Parts[0]
    $CurrentBuild = [int]$Parts[1]
} else {
    Write-Error "Could not read version from pubspec.yaml"
    exit 1
}

# Use provided or auto-increment
if (-not $Version) { $Version = $CurrentVersion }
if (-not $BuildNumber) { $BuildNumber = $CurrentBuild + 1 }

$Tag = "v${Version}+${BuildNumber}"

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "  Releasing: $Tag" -ForegroundColor Cyan
Write-Host "  Version:   $Version" -ForegroundColor Cyan
Write-Host "  Build:     $BuildNumber" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan

# ── Step 1: Update pubspec.yaml version ──
Write-Host ""
Write-Host "-> Updating pubspec.yaml..." -ForegroundColor Yellow
$PubspecContent = $PubspecContent -replace 'version:\s*\S+', "version: ${Version}+${BuildNumber}"
Set-Content -Path $Pubspec -Value $PubspecContent -NoNewline
Write-Host "   Done: version: ${Version}+${BuildNumber}"

# ── Step 2: Build release APK ──
Write-Host ""
Write-Host "-> Building release APK..." -ForegroundColor Yellow
Push-Location $MobileDir
flutter build apk --release --build-name="$Version" --build-number="$BuildNumber"
Pop-Location

$ApkPath = "$MobileDir/build/app/outputs/flutter-apk/app-release.apk"
if (-not (Test-Path $ApkPath)) {
    Write-Error "APK not found at $ApkPath"
    exit 1
}

$ApkSize = (Get-Item $ApkPath).Length / 1MB
$ApkSizeStr = "{0:N1} MB" -f $ApkSize
Write-Host "   APK built: $ApkPath ($ApkSizeStr)"

# ── Step 3: Git commit and tag ──
Write-Host ""
Write-Host "-> Committing version bump..." -ForegroundColor Yellow
git add $Pubspec
git commit -m "release: ${Tag}" 2>$null
if ($LASTEXITCODE -ne 0) { Write-Host "   (no changes to commit)" }

Write-Host "-> Creating tag: $Tag"
git tag -a $Tag -m "Release $Tag"

# ── Step 4: Push to remote ──
Write-Host ""
Write-Host "-> Pushing to origin..." -ForegroundColor Yellow
git push origin main --tags

# ── Step 5: Create GitHub Release ──
Write-Host ""
Write-Host "-> Creating GitHub Release..." -ForegroundColor Yellow

if (-not $Notes) { $Notes = "Release $Version (build $BuildNumber)" }

gh release create $Tag $ApkPath --title "v${Version}" --notes $Notes

$ReleaseUrl = gh release view $Tag --json url -q '.url'

Write-Host ""
Write-Host "==================================" -ForegroundColor Green
Write-Host "  Release published!" -ForegroundColor Green
Write-Host "  Tag:  $Tag" -ForegroundColor Green
Write-Host "  URL:  $ReleaseUrl" -ForegroundColor Green
Write-Host "  APK:  $ApkSizeStr" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green
Write-Host ""
Write-Host "The app will pick up this update automatically."
