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

    if (-not (Test-Path -LiteralPath $File)) {
        Write-Error "File not found: $File"
        return
    }

    $directory = [System.IO.Path]::GetDirectoryName((Resolve-Path -LiteralPath $File).Path)
    $extension = [System.IO.Path]::GetExtension($File)
    $tempFile = [System.IO.Path]::Combine($directory, ([System.IO.Path]::GetRandomFileName() + $extension))

    try {
        magick $File -colorspace sRGB -strip $tempFile
        Move-Item -LiteralPath $tempFile -Destination $File -Force
    } finally {
        if (Test-Path -LiteralPath $tempFile) {
            Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
        }
    }

    # verify: should output nothing if ICC is gone
    exiftool -G1 -a -s $File

}
