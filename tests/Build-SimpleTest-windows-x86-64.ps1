param (
    [string]$DistFile
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $DistFile -or -not (Test-Path $DistFile)) {
    Write-Error "Usage: .\Build-SimpleTest-windows-x86-64.ps1 <path-to-dist-zip>"
    exit 1
}

$BuildDir = "$PWD\build"

# Clean and extract
Remove-Item -Recurse -Force $BuildDir -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null
Expand-Archive -Path $DistFile -DestinationPath $BuildDir -Force

Write-Host "`nCompiling..."
Write-Host "BUILD_DIR: $BuildDir"

$IncludeDir = "$BuildDir\include"
$LibDir     = "$BuildDir\lib-windows-x86-64"
$OutputExe  = "$PWD\simple-test-x86-64.exe"
$Compiler   = "clang++"

$CompileArgs = @(
    "simple-test.cpp"          ,
    "-std=c++23"               ,
    "-O2"                      ,
    "-D_CRT_SECURE_NO_WARNINGS",
    "-I$IncludeDir"            ,
    "-o", $OutputExe           ,
    "--target=x86_64-windows"  ,
    "-L$LibDir"                ,
    "-lfmt"
)

& $Compiler @CompileArgs
if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Compilation failed"
    exit 1
}

Write-Host "`n✅ Success!"
Write-Host "Test is ready to run (on Windows x86-64): .\simple-test-x86-64.exe"
