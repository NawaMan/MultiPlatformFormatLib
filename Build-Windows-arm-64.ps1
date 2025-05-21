# Build-Windows-arm-64.ps1 

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
    if ($line -match '^\s*#') { continue }       # skip comment
    if ($line -match '^\s*$') { continue }       # skip empty line

    $parts = $line -split '=', 2
    if ($parts.Count -eq 2) {
        $key = $parts[0].Trim()
        $val = $parts[1].Trim()
        Set-Item -Path "Env:$key" -Value $val
    }
}

Write-Output "CLANG_VERSION: $env:CLANG_VERSION"
Write-Output "FMT_VERSION:   $env:FMT_VERSION"
Write-Output "ENSDK_VERSION: $env:ENSDK_VERSION"

Write-Output "Clang version   : $(clang --version)"
Write-Output "Clang++ version : $(clang++ --version)"
Write-Output "LLVM-ar version : $(llvm-ar --version)"
Write-Output "LLVM-ranlib     : $(llvm-ranlib --version)"
Write-Output "Clang path      : $(Get-Command clang | Select-Object -ExpandProperty Source)"
Write-Output "Clang++ path    : $(Get-Command clang++ | Select-Object -ExpandProperty Source)"

Write-Section "Check compiler version"

# Extract actual clang version (e.g., "20.1.5")
$ActualClangVersionLine = & clang --version | Select-String -Pattern "clang version\s+(\d+\.\d+\.\d+)"
if ($ActualClangVersionLine -match "clang version\s+(\d+\.\d+\.\d+)") {
    $ActualClangVersion = $Matches[1]
    $ActualMajorVersion = $ActualClangVersion.Split(".")[0]
} else {
    throw "Unable to determine clang version"
}

Write-Output "Actual clang version: $ActualClangVersion"
Write-Output "Actual clang major version: $ActualMajorVersion"

# Get version expectations from env (with defaults for robustness)
$BuildClang     = if ($env:BUILD_CLANG) { $env:BUILD_CLANG } else { "true" }
$IgnoreVersion  = if ($env:IGNORE_COMPILER_VERSION) { $env:IGNORE_COMPILER_VERSION } else { "0" }
$ExpectedMajorVersion = $env:CLANG_VERSION

# Perform the version check
if ($BuildClang -eq "true" -and $IgnoreVersion -eq "0") {
    if ($ActualMajorVersion -ne $ExpectedMajorVersion) {
        throw "Clang version $ExpectedMajorVersion.x required, found $ActualClangVersion"
    }
}

$BuildClang = if ($env:BUILD_CLANG) { $env:BUILD_CLANG } else { "true" }
$IgnoreVersion = if ($env:IGNORE_COMPILER_VERSION) { $env:IGNORE_COMPILER_VERSION } else { "0" }

if ($BuildClang -eq "true" -and $IgnoreVersion -eq "0") {
    if ($ActualClangVersion.Split(".")[0] -ne $env:CLANG_VERSION) {
        throw "Clang version $env:CLANG_VERSION.x required, found $ActualClangVersion"
    }
}

Write-Status "Clang version: $ActualClangVersion"

Write-Section "Downloading Source $env:FMT_VERSION"
& .\Prepare-Src.ps1 $BuildDir

Write-Section "Building fmt for Windows ARM-64"

$SourceDir    = "$BuildDir\fmt-source\fmt-$env:FMT_VERSION"
$TargetDir    = "$BuildDir\fmt-target"
$OptFlags     = "-O2 -flto -ffunction-sections -fdata-sections"
$LinkFlags    = "-Wl,--gc-sections"
$TargetTriple = "aarch64-pc-windows-msvc"

$env:CC       = "clang --target=$TargetTriple"
$env:CXX      = "clang++ --target=$TargetTriple"
$env:CFLAGS   = $OptFlags
$env:CXXFLAGS = $OptFlags
$env:LDFLAGS  = $LinkFlags

New-Item -ItemType Directory -Force -Path "$SourceDir\build" | Out-Null
Set-Location "$SourceDir\build"

cmake ..                                                 `
    -G "Ninja"                                           `
    -DCMAKE_BUILD_TYPE=Release                           `
    -DCMAKE_INSTALL_PREFIX="$TargetDir"                  `
    -DFMT_DOC=OFF                                        `
    -DFMT_TEST=OFF                                       `
    -DFMT_INSTALL=ON                                     `
    -DBUILD_SHARED_LIBS=OFF                              `
    -DCMAKE_MSVC_RUNTIME_LIBRARY="MultiThreaded"         `
    -DCMAKE_SYSTEM_NAME="Windows"                        `
    -DCMAKE_SYSTEM_PROCESSOR="ARM64"                     `
    -DCMAKE_C_COMPILER="clang"                           `
    -DCMAKE_CXX_COMPILER="clang++"                       `
    -DCMAKE_C_FLAGS="--target=$TargetTriple $OptFlags"   `
    -DCMAKE_CXX_FLAGS="--target=$TargetTriple $OptFlags" `
    -DCMAKE_EXE_LINKER_FLAGS="$LinkFlags"
    # *> $BuildLog 2>&1

cmake --build . --config Release --parallel # *> $BuildLog 2>&1
cmake --install . # *> $BuildLog 2>&1


# Rename the static library
Write-Output "TargetDir: $TargetDir"
Get-ChildItem "$TargetDir"
Get-ChildItem "$TargetDir\lib"

# Rename the static library
New-Item -ItemType Directory -Force -Path "$TargetDir\lib-windows-arm-64" | Out-Null
Move-Item "$TargetDir\lib\fmt.lib" "$TargetDir\lib-windows-arm-64\fmt.lib" -Force

& llvm-readobj --file-headers "$TargetDir\lib-windows-arm-64\fmt.lib"

# Remove the lib directory as it's no longer needed
Remove-Item -Path "$TargetDir\lib" -Recurse -Force

# Rename the static library
Write-Output "TargetDir: $TargetDir"
Get-ChildItem "$TargetDir"
Get-ChildItem "$TargetDir\lib-windows-arm-64"

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
cmd.exe /c tree /F /A

Compress-Archive -Path * -DestinationPath $BuildZip -Force
Set-ItemProperty -Path $BuildZip -Name Attributes -Value 'Normal'  # Ensure readable by others


if (Test-Path $BuildZip) {
    Write-Status "Build succeeded!"
    Write-Output "File: $BuildZip"
    Write-Output "Size: $((Get-Item $BuildZip).Length / 1MB) MB"
} else {
    throw "Build failed! No output archive found."
}
