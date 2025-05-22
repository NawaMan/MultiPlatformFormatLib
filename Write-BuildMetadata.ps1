function Write-BuildMetadata {
    param (
        [string]$TargetDir,
        [string]$Compiler,
        [string]$CompilerVersion,
        [string]$TargetOS,
        [string]$Arch,
        [string]$OptFlags,
        [string]$LinkFlags
    )

    $buildFlags = @"
# Build Flags
CFLAGS   = $OptFlags
CXXFLAGS = $OptFlags
LDFLAGS  = $LinkFlags
Compiler = $Compiler $CompilerVersion
Target   = $TargetOS $Arch
"@

    Set-Content -Path "$TargetDir\build-flags.txt" -Value $buildFlags

    $readme = @"
# fmt $env:FMT_VERSION ($TargetOS $Arch, $Compiler $CompilerVersion)

This archive contains a statically compiled build of the [fmt](https://github.com/fmtlib/fmt) library.

## Build Info

- Compiler: $Compiler $CompilerVersion
- Target:   $TargetOS $Arch
- CFLAGS:   $OptFlags
- CXXFLAGS: $OptFlags
- LDFLAGS:  $LinkFlags

## Contents

- include/: Header files
- lib/: Static libraries
- version.txt, LICENSE, build-flags.txt: Metadata

---
Generated on $(Get-Date -Format "yyyy-MM-dd HH:mm")
"@

    Set-Content -Path "$TargetDir\README.md" -Value $readme
}


# Not sure this does not work. The error said the files do not exist.

# Write-Output "Build flags:"
# Get-Content -Path "$TargetDir\build-flags.txt"

# Write-Output "README.md:"
# Get-Content -Path "$TargetDir\README.md"
