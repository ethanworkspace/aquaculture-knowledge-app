param(
    [string]$FlutterSdk,
    [string]$AndroidSdk,
    [string]$JavaHome,
    [ValidateSet('debug', 'release')]
    [string]$Mode = 'release'
)
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if ($FlutterSdk) { $flutterCommand = Join-Path $FlutterSdk 'bin/flutter.bat' }
else { $flutterCommand = (Get-Command flutter -ErrorAction Stop).Source }
if ($AndroidSdk) { $env:ANDROID_HOME = $AndroidSdk }
if ($JavaHome) { $env:JAVA_HOME = $JavaHome }
Push-Location -LiteralPath $projectRoot
try {
    & $flutterCommand pub get
    if ($LASTEXITCODE -ne 0) { throw 'Flutter package resolution failed.' }
    & $flutterCommand analyze
    if ($LASTEXITCODE -ne 0) { throw 'Flutter analysis failed.' }
    & $flutterCommand test
    if ($LASTEXITCODE -ne 0) { throw 'Flutter tests failed.' }
    & $flutterCommand build apk "--$Mode"
    if ($LASTEXITCODE -ne 0) { throw 'APK build failed.' }
    Get-Item -LiteralPath (Join-Path $projectRoot ("build/app/outputs/flutter-apk/app-$Mode.apk"))
}
finally { Pop-Location }
