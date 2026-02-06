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

# Powershell StartUp
# If locked: Unblock-File $PROFILE
function startup {
    Write-Host ""
    Write-Host " Folders" -ForegroundColor Cyan
    eza --icons --group-directories-first --color=always --git --header
}

# Custom command overview.
# Lists user-defined interactive functions.
# Scans profile and custom scripts directory.
function tools {

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

    Write-Host ""
    Write-Host "󰡱 Available Custom Functions" -ForegroundColor Cyan

    $i = 0
    foreach ($item in $functions) {
        Write-Host "    " -ForegroundColor DarkBlue -NoNewline
        Write-Host ("{0,-20}" -f $item) -ForegroundColor Blue -NoNewline

        $i++
        # Every 5 items, start a new line
        if ($i % 5 -eq 0) { Write-Host "" }
    }

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

# Power off system immediately
function halt {
    shutdown /s /t 0
}

# Displays a table with all available functions in this project (Not Helper Functions) in one column grouped by functionality, in the third column it displays a short explanation what this function does, a second column shows the syntax. The table is nice taking the colors from the function tools and uses nerd fonts.
function info {

    $infoPath = Join-Path $PSScriptRoot ".info"

    if (-not (Test-Path -LiteralPath $infoPath)) {
        Write-Warning "Info table not found: $infoPath"
        return
    }

    Write-Host ""
    Write-Host (Get-Content -LiteralPath $infoPath -Raw) -ForegroundColor Blue -NoNewline
    Write-Host ""
}
