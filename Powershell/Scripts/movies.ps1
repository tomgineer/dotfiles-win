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