param(
    [switch]$SkipFlutterBuild
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$companyConfigPath = Join-Path $repoRoot 'lib\utils\company_config.dart'
$releaseDir = Join-Path $repoRoot 'build\windows\x64\runner\Release'
$installerDir = Join-Path $repoRoot 'build\installer'
$stagingDir = Join-Path $installerDir 'app'
$issPath = Join-Path $repoRoot 'installer\mpt_ims.iss'
$vcRedistPath = Join-Path $installerDir 'vc_redist.x64.exe'

function Find-Iscc {
    $command = Get-Command 'ISCC.exe' -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $candidates = @(@(
        (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'),
        (Join-Path $env:ProgramFiles 'Inno Setup 6\ISCC.exe')
    ) | Where-Object { $_ -and (Test-Path $_) })

    if ($candidates.Count -gt 0) {
        return $candidates[0]
    }

    throw 'Inno Setup 6 was not found. Install it from https://jrsoftware.org/isinfo.php and rerun this script.'
}

$iscc = Find-Iscc

$companyFlag = Select-String -Path $companyConfigPath `
    -Pattern '^\s*const bool useMagnetPowerTech\s*=\s*(true|false)\s*;' |
    Select-Object -First 1
if (-not $companyFlag) {
    throw "Could not determine company from '$companyConfigPath'. Expected a literal useMagnetPowerTech boolean."
}
$company = if ($companyFlag.Matches[0].Groups[1].Value -eq 'true') {
    'MPT'
} else {
    'AIMANT'
}
$installerBaseName = if ($company -eq 'MPT') {
    'Magnet-IMS-Setup'
} else {
    'Aimant-IMS-Setup'
}

if (-not $SkipFlutterBuild) {
    Push-Location $repoRoot
    try {
        flutter build windows --release
        if ($LASTEXITCODE -ne 0) {
            throw "Flutter Windows release build failed with exit code $LASTEXITCODE."
        }
    }
    finally {
        Pop-Location
    }
}

$appExe = Join-Path $releaseDir 'mpt_ims.exe'
$flutterRuntime = Join-Path $releaseDir 'flutter_windows.dll'
$assetBundle = Join-Path $releaseDir 'data\flutter_assets'
if (-not (Test-Path $appExe) -or
    -not (Test-Path $flutterRuntime) -or
    -not (Test-Path $assetBundle)) {
    throw "Release bundle is incomplete at '$releaseDir'. Expected mpt_ims.exe, flutter_windows.dll, and data\flutter_assets."
}

New-Item -ItemType Directory -Path $installerDir -Force | Out-Null
if (Test-Path $stagingDir) {
    Remove-Item $stagingDir -Recurse -Force
}
New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null
Copy-Item $appExe -Destination $stagingDir
Get-ChildItem $releaseDir -Filter '*.dll' -File |
    Copy-Item -Destination $stagingDir
Copy-Item (Join-Path $releaseDir 'data') -Destination $stagingDir -Recurse

if (-not (Test-Path (Join-Path $stagingDir 'mpt_ims.exe')) -or
    -not (Test-Path (Join-Path $stagingDir 'flutter_windows.dll')) -or
    -not (Test-Path (Join-Path $stagingDir 'data\flutter_assets'))) {
    throw "Staged application bundle is incomplete at '$stagingDir'."
}

if (-not (Test-Path $vcRedistPath)) {
    Write-Host 'Downloading the official Microsoft Visual C++ x64 runtime installer...'
    Invoke-WebRequest `
        -Uri 'https://aka.ms/vs/17/release/vc_redist.x64.exe' `
        -OutFile $vcRedistPath
}

$versionLine = Select-String -Path (Join-Path $repoRoot 'pubspec.yaml') `
    -Pattern '^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$' |
    Select-Object -First 1
if (-not $versionLine) {
    throw 'Could not read version from pubspec.yaml. Expected version: major.minor.patch+build.'
}
$appVersion = '{0}.{1}' -f `
    $versionLine.Matches[0].Groups[1].Value, `
    $versionLine.Matches[0].Groups[2].Value

Push-Location $repoRoot
try {
    & $iscc `
        "/DAppVersion=`"$appVersion`"" `
        "/DCompany=$company" `
        "/DSourceDir=`"$stagingDir`"" `
        "/DOutputDir=`"$installerDir`"" `
        "/DVCRedistPath=`"$vcRedistPath`"" `
        $issPath

    if ($LASTEXITCODE -ne 0) {
        throw "Inno Setup compilation failed with exit code $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}

Write-Host "Installer created: $(Join-Path $installerDir "$installerBaseName-$appVersion.exe")"