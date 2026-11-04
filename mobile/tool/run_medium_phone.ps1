[CmdletBinding()]
param(
    [string]$EmulatorId = 'medium_phone',
    [string]$ApiBaseUrl,
    [ValidateRange(30, 600)][int]$BootTimeoutSeconds = 180
)

$ErrorActionPreference = 'Stop'
$mobileDir = Split-Path -Parent $PSScriptRoot
$propertiesPath = Join-Path $mobileDir 'android\local.properties'

function Get-LocalProperty([string]$Name) {
    if (Test-Path -LiteralPath $propertiesPath) {
        $line = Get-Content -LiteralPath $propertiesPath |
            Where-Object { $_.StartsWith("$Name=") } | Select-Object -First 1
        if ($line) { return $line.Substring($Name.Length + 1).Replace('\\', '\').Replace('\:', ':') }
    }
}

$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
if ($flutterCommand) {
    $flutterPath = $flutterCommand.Source
} else {
    $flutterSdk = Get-LocalProperty 'flutter.sdk'
    if (!$flutterSdk) { throw 'Flutter not found. Configure flutter.sdk in android/local.properties or add Flutter to PATH.' }
    $flutterPath = Join-Path $flutterSdk 'bin\flutter.bat'
}

$sdkPath = Get-LocalProperty 'sdk.dir'
if (!$sdkPath) { $sdkPath = $env:ANDROID_HOME }
if (!$sdkPath) { $sdkPath = $env:ANDROID_SDK_ROOT }
if (!$sdkPath) { throw 'Android SDK not found. Configure sdk.dir in android/local.properties.' }
$adbPath = Join-Path $sdkPath 'platform-tools\adb.exe'
if (!(Test-Path -LiteralPath $adbPath)) { throw "adb not found: $adbPath" }

if ($ApiBaseUrl) {
    $apiUri = $null
    if (![Uri]::TryCreate($ApiBaseUrl, [UriKind]::Absolute, [ref]$apiUri) -or
        $apiUri.Scheme -notin @('http', 'https')) {
        throw 'ApiBaseUrl must be an absolute http:// or https:// URL.'
    }
}

function Find-Emulator {
    $deviceList = & $adbPath devices
    foreach ($line in $deviceList) {
        if ($line -match '^(emulator-\d+)\s+device\b') {
            $serial = $Matches[1]
            $avdName = & $adbPath -s $serial emu avd name 2>$null
            if (@($avdName | ForEach-Object { $_.Trim() }) -contains $EmulatorId) {
                return $serial
            }
        }
    }
}

Push-Location $mobileDir
try {
    & $adbPath start-server
    if ($LASTEXITCODE -ne 0) { throw 'Could not start adb.' }
    $deviceId = Find-Emulator
    if (!$deviceId) {
        Write-Host "Starting Android emulator: $EmulatorId"
        & $flutterPath emulators --launch $EmulatorId
        if ($LASTEXITCODE -ne 0) {
            throw "Could not start $EmulatorId. Check its system image in Android Studio Device Manager."
        }
    }

    $deadline = (Get-Date).AddSeconds($BootTimeoutSeconds)
    do {
        $deviceId = Find-Emulator
        if ($deviceId) {
            $bootCompleted = & $adbPath -s $deviceId shell getprop sys.boot_completed 2>$null
            if (($bootCompleted -join '').Trim() -eq '1') { break }
        }
        Start-Sleep -Seconds 2
    } while ((Get-Date) -lt $deadline)
    if (!$deviceId -or ($bootCompleted -join '').Trim() -ne '1') {
        throw "Timed out waiting for $EmulatorId to boot."
    }

    $runArguments = @('run', '-d', $deviceId)
    if ($ApiBaseUrl) {
        $runArguments += "--dart-define=API_BASE_URL=$ApiBaseUrl"
    }
    Write-Host "Running on $EmulatorId ($deviceId)."
    if (!$ApiBaseUrl) { Write-Host 'Using the shared default API: http://10.0.2.2:8080' }
    & $flutterPath @runArguments
    if ($LASTEXITCODE -ne 0) { throw 'Flutter run failed. Review the build output above.' }
} finally {
    Pop-Location
}
