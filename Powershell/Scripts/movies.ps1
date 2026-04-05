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