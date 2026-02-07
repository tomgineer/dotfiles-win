<#
.SYNOPSIS
Creates a multi-size Windows ICO file from an input image.
#>
function makeico {
    param(
        [string]$InputFile
    )

    if ([string]::IsNullOrWhiteSpace($InputFile)) {
        Write-Host "Syntax: makeico <input-file>"
        return
    }

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

<#
.SYNOPSIS
Removes embedded metadata from an image file in place.
#>
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
