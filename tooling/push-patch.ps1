# ==============================================================================
# In-House Code Push - Windows PowerShell Patch Pusher
# Builds the Flutter app, extracts libapp.so, verifies the snapshot, and uploads
# the patch to the running Dart Frog dashboard.
# ==============================================================================
param(
    [string]$TargetRelease = "1.0.0",
    [string]$Arch = "x64",
    [string]$AppDir = "",
    [string]$AppId = ""
)

$ErrorActionPreference = "Stop"

$toolingDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoDir = Split-Path -Parent $toolingDir
$configFile = Join-Path $toolingDir "config.env"

if (-not (Test-Path $configFile)) {
    Write-Error "Missing config.env at $configFile"
}

# Parse config.env
$config = @{}
Get-Content $configFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#") -and $line.Contains("=")) {
        $parts = $line.Split("=", 2)
        $key = $parts[0].Trim()
        $val = $parts[1].Trim().Trim('"').Trim("'")
        $config[$key] = $val
    }
}

$flutterBin = if ($config["FLUTTER_BIN"]) { $config["FLUTTER_BIN"] } else { "flutter" }
$appId = if ($AppId) { $AppId } elseif ($config["APP_ID"]) { $config["APP_ID"] } else { "com.example.codepush_demo" }
$engineSnapshot = $config["ENGINE_SNAPSHOT"]
$dashboardUrl = if ($config["DASHBOARD_URL"]) { $config["DASHBOARD_URL"] } else { "http://localhost:8080" }
$adminToken = if ($config["ADMIN_TOKEN"]) { $config["ADMIN_TOKEN"] } else { "dev-admin-token-change-me" }
$appDir = if ($AppDir) { $AppDir } elseif ($config["APP_DIR"]) { $config["APP_DIR"] } else { Join-Path $repoDir "example" }
$localEngineMaven = $config["LOCAL_ENGINE_MAVEN"]
$patchStorageDir = if ($config["PATCH_STORAGE_DIR"]) { $config["PATCH_STORAGE_DIR"] } else { Join-Path $repoDir "server\_patches" }

Write-Host "==> Checking dashboard at $dashboardUrl..."
try {
    $health = Invoke-WebRequest -Uri "$dashboardUrl/" -UseBasicParsing -TimeoutSec 5
    if ($health.StatusCode -ne 200) { throw "Status $($health.StatusCode)" }
} catch {
    Write-Error "Dashboard server is not reachable at $dashboardUrl. Please start it first!"
}

# Build the release APK
Write-Host "==> Building Flutter app in $appDir..."
Push-Location $appDir
try {
    $env:LOCAL_ENGINE_MAVEN = $localEngineMaven
    & $flutterBin pub get
    & $flutterBin build apk --release --target-platform android-arm64,android-x64 --android-skip-build-dependency-validation
    if ($LASTEXITCODE -ne 0) { throw "flutter build apk failed!" }
} finally {
    Pop-Location
}

$apkPath = Join-Path $appDir "build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path $apkPath)) {
    Write-Error "Built APK not found at $apkPath"
}

# Extract libapp.so
$workDir = Join-Path ([System.IO.Path]::GetTempPath()) ("codepush_" + [System.Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Force -Path $workDir | Out-Null

try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($apkPath, $workDir)

    $targetSubDir = if ($Arch -eq "arm64") { "arm64-v8a" } else { "x86_64" }
    $libappPath = Join-Path $workDir "lib\$targetSubDir\libapp.so"

    if (-not (Test-Path $libappPath)) {
        Write-Error "libapp.so not found for architecture $Arch ($libappPath)"
    }

    # Verify snapshot
    $bytes = [System.IO.File]::ReadAllBytes($libappPath)
    $latin = [System.Text.Encoding]::GetEncoding(28591).GetString($bytes)
    if (-not $latin.Contains($engineSnapshot)) {
        Write-Error "ENGINE_SNAPSHOT mismatch! Expected $engineSnapshot but it was not found in $libappPath"
    }
    Write-Host "==> Verified snapshot $engineSnapshot in libapp.so ($Arch)"

    # Get next patch number
    $headers = @{ "Authorization" = "Bearer $adminToken" }
    $patchesResp = Invoke-RestMethod -Uri "$dashboardUrl/admin/patches" -Headers $headers -Method Get
    $maxNum = 0
    if ($patchesResp.patches) {
        foreach ($p in $patchesResp.patches) {
            if ($p.app_id -eq $appId -and $p.release_version -eq $TargetRelease -and $p.arch -eq $Arch) {
                if ($p.number -gt $maxNum) { $maxNum = $p.number }
            }
        }
    }
    $nextNum = $maxNum + 1

    Write-Host "==> Pushing patch #$nextNum for $appId ($TargetRelease, $Arch)..."

    # Push to dashboard using curl.exe for multipart/form-data
    $curlOut = & curl.exe -s -w "`n%{http_code}" -X POST "$dashboardUrl/admin/patches" `
        -H "Authorization: Bearer $adminToken" `
        -F "patch=@$libappPath" `
        -F "app_id=$appId" `
        -F "release_version=$TargetRelease" `
        -F "platform=android" `
        -F "arch=$Arch" `
        -F "channel=stable" `
        -F "number=$nextNum" `
        -F "rollout_percentage=100"

    $lines = $curlOut.Trim().Split("`n")
    $statusCode = $lines[-1].Trim()
    $body = if ($lines.Count -gt 1) { $lines[0..($lines.Count - 2)] -join "`n" } else { "" }

    if ($statusCode -ne "201" -and $statusCode -ne "200") {
        Write-Error "Patch upload failed HTTP $statusCode : $body"
    }

    # Sideload copy in patch storage dir
    if (-not (Test-Path $patchStorageDir)) {
        New-Item -ItemType Directory -Force -Path $patchStorageDir | Out-Null
    }
    Copy-Item $apkPath -Destination (Join-Path $patchStorageDir "${appId}_${TargetRelease}_android_${Arch}_${nextNum}.apk") -Force

    Write-Host "============================================================" -ForegroundColor Green
    Write-Host " SUCCESS: Pushed patch #$nextNum ($Arch) to $dashboardUrl" -ForegroundColor Green
    Write-Host " Devices will download this patch on their next app launch." -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green

} finally {
    Remove-Item -Recurse -Force $workDir -ErrorAction SilentlyContinue
}
