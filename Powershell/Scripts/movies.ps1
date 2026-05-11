<#
.SYNOPSIS
Scans all subfolders recursively and removes those that contain no AVI, MKV, or MP4 files anywhere inside them.
#>
function movies-scan {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    $videoExtensions = @('.avi', '.mkv', '.mp4')
    $startPath = (Get-Location).Path

    Get-ChildItem -LiteralPath $startPath -Directory -Recurse |
        Sort-Object FullName -Descending |
        ForEach-Object {
            $folder = $_

            $hasVideo = @(Get-ChildItem -LiteralPath $folder.FullName -File -Recurse -ErrorAction SilentlyContinue |
                Where-Object { $videoExtensions -contains $_.Extension.ToLowerInvariant() }).Count -gt 0

            if (-not $hasVideo) {
                if ($PSCmdlet.ShouldProcess($folder.FullName, 'Delete folder with no video files anywhere inside it')) {
                    Remove-Item -LiteralPath $folder.FullName -Recurse -Force
                    Write-Host "Deleted: $($folder.FullName)"
                }
            }
        }
}
# movies-scan -WhatIf -> Preview which folders would be deleted without actually deleting them.

<#
.SYNOPSIS
Copies readable files from one folder to another and skips broken ones.
#>
function salvage {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$source,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$destination
    )

    if (-not (Test-Path -LiteralPath $source -PathType Container)) {
        throw "Source folder does not exist: $source"
    }

    if (-not (Test-Path -LiteralPath $destination)) {
        New-Item -ItemType Directory -Path $destination -Force | Out-Null
    }

    $source = (Get-Item -LiteralPath $source).FullName.TrimEnd('\')
    $destination = (Get-Item -LiteralPath $destination).FullName.TrimEnd('\')

    $logFile = Join-Path $destination 'salvage_failed.txt'

    if (Test-Path -LiteralPath $logFile) {
        Remove-Item -LiteralPath $logFile -Force
    }

    Get-ChildItem -LiteralPath $source -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
        $relativePath = $_.FullName.Substring($source.Length).TrimStart('\')
        $targetFile = Join-Path $destination $relativePath
        $targetDir = Split-Path -Path $targetFile -Parent

        if (-not (Test-Path -LiteralPath $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }

        try {
            Copy-Item -LiteralPath $_.FullName -Destination $targetFile -Force -ErrorAction Stop
            Write-Host "OK   $relativePath"
        }
        catch {
            Add-Content -Path $logFile -Value $relativePath
            Write-Warning "FAIL $relativePath"
        }
    }
}

<#
.SYNOPSIS
Scans movies in current folder and puts them in folders with the same name as basename.
#>
function move-to-folder {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    $videoExtensions = @('.avi', '.mkv', '.mp4')
    $startPath = (Get-Location).Path

    Get-ChildItem -LiteralPath $startPath -File |
        Where-Object { $videoExtensions -contains $_.Extension.ToLowerInvariant() } |
        ForEach-Object {
            $movieFile = $_
            $targetFolder = Join-Path $startPath $movieFile.BaseName

            if (-not (Test-Path -LiteralPath $targetFolder)) {
                if ($PSCmdlet.ShouldProcess($targetFolder, 'Create movie folder')) {
                    New-Item -ItemType Directory -Path $targetFolder -Force | Out-Null
                }
            }

            Get-ChildItem -LiteralPath $startPath -File |
                Where-Object { $_.BaseName -eq $movieFile.BaseName } |
                ForEach-Object {
                    $targetPath = Join-Path $targetFolder $_.Name

                    if ($_.FullName -eq $targetPath) {
                        return
                    }

                    if ($PSCmdlet.ShouldProcess($_.FullName, "Move to $targetFolder")) {
                        Move-Item -LiteralPath $_.FullName -Destination $targetFolder
                        Write-Host "Moved: $($_.Name) -> $targetFolder"
                    }
                }
        }
}

<#
.SYNOPSIS
Scans video files in the current folder and writes filename and duration to a text file.
#>
function extract-duration {

    [CmdletBinding()]
    param(
        [string]$OutputFile = 'episode_durations.txt'
    )

    if (-not (Get-Command ffprobe -ErrorAction SilentlyContinue)) {
        Write-Host 'ffprobe not found in PATH.'
        return
    }

    $files = Get-ChildItem -File |
        Where-Object { $_.Extension -match '^\.(mp4|mkv|avi|mov|m4v)$' } |
        Sort-Object Name

    if (-not $files) {
        Write-Host 'No video files found.'
        return
    }

    $outputPath = Join-Path (Get-Location) $OutputFile

    $lines = foreach ($file in $files) {
        $seconds = & ffprobe -v error -show_entries format=duration -of csv=p=0 -- "$($file.FullName)" 2>$null

        if ($seconds -match '^\d+(\.\d+)?$') {
            $ts = [TimeSpan]::FromSeconds([math]::Round([double]::Parse($seconds, [System.Globalization.CultureInfo]::InvariantCulture)))
            '{0} | {1:00}:{2:00}:{3:00}' -f $file.Name, [int]$ts.TotalHours, $ts.Minutes, $ts.Seconds
        } else {
            '{0} | ERROR' -f $file.Name
        }
    }

    $lines | Set-Content -LiteralPath $outputPath -Encoding UTF8
    Write-Host "Saved: $outputPath"
}

<#
.SYNOPSIS
Extracts the English subtitle from a video file to an SRT file.
#>
function get-sub {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FileName
    )

    if (-not (Test-Path $FileName)) {
        Write-Error "File not found: $FileName"
        return
    }

    $srtFile = [System.IO.Path]::ChangeExtension($FileName, ".srt")

    ffmpeg -i $FileName -map 0:s:m:language:eng -c:s srt $srtFile
}