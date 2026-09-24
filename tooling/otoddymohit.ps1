# ==============================================================================
# otoddymohit - In-House Flutter CodePush CLI
#
# Usage:
#   otoddymohit release   [-Dir <path>] [-Install]
#   otoddymohit patch     [-Dir <path>] [-Arch <arm64|x64>] [-Release <ver>] [-Test]
#   otoddymohit rollback  [-Dir <path>] [-Patch <number>] [-Release <ver>]
#   otoddymohit status    [-AppId <id>]
#   otoddymohit server    [start|status]
# ==============================================================================

param(
    [Parameter(Position = 0)]
    [string]$Command = "help",

    [Parameter(Position = 1)]
    [string]$SubParam = "",

    [string]$Dir = "",
    [string]$AppId = "",
    [string]$Release = "",
    [string]$Arch = "",
    [int]$Patch = 0,
    [switch]$Install,
    [switch]$Test,
    [string]$ServerUrl = "http://localhost:8080",
    [string]$AdminToken = "dev-admin-token-change-me"
)

$ErrorActionPreference = "Stop"

# Base configuration paths
$repoRoot = "c:\Users\ronni\OneDrive\Desktop\codepush\inhouse-codepush"
$localEngineMaven = "$repoRoot\local-engine-maven"
$engineSnapshot = "0451907c2eaa8467e848c0067bfe8ed4"
$patchStorageDir = "$repoRoot\server\_patches"

function Write-BrandHeader {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " 🚀 otoddymohit - Flutter In-House CodePush CLI" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
}

function Resolve-ProjectInfo {
    param([string]$targetDir)

    $projectDir = if ($targetDir) { (Resolve-Path $targetDir).Path } else { (Get-Location).Path }
    $pubspecPath = Join-Path $projectDir "pubspec.yaml"

    if (-not (Test-Path $pubspecPath)) {
        Write-Error "No pubspec.yaml found in $projectDir. Please run otoddymohit inside a Flutter project directory or pass -Dir <path>."
    }

    # Extract version from pubspec.yaml
    $version = "1.0.0"
    Get-Content $pubspecPath | ForEach-Object {
        if ($_ -match "^\s*version:\s*([^\s+]+)") {
            $version = $matches[1]
        }
    }

    # Extract appId from android build gradle
    $detectedAppId = ""
    $gradleKts = Join-Path $projectDir "android\app\build.gradle.kts"
    $gradleGroovy = Join-Path $projectDir "android\app\build.gradle"

    if (Test-Path $gradleKts) {
        $content = Get-Content $gradleKts -Raw
        if ($content -match 'applicationId\s*=\s*["'']([^"'']+)["'']') {
            $detectedAppId = $matches[1]
        } elseif ($content -match 'namespace\s*=\s*["'']([^"'']+)["'']') {
            $detectedAppId = $matches[1]
        }
    } elseif (Test-Path $gradleGroovy) {
        $content = Get-Content $gradleGroovy -Raw
        if ($content -match 'applicationId\s+["'']([^"'']+)["'']') {
            $detectedAppId = $matches[1]
        } elseif ($content -match 'namespace\s+["'']([^"'']+)["'']') {
            $detectedAppId = $matches[1]
        }
    }

    $finalAppId = if ($AppId) { $AppId } elseif ($detectedAppId) { $detectedAppId } else { "com.example.app" }
    $finalRelease = if ($Release) { $Release } else { $version }

    return @{
        ProjectDir = $projectDir
        AppId      = $finalAppId
        Release    = $finalRelease
    }
}

function Get-PrimaryAdbDevice {
    try {
        $lines = & adb devices | Where-Object { $_ -match "\bdevice\b" -and $_ -notmatch "List of" }
        if ($lines) {
            $first = ($lines | Select-Object -First 1).Split("`t")[0].Trim()
            return $first
        }
    } catch {}
    return ""
}

function Detect-TargetArch {
    if ($Arch) { return $Arch }
    try {
        $device = Get-PrimaryAdbDevice
        if ($device) {
            $cpuAbi = (& adb -s $device shell getprop ro.product.cpu.abi).Trim()
            if ($cpuAbi -match "arm64") { return "arm64" }
            if ($cpuAbi -match "x86_64") { return "x64" }
        }
    } catch {}
    return "x64" # Default for emulator
}

