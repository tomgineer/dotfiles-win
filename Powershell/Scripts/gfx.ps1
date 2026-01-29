# gfx.ps1
#
# Creates a Windows .ico file from an input image using ImageMagick.
# The generated icon includes multiple embedded resolutions (16 to 256 px).
# After creation, the icon is inspected to verify its contents.
# All embedded sizes are listed, and a warning is shown if the icon
# does not contain multiple resolutions.
#
# Requirements:
# - ImageMagick (magick.exe) must be available in PATH.

function makeico {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputFile
    )

    if (-not (Test-Path -LiteralPath $InputFile)) {
        throw "File not found: $InputFile"
    }

    $outputFile = [System.IO.Path]::ChangeExtension($InputFile, '.ico')

    # Create icon
    & magick $InputFile -define icon:auto-resize=256,128,96,64,48,32,24,16 $outputFile

    Write-Host "Created: $outputFile"

    # Check
    $sizes = & magick identify -format "%w x %h`n" $outputFile

    if (-not $sizes) {
        Write-Warning "Could not read icon contents"
        return
    }

    $count = ($sizes | Measure-Object).Count

    Write-Host "Embedded resolutions:"
    $sizes | ForEach-Object { Write-Host "  $_" }

    if ($count -lt 2) {
        Write-Warning "Icon is NOT multi-resolution"
    } else {
        Write-Host "Multi-resolution icon detected ($count sizes)"
    }
}

# Removes all metadata (EXIF, IPTC, XMP, etc.) from an image file.
# The original file is overwritten.
# Requires exiftool to be installed and available in PATH.
function remove-meta {
    param (
        [Parameter(Mandatory = $true)]
        [string]$File
    )

    if (-not (Test-Path $File)) {
        Write-Error "File not found: $File"
        return
    }

    exiftool -all= -overwrite_original $File | Out-Null
}