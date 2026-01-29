# system.ps1
#
# File system helper functions.
# Overrides or extends built-in shell behavior.
# Designed for interactive use and dot-sourced at startup.

# Custom directory listing.
# Overrides the built-in 'dir' alias.
# Uses 'eza' when available, falls back to Get-ChildItem.
function dir {
    if (Get-Command eza -ErrorAction SilentlyContinue) {
        eza --icons --group-directories-first --color=always --git --header
    } else {
        Get-ChildItem
    }
}

# Custom command overview.
# Lists user-defined interactive functions.
# Scans profile and custom scripts directory.
function hero {
    Write-Host "󰡱 Available Custom Functions" -ForegroundColor Cyan

    $scriptRoot = "D:\powershell\.scripts"

    $functions = Get-Command -CommandType Function |
        Where-Object {
            $_.ScriptBlock.File -and
            (
                $_.ScriptBlock.File -like "$scriptRoot\*" -or
                $_.ScriptBlock.File -eq $PROFILE
            ) -and
            $_.Name -notmatch '^(script:)?Invoke-' -and
            $_.Name -notmatch '^(script:)?_'   # optional: hide "_private" names if you ever use them
        } |
        Select-Object -ExpandProperty Name |
        Sort-Object

    if (-not $functions -or $functions.Count -eq 0) {
        Write-Host "(none found)" -ForegroundColor DarkGray
        Write-Host ""
        return
    }

    Write-Host ($functions -join "  ") -ForegroundColor Green
    Write-Host ""
}

# Windows icon and thumbnail cache helper.
# Forces a rebuild of per-user icon caches.
# Stops and restarts Explorer to unlock cache files.
function reb-cache {
    Write-Host "Stopping Explorer..." -ForegroundColor Cyan
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue

    Start-Sleep -Seconds 1

    $paths = @(
        "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache*",
        "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache*"
    )

    Write-Host "Deleting icon & thumbnail cache..." -ForegroundColor Cyan
    foreach ($path in $paths) {
        Remove-Item $path -Force -ErrorAction SilentlyContinue
    }

    Write-Host "Starting Explorer..." -ForegroundColor Cyan
    Start-Process explorer.exe

    Write-Host "Icon cache rebuild triggered." -ForegroundColor Green
}
