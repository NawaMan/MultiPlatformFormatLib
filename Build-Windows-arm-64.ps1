# Build-Windows-Clang-ARM64.ps1

param (
    [string]$DistDir = "$PWD\dist"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectDir = $PWD
$BuildDir = "$ProjectDir\build\build-windows-arm64"
$BuildLog = "$BuildDir\build.log"

. .\ps-sources\Common-Source.ps1
. .\ps-sources\Src-Common.ps1

New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null
New-Item -ItemType File      -Force -Path $BuildLog | Out-Null

# Load environment
$envLines = (Get-Content .\versions.env -Raw -Encoding UTF8).Replace("`u{FEFF}", "") -split "`n"
foreach ($line in $envLines) {
    $line = $line.Trim()
    if ($line -match '^\s*#' -or $line -match '^\s*$') { continue }
    $parts = $line -split '=', 2
    if ($parts.Count -eq 2) {
        Set-Item -Path "Env:$($parts[0].Trim())" -Value $parts[1].Trim()
    }
}

Write-Output "CLANG_VERSION: $env:CLANG_VERSION"
Write-Output "FMT_VERSION:   $env:FMT_VERSION"

Write-Section "Check clang version"
$ActualClangVersion = (& clang --version | Select-String -Pattern "clang version\s+(\d+\.\d+\.\d+)" | ForEach-Object {
    if ($_ -match "clang version\s+(\d+\.\d+\.\d+)") { $Matches[1] }
})
Write-Status "Clang version: $ActualClangVersion"

Write-Section "Downloading Source $env:FMT_VERSION"
& .\Prepare-Src.ps1 $BuildDir

Write-Section "Building fmt for Windows ARM64"

$SourceDir = "$BuildDir\fmt-source\fmt-$env:FMT_VERSION"
$TargetDir = "$BuildDir\fmt-target"
$OptFlags = "-O2 -flto -ffunction-sections -fdata-sections -fPIC"
$LinkFlags = "-Wl,--gc-sections"
$TargetTriple = "aarch64-windows"

$env:CC       = "clang --target=$TargetTriple"
$env:CXX      = "clang++ --target=$TargetTriple"
$env:CFLAGS   = $OptFlags
$env:CXXFLAGS = $OptFlags
$env:LDFLAGS  = $LinkFlags

New-Item -ItemType Directory -Force -Path "$SourceDir\build" | Out-Null
Set-Location "$SourceDir\build"

cmake .. `
    -DCMAKE_BUILD_TYPE=Release `
    -DCMAKE_INSTALL_PREFIX="$TargetDir" `
    -DFMT_DOC=OFF `
    -DFMT_TEST=OFF `
    -DFMT_INSTALL=ON `
    -DBUILD_SHARED_LIBS=OFF `
    -DCMAKE_SYSTEM_NAME="Windows" `
    -DCMAKE_SYSTEM_PROCESSOR="ARM64" `
    -DCMAKE_C_COMPILER="clang" `
    -DCMAKE_CXX_COMPILER="clang++" `
    -DCMAKE_C_COMPILER_TARGET=$TargetTriple `
    -DCMAKE_CXX_COMPILER_TARGET=$TargetTriple `
    *> $BuildLog 2>&1

cmake --build . --config Release --parallel *> $BuildLog 2>&1
cmake --install . *> $BuildLog 2>&1

# Rename the static library
New-Item -ItemType Directory -Force -Path "$TargetDir\lib-windows-arm-64" | Out-Null
Move-Item "$TargetDir\lib\libfmt.a" "$TargetDir\lib-windows-arm-64\libfmt.a" -Force

Write-Section "Packaging"

New-Item -ItemType Directory -Force -Path $DistDir | Out-Null
$BuildZip = "$DistDir\fmt-$env:FMT_VERSION`_windows-arm-64_clang-$env:CLANG_VERSION.zip"

Copy-Item "$ProjectDir\version.txt"  "$TargetDir" -Force
Copy-Item "$ProjectDir\versions.env" "$TargetDir" -Force
Copy-Item "$ProjectDir\LICENSE"      "$TargetDir" -Force
Copy-Item "$ProjectDir\README.md"    "$TargetDir" -Force

. $ProjectDir\Write-BuildMetadata.ps1

Write-BuildMetadata `
    -TargetDir $TargetDir `
    -Compiler "Clang" `
    -CompilerVersion $ActualClangVersion `
    -TargetOS "Windows" `
    -Arch "arm64" `
    -OptFlags $OptFlags `
    -LinkFlags $LinkFlags

Set-Location $TargetDir
Write-Output "Current Directory:"
Get-Location
Write-Output "Directory Structure:"
Get-ChildItem -Recurse | Format-Table -Property Mode,Length,Name -AutoSize

Compress-Archive -Path * -DestinationPath $BuildZip -Force
Set-ItemProperty -Path $BuildZip -Name Attributes -Value 'Normal'


if (Test-Path $BuildZip) {
    Write-Status "Build succeeded!"
    Write-Output "File: $BuildZip"
    Write-Output "Size: $((Get-Item $BuildZip).Length / 1MB) MB"
} else {
    throw "Build failed! No output archive found."
}
