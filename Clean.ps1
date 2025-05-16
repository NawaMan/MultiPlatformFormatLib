#!/usr/bin/env pwsh

# Clean script for MultiPlatformFormatLib

# Remove build directories
if (Test-Path -Path "build") {
    Remove-Item -Path "build" -Recurse -Force
}

if (Test-Path -Path "dist") {
    Remove-Item -Path "dist" -Recurse -Force
}

if (Test-Path -Path "tests/build") {
    Remove-Item -Path "tests/build" -Recurse -Force
}

if (Test-Path -Path "tests/simple-test") {
    Remove-Item -Path "tests/simple-test" -Recurse -Force
}

Write-Host "Clean completed successfully" -ForegroundColor Green
