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

<#
.SYNOPSIS
Adds a default folder cover to leaf directories that lack folder.png/jpg/webp.
#>
function coverfiller {

    $root = (Get-Location).Path
    $source = Join-Path $root "folder-example.webp"

    if (-not (Test-Path -LiteralPath $source)) {
        Write-Error "Missing source file: $source"
        return
    }

    # Get all directories under root
    Get-ChildItem -LiteralPath $root -Directory -Recurse | ForEach-Object {

        $dir = $_.FullName

        # Check if leaf folder (no subdirectories)
        $hasSubdirs = Get-ChildItem -LiteralPath $dir -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($hasSubdirs) {
            return
        }

        # Check if folder.png/jpg/jpeg/webp already exists
        $existingCover = Get-ChildItem -LiteralPath $dir -File -ErrorAction SilentlyContinue |
            Where-Object {
                $_.BaseName -ieq "folder" -and
                $_.Extension -in @(".png", ".jpg", ".jpeg", ".webp")
            } |
            Select-Object -First 1

        if ($existingCover) {
            return
        }

        # Copy cover
        $dest = Join-Path $dir "folder.webp"

        try {
            Copy-Item -LiteralPath $source -Destination $dest -Force
            Write-Host "Added cover: $dest"
        }
        catch {
            Write-Warning "Failed to copy to '$dest': $($_.Exception.Message)"
        }
    }
}

<#
.SYNOPSIS
In leaf directories, converts existing folder.(png|jpg|jpeg|webp) to folder.webp
(resize max 1200x1200, quality 60) using ImageMagick. Deletes original by default.
#>
function coverconv {

    param(
        [int]$MaxSize = 1200,
        [int]$Quality = 60,
        [switch]$KeepOriginal
    )

    $root = (Get-Location).Path

    # Check ImageMagick availability
    $magickCmd = Get-Command magick -ErrorAction SilentlyContinue
    if (-not $magickCmd) {
        Write-Error "ImageMagick not found. Install it and ensure 'magick' is in PATH."
        return
    }

    Get-ChildItem -LiteralPath $root -Directory -Recurse | ForEach-Object {

        $dir = $_.FullName

        # Leaf folder check
        $hasSubdirs = Get-ChildItem -LiteralPath $dir -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($hasSubdirs) {
            return
        }

        # Find existing folder.(png|jpg|jpeg|webp)
        $existingCover = Get-ChildItem -LiteralPath $dir -File -ErrorAction SilentlyContinue |
            Where-Object {
                $_.BaseName -ieq "folder" -and
                $_.Extension.ToLowerInvariant() -in @(".png", ".jpg", ".jpeg", ".webp")
            } |
            Select-Object -First 1

        if (-not $existingCover) {
            return
        }

        $src  = $existingCover.FullName
        $dest = Join-Path $dir "folder.webp"

        try {

            if ($src -ieq $dest) {
                # Source is already folder.webp -> resize in-place safely via temp file
                $temp = Join-Path $dir "folder_temp.webp"

                & magick `
                    "$src" `
                    -auto-orient `
                    -resize "${MaxSize}x${MaxSize}>" `
                    -quality $Quality `
                    -strip `
                    "$temp"

                if ($LASTEXITCODE -ne 0) {
                    throw "ImageMagick exited with code $LASTEXITCODE"
                }

                Move-Item -LiteralPath $temp -Destination $dest -Force
                Write-Host "Resized WebP: $dest"
            }
            else {
                # Convert to webp
                & magick `
                    "$src" `
                    -auto-orient `
                    -resize "${MaxSize}x${MaxSize}>" `
                    -quality $Quality `
                    -strip `
                    "$dest"

                if ($LASTEXITCODE -ne 0) {
                    throw "ImageMagick exited with code $LASTEXITCODE"
                }

                Write-Host "Created WebP: $dest"

                # Delete original by default
                if (-not $KeepOriginal) {
                    Remove-Item -LiteralPath $src -Force
                    Write-Host "Deleted original: $src"
                }
            }
        }
        catch {
            Write-Warning "Failed to process '$src': $($_.Exception.Message)"
        }
    }
}
