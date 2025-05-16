# SOURCE ME - DO NOT RUN (Use . .\Common-Source.ps1 to source this file)

if (-not $BuildLog) {
    Write-Output "BUILD_LOG is not set!"
    
    if (-not (Test-Path -Path "build")) {
        New-Item -ItemType Directory -Path "build" | Out-Null
    }
    
    if (-not (Test-Path -Path "build\build.log")) {
        New-Item -ItemType File -Path "build\build.log" | Out-Null
    }
    
    $global:BuildLog = "build\build.log"
    Write-Output "Build log: $BuildLog"
}

# == PRINTING FUNCTIONS ==

# Color definitions for PowerShell
$Script:RED = "Red"
$Script:GREEN = "Green"
$Script:YELLOW = "Yellow"
$Script:BLUE = "Blue"
$Script:NC = "White" # Normal color (reset)

function Write-Log {
    param(
        [Parameter(ValueFromPipeline=$true)]
        [string]$Message
    )
    
    Write-Output $Message
    Add-Content -Path $BuildLog -Value $Message
}

function Write-EmptyLine {
    Write-Output ""
    Add-Content -Path $BuildLog -Value ""
}

function Write-Section {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title
    )
    
    Write-Output "`n"
    Write-Host "=== $Title ===" -ForegroundColor $YELLOW
    Write-Output ""
    
    Add-Content -Path $BuildLog -Value ""
    Add-Content -Path $BuildLog -Value "=== $Title ==="
    Add-Content -Path $BuildLog -Value ""
}

function Write-Status {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host $Message -ForegroundColor $BLUE
    Write-Output ""
    
    Add-Content -Path $BuildLog -Value $Message
    Add-Content -Path $BuildLog -Value ""
}

function Exit-WithError {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ErrorMessage
    )
    
    Write-Host "ERROR: $ErrorMessage" -ForegroundColor $RED
    Add-Content -Path $BuildLog -Value "ERROR: $ErrorMessage"
    exit 1
}