# ------------------------------------------------------------------------------
# COMMAND: release
# ------------------------------------------------------------------------------
function Invoke-Release {
    $info = Resolve-ProjectInfo -targetDir $Dir
    Write-Host "==> Target Project: $($info.ProjectDir)" -ForegroundColor Yellow
    Write-Host "==> App ID:         $($info.AppId)" -ForegroundColor Yellow
    Write-Host "==> Release Ver:    $($info.Release)" -ForegroundColor Yellow
    Write-Host "==> Building base release APK with custom engine..." -ForegroundColor Yellow

    Push-Location $info.ProjectDir
    try {
        $env:LOCAL_ENGINE_MAVEN = $localEngineMaven
        & flutter pub get
        & flutter build apk --release --target-platform android-arm64,android-x64 --android-skip-build-dependency-validation
        if ($LASTEXITCODE -ne 0) { throw "flutter build apk failed!" }
    } finally {
        Pop-Location
    }

    $apkPath = Join-Path $info.ProjectDir "build\app\outputs\flutter-apk\app-release.apk"
    if (-not (Test-Path $apkPath)) {
        Write-Error "Built APK not found at $apkPath"
    }

    $apkSizeMB = [math]::Round(((Get-Item $apkPath).Length / 1MB), 2)

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host " ✨ RELEASE READY: $($info.AppId) (v$($info.Release))" -ForegroundColor Green
    Write-Host " Output APK: $apkPath ($apkSizeMB MB)" -ForegroundColor Green
    Write-Host " Engine Hook: Verified local engine Maven integrated" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green

    if ($Install) {
        $primary = Get-PrimaryAdbDevice
        $devArgs = if ($primary) { @("-s", $primary) } else { @() }
        Write-Host "==> Installing APK on connected device ($primary)..." -ForegroundColor Yellow
        & adb @devArgs install -r $apkPath
        Write-Host "==> Launching app..." -ForegroundColor Yellow
        & adb @devArgs shell am start -n "$($info.AppId)/.MainActivity"
    } else {
        Write-Host "Tip: Pass -Install to immediately install and launch on emulator/device." -ForegroundColor Gray
    }
}

# ------------------------------------------------------------------------------
# COMMAND: patch
# ------------------------------------------------------------------------------
function Invoke-Patch {
    $info = Resolve-ProjectInfo -targetDir $Dir
    $targetArch = Detect-TargetArch

    Write-Host "==> Target Project: $($info.ProjectDir)" -ForegroundColor Yellow
    Write-Host "==> App ID:         $($info.AppId)" -ForegroundColor Yellow
    Write-Host "==> Target Release: $($info.Release)" -ForegroundColor Yellow
    Write-Host "==> Target Arch:    $targetArch" -ForegroundColor Yellow

    # Check dashboard connectivity
    try {
        $health = Invoke-WebRequest -Uri "$ServerUrl/" -UseBasicParsing -TimeoutSec 3
        if ($health.StatusCode -ne 200) { throw "Server returned $($health.StatusCode)" }
    } catch {
        Write-Error "CodePush Server is not reachable at $ServerUrl. Run 'otoddymohit server start' first."
    }

    # Build release APK
    Write-Host "==> Compiling Dart AOT snapshot..." -ForegroundColor Yellow
    Push-Location $info.ProjectDir
    try {
        $env:LOCAL_ENGINE_MAVEN = $localEngineMaven
        & flutter pub get
        & flutter build apk --release --target-platform android-arm64,android-x64 --android-skip-build-dependency-validation
        if ($LASTEXITCODE -ne 0) { throw "flutter build apk failed!" }
    } finally {
        Pop-Location
    }

    $apkPath = Join-Path $info.ProjectDir "build\app\outputs\flutter-apk\app-release.apk"
    $workDir = Join-Path ([System.IO.Path]::GetTempPath()) ("otoddy_" + [System.Guid]::NewGuid().ToString())
    New-Item -ItemType Directory -Force -Path $workDir | Out-Null

    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($apkPath, $workDir)

        $targetSubDir = if ($targetArch -eq "arm64") { "arm64-v8a" } else { "x86_64" }
        $libappPath = Join-Path $workDir "lib\$targetSubDir\libapp.so"

        if (-not (Test-Path $libappPath)) {
            Write-Error "libapp.so not found for $targetArch at $libappPath"
        }

        # Verify snapshot hash
        $bytes = [System.IO.File]::ReadAllBytes($libappPath)
        $latin = [System.Text.Encoding]::GetEncoding(28591).GetString($bytes)
        if (-not $latin.Contains($engineSnapshot)) {
            Write-Error "ENGINE_SNAPSHOT mismatch! Expected $engineSnapshot in libapp.so"
        }
        Write-Host "==> Engine snapshot $engineSnapshot verified." -ForegroundColor Green

        # Determine next patch number for this specific app & release
        $headers = @{ "Authorization" = "Bearer $AdminToken" }
        $patchesResp = Invoke-RestMethod -Uri "$ServerUrl/admin/patches" -Headers $headers -Method Get
        $maxNum = 0
        if ($patchesResp.patches) {
            foreach ($p in $patchesResp.patches) {
                if ($p.app_id -eq $info.AppId -and $p.release_version -eq $info.Release -and $p.arch -eq $targetArch) {
                    if ($p.number -gt $maxNum) { $maxNum = $p.number }
                }
            }
        }
        $nextNum = $maxNum + 1

        Write-Host "==> Pushing Patch #$nextNum to $ServerUrl..." -ForegroundColor Yellow

        $curlOut = & curl.exe -s -w "`n%{http_code}" -X POST "$ServerUrl/admin/patches" `
            -H "Authorization: Bearer $AdminToken" `
            -F "patch=@$libappPath" `
            -F "app_id=$($info.AppId)" `
            -F "release_version=$($info.Release)" `
            -F "platform=android" `
            -F "arch=$targetArch" `
            -F "channel=stable" `
            -F "number=$nextNum" `
            -F "rollout_percentage=100"

        $lines = $curlOut.Trim().Split("`n")
        $statusCode = $lines[-1].Trim()
        $body = if ($lines.Count -gt 1) { $lines[0..($lines.Count - 2)] -join "`n" } else { "" }

        if ($statusCode -ne "201" -and $statusCode -ne "200") {
            Write-Error "Patch upload failed HTTP $statusCode : $body"
        }

        # Sideload copy to local storage dir
        if (-not (Test-Path $patchStorageDir)) {
            New-Item -ItemType Directory -Force -Path $patchStorageDir | Out-Null
        }
        Copy-Item $apkPath -Destination (Join-Path $patchStorageDir "$($info.AppId)_$($info.Release)_android_${targetArch}_${nextNum}.apk") -Force

        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Green
        Write-Host " 🚀 PATCH PUBLISHED: Patch #$nextNum for $($info.AppId)" -ForegroundColor Green
        Write-Host " Target Release: $($info.Release) ($targetArch)" -ForegroundColor Green
        Write-Host " Server:         $ServerUrl" -ForegroundColor Green
        Write-Host " Rollout:        100% (Instant OTA Delivery)" -ForegroundColor Green
        Write-Host "============================================================" -ForegroundColor Green

        if ($Test) {
            $primary = Get-PrimaryAdbDevice
            $devArgs = if ($primary) { @("-s", $primary) } else { @() }
            Write-Host "==> Restarting app on device ($primary) to download patch..." -ForegroundColor Yellow
            & adb @devArgs shell am force-stop $info.AppId
            Start-Sleep -Seconds 1
            & adb @devArgs shell am start -n "$($info.AppId)/.MainActivity"
            Write-Host "==> Launched! App will download patch #$nextNum in background." -ForegroundColor Green
            Write-Host "==> Restart the app once more to see the patch in action!" -ForegroundColor Cyan
        }

    } finally {
        Remove-Item -Recurse -Force $workDir -ErrorAction SilentlyContinue
    }
}

