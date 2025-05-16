# SOURCE ME - DO NOT RUN (Use . .\Src-Common.ps1 to source this file)

function Get-SourceCode {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SrcVersion,
        
        [Parameter(Mandatory=$true)]
        [string]$SrcFile
    )
    
    if ([string]::IsNullOrEmpty($SrcVersion)) {
        Exit-WithError "SRC_VERSION is not set!"
    }
    
    Write-Log "Ensure source"
    if (-not (Test-Path -Path $SrcFile)) {
        $SrcUrl = "https://github.com/fmtlib/fmt/archive/refs/tags/$SrcVersion.zip"
        Write-Log "📥 Downloading SRC..."
        Invoke-WebRequest -Uri $SrcUrl -OutFile $SrcFile
        Write-Log ""
    }
}

function Expand-SourceArchive {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SrcFile,
        
        [Parameter(Mandatory=$true)]
        [string]$SrcDir
    )
    
    Write-Log "📦 Extracting source to $SrcDir ..."
    
    # Remove directory if it exists and create a new one
    if (Test-Path -Path $SrcDir) {
        Remove-Item -Path $SrcDir -Recurse -Force
    }
    
    New-Item -ItemType Directory -Path $SrcDir -Force | Out-Null
    
    # Save current location
    $currentLocation = Get-Location
    
    # Change to the source directory
    Set-Location -Path $SrcDir
    
    # Extract the zip file
    Expand-Archive -Path $SrcFile -DestinationPath .
    
    # Return to the original location
    Set-Location -Path $currentLocation
    
    Write-Log "END: Expand-SourceArchive"
}
