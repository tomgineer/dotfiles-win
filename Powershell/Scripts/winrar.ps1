<#
.SYNOPSIS
Archives the current folder contents to a timestamped RAR in restore_points.
#>
function rarit {
    $rarExe      = "C:\Program Files\WinRAR\rar.exe"
    $targetDir   = "D:\restore_points"

    if (-not (Test-Path $rarExe)) {
        Write-Error "WinRAR not found at $rarExe"
        return
    }

    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir | Out-Null
    }

    $currentPath = Get-Location
    $folderName  = Split-Path $currentPath -Leaf

    # Suffix: _(dd.mm.yyyy hh-MM-ss)
    $stamp   = Get-Date -Format "dd.MM.yyyy HH-mm-ss"
    $rarName = "${folderName}_($stamp).rar"

    $tmpRar  = Join-Path $currentPath $rarName
    $finalRar = Join-Path $targetDir  $rarName

    # Get non-hidden files & folders from current directory
    $items = Get-ChildItem -Force | Where-Object {
        -not ($_.Attributes -band [System.IO.FileAttributes]::Hidden)
    }

    if (-not $items -or $items.Count -eq 0) {
        Write-Warning "Nothing to compress (no non-hidden items found)."
        return
    }

    Write-Host "Creating archive: $tmpRar" -ForegroundColor Cyan

    & $rarExe a -r -ep1 "$tmpRar" $items.FullName | Out-Null

    if (-not (Test-Path $tmpRar)) {
        Write-Error "Archive creation failed (RAR file not found)."
        return
    }

    Move-Item -Path $tmpRar -Destination $finalRar -Force

    Write-Host "Moved to: $finalRar" -ForegroundColor Green

    explorer $targetDir
}