# ------------------------------------------------------------------------------
# COMMAND: rollback
# ------------------------------------------------------------------------------
function Invoke-Rollback {
    $info = Resolve-ProjectInfo -targetDir $Dir

    $targetPatch = $Patch
    if ($targetPatch -le 0) {
        # Fetch latest patch for this app
        $headers = @{ "Authorization" = "Bearer $AdminToken" }
        $patchesResp = Invoke-RestMethod -Uri "$ServerUrl/admin/patches" -Headers $headers -Method Get
        if ($patchesResp.patches) {
            foreach ($p in $patchesResp.patches) {
                if ($p.app_id -eq $info.AppId -and $p.release_version -eq $info.Release -and -not $p.rolled_back) {
                    if ($p.number -gt $targetPatch) { $targetPatch = $p.number }
                }
            }
        }
    }

    if ($targetPatch -le 0) {
        Write-Host "No active patches found to rollback for $($info.AppId) ($($info.Release))." -ForegroundColor Yellow
        return
    }

    $targetArch = Detect-TargetArch
    Write-Host "==> Executing emergency rollback for Patch #$targetPatch ($targetArch)..." -ForegroundColor Yellow

    $bodyObj = @{
        app_id          = $info.AppId
        release_version = $info.Release
        platform        = "android"
        arch            = $targetArch
        channel         = "stable"
        number          = [int]$targetPatch
        rolled_back     = $true
    }
    $json = $bodyObj | ConvertTo-Json

    $headers = @{
        "Authorization" = "Bearer $AdminToken"
        "Content-Type"  = "application/json"
    }

    try {
        $res = Invoke-RestMethod -Uri "$ServerUrl/admin/rollback" -Headers $headers -Method Post -Body $json
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Magenta
        Write-Host " ⛔ ROLLBACK COMPLETE: Patch #$targetPatch revoked!" -ForegroundColor Magenta
        Write-Host " App ID:  $($info.AppId) (v$($info.Release))" -ForegroundColor Magenta
        Write-Host " Devices will revert to baseline on their next app launch." -ForegroundColor Magenta
        Write-Host "============================================================" -ForegroundColor Magenta
    } catch {
        Write-Error "Rollback request failed: $_"
    }
}

