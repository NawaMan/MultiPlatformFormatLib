# Prepare-Src.ps1

param(
    [string]$BuildDir = (Join-Path (Get-Location) "build")
)

$BuildLog = Join-Path $BuildDir "build.log"

# Create build directory if it doesn't exist
if (-not (Test-Path $BuildDir)) {
    New-Item -ItemType Directory -Path $BuildDir -Force | Out-Null
}

# Create empty log file if it doesn't exist
if (-not (Test-Path $BuildLog)) {
    New-Item -ItemType File -Path $BuildLog -Force | Out-Null
}

# Source common files
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptPath\ps-sources\Common-Source.ps1"
. "$ScriptPath\ps-sources\Src-Common.ps1"

# Load versions from environment file
$envFile = Join-Path $ScriptPath "versions.env"
$envContent = Get-Content $envFile

# Parse environment variables
$FmtVersion = ($envContent | Where-Object { $_ -match "^FMT_VERSION=(.*)" } | ForEach-Object { $Matches[1] })

$FmtZip = Join-Path $BuildDir "fmt-source.zip"
Get-SourceCode -SrcVersion $FmtVersion -SrcFile $FmtZip
Expand-SourceArchive -SrcFile $FmtZip -SrcDir (Join-Path $BuildDir "fmt-source")

# Clean up zip file
Remove-Item -Path $FmtZip -Force
