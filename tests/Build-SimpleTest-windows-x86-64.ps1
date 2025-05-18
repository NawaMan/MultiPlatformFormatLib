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
$DistDir  = Split-Path $DistFile

# Clean and extract
Remove-Item -Recurse -Force $BuildDir -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null
Expand-Archive -Path $DistFile -DestinationPath $BuildDir -Force

Write-Host "`nCompiling..."
Write-Host "BUILD_DIR: $BuildDir"

$IncludeDir = "$BuildDir\include"
$LibDir     = "$BuildDir\lib"
$OutputExe  = "$PWD\simple-test.exe"
$Compiler = "clang++"

$CompileArgs = @(
    "simple-test.cpp",
    "-std=c++23",
    "-O2",
    "-D_CRT_SECURE_NO_WARNINGS",
    "-I$IncludeDir",
    "-o", $OutputExe,
    "--target=i686-windows",           # 👈 Important: this makes it x86
    "-L$LibDir", "-lfmt"               # Or use "fmt.lib" if you're using MSVC-style .lib
)

& $Compiler @CompileArgs
if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Compilation failed"
    exit 1
}

Write-Host "`n✅ Success!"
Write-Host "Test is ready to run: .\simple-test.exe"