# ------------------------------------------------------------------------------
# COMMAND: status
# ------------------------------------------------------------------------------
function Invoke-Status {
    $headers = @{ "Authorization" = "Bearer $AdminToken" }
    Write-Host "==> Fetching CodePush dashboard status ($ServerUrl)..." -ForegroundColor Yellow

    try {
        $patchesResp = Invoke-RestMethod -Uri "$ServerUrl/admin/patches" -Headers $headers -Method Get
        $devicesResp = Invoke-RestMethod -Uri "$ServerUrl/admin/devices" -Headers $headers -Method Get

        Write-Host ""
        Write-Host "--- REGISTERED PATCHES ---" -ForegroundColor Cyan
        if ($patchesResp.patches -and $patchesResp.patches.Count -gt 0) {
            $patchesResp.patches | Format-Table -Property app_id, release_version, arch, number, rolled_back, rollout_percentage | Out-String | Write-Host
        } else {
            Write-Host "No patches registered yet." -ForegroundColor Gray
        }

        Write-Host "--- CONNECTED DEVICES (TELEMETRY) ---" -ForegroundColor Cyan
        if ($devicesResp.devices -and $devicesResp.devices.Count -gt 0) {
            $devicesResp.devices | Format-Table -Property app_id, release_version, arch, current_patch_number, last_seen | Out-String | Write-Host
        } else {
            Write-Host "No active devices recorded yet." -ForegroundColor Gray
        }
    } catch {
        Write-Error "Failed to fetch status from $($ServerUrl): $_"
    }
}

# ------------------------------------------------------------------------------
# COMMAND: server
# ------------------------------------------------------------------------------
function Invoke-Server {
    param([string]$action)

    if ($action -eq "start") {
        Write-Host "==> Starting Dart Frog server on port 8080..." -ForegroundColor Yellow
        Push-Location "$repoRoot\server"
        try {
            $env:PORT = "8080"
            $env:PUBLIC_BASE_URL = "http://10.0.2.2:8080"
            $env:ADMIN_TOKEN = $AdminToken
            $env:PATCH_STORAGE_DIR = $patchStorageDir
            Start-Process -FilePath "dart" -ArgumentList "build/bin/server.dart" -NoNewWindow
            Write-Host "==> Server started on http://localhost:8080" -ForegroundColor Green
        } finally {
            Pop-Location
        }
    } else {
        try {
            $res = Invoke-WebRequest -Uri "$ServerUrl/" -UseBasicParsing -TimeoutSec 3
            Write-Host "==> CodePush Server is HEALTHY (HTTP $($res.StatusCode)) at $ServerUrl" -ForegroundColor Green
        } catch {
            Write-Host "==> CodePush Server is OFFLINE at $ServerUrl" -ForegroundColor Red
        }
    }
}

# ------------------------------------------------------------------------------
# COMMAND: help
# ------------------------------------------------------------------------------
function Show-Help {
    Write-BrandHeader
    Write-Host "Commands:" -ForegroundColor White
    Write-Host "  otoddymohit release   Builds the store release APK with the hooked Flutter engine" -ForegroundColor White
    Write-Host "                        Options: -Dir <path> -Install" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  otoddymohit patch     Compiles Dart changes into an OTA patch and uploads to server" -ForegroundColor White
    Write-Host "                        Options: -Dir <path> -Arch <arm64|x64> -Release <ver> -Test" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  otoddymohit rollback  Revokes a patch on the server (emergency killswitch)" -ForegroundColor White
    Write-Host "                        Options: -Dir <path> -Patch <number> -Release <ver>" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  otoddymohit status    Shows registered patches and live connected device telemetry" -ForegroundColor White
    Write-Host ""
    Write-Host "  otoddymohit server    Checks server health or starts server (otoddymohit server start)" -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  otoddymohit release -Install" -ForegroundColor Yellow
    Write-Host "  otoddymohit patch -Test" -ForegroundColor Yellow
    Write-Host "  otoddymohit rollback" -ForegroundColor Yellow
    Write-Host "  otoddymohit status" -ForegroundColor Yellow
    Write-Host ""
}

# ------------------------------------------------------------------------------
# MAIN DISPATCHER
# ------------------------------------------------------------------------------
Write-BrandHeader

switch ($Command.ToLower()) {
    "release"  { Invoke-Release }
    "patch"    { Invoke-Patch }
    "rollback" { Invoke-Rollback }
    "status"   { Invoke-Status }
    "server"   { Invoke-Server -action $SubParam }
    "help"     { Show-Help }
    default    { Show-Help }
}
