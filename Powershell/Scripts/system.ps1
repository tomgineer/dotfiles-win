<#
.SYNOPSIS
Lists directory contents with eza, or falls back to Get-ChildItem.
#>
function dir {
    if (Get-Command eza -ErrorAction SilentlyContinue) {
        eza --icons --group-directories-first --color=always --git --header
    } else {
        Get-ChildItem
    }
}

<#
.SYNOPSIS
Prints the startup folder view with icons and Git metadata.
#>
function startup {
    Write-Host ""
    Write-Host " Folders" -ForegroundColor Cyan
    eza --icons --group-directories-first --color=always --git --header
}

<#
.SYNOPSIS
Displays help for all available tools.
#>
function info {

    $scriptRoot = "D:\powershell\.scripts"

    $functions = Get-Command -CommandType Function |
        Where-Object {
            $_.ScriptBlock.File -and
            (
                $_.ScriptBlock.File -like "$scriptRoot\*" -or
                $_.ScriptBlock.File -eq $PROFILE
            ) -and
            $_.Name -notmatch '^(script:)?Invoke-' -and
            $_.Name -notmatch '^(script:)?_' -and
            $_.Name -notmatch '^(script:)?tools(-ext)?$'
        } |
        Select-Object Name, @{Name = 'FileName'; Expression = { Split-Path $_.ScriptBlock.File -Leaf } }

    if (-not $functions -or $functions.Count -eq 0) {
        Write-Host "(none found)" -ForegroundColor DarkGray
        Write-Host ""
        return
    }

    Write-Host ""
    Write-Host "󰡱 Available Custom Functions" -ForegroundColor Cyan

    $groups = $functions |
        Sort-Object FileName, Name |
        Group-Object -Property FileName

    foreach ($group in $groups) {
        $heading = [System.IO.Path]::GetFileNameWithoutExtension($group.Name)
        if ($heading.Length -gt 0) {
            $heading = $heading.Substring(0, 1).ToUpper() + $heading.Substring(1)
        }

        Write-Host ""
        Write-Host (" {0}" -f $heading) -ForegroundColor Cyan

        foreach ($item in $group.Group) {
            $help = Get-Help -Name $item.Name -ErrorAction SilentlyContinue
            $synopsis = "$($help.Synopsis)".Trim()
            if ([string]::IsNullOrWhiteSpace($synopsis)) {
                $synopsis = "(no synopsis)"
            }

            Write-Host "    " -ForegroundColor DarkBlue -NoNewline
            Write-Host ("{0,-24}" -f $item.Name) -ForegroundColor Blue -NoNewline
            Write-Host "󰛓 " -ForegroundColor Red -NoNewline
            Write-Host $synopsis -ForegroundColor Gray
        }
    }

    Write-Host ""
}

<#
.SYNOPSIS
Counts files with the specified extension in the current folder and all subfolders.
#>
function count {
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Extension
    )

    $Extension = $Extension.Trim().TrimStart(".")
    if ([string]::IsNullOrWhiteSpace($Extension)) {
        throw "Specify a file extension, for example: count pdf"
    }

    $fileCount = (
        Get-ChildItem -LiteralPath . -File -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object Extension -EQ ".$Extension" |
            Measure-Object
    ).Count

    $noun = if ($fileCount -eq 1) { "file" } else { "files" }
    Write-Host "Found " -NoNewline
    Write-Host $fileCount -ForegroundColor Green -NoNewline
    Write-Host " .$Extension $noun."
}

<#
.SYNOPSIS
Rebuilds the Windows icon and thumbnail cache for the current user.
#>
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

<#
.SYNOPSIS
Shuts down Windows immediately without delay.
#>
function halt {
    shutdown /s /t 0
}

<#
.SYNOPSIS
Shows available terminal colors and a truecolor preview.
#>
function colors {
    Write-Host ""
    Write-Host "󰏘 Console Colors (Write-Host)" -ForegroundColor Cyan
    Write-Host ""

    [enum]::GetNames([System.ConsoleColor]) | ForEach-Object {
        Write-Host ("  {0,-12}" -f $_) -ForegroundColor $_
    }

    Write-Host ""
    Write-Host "󰏘 Truecolor Sample" -ForegroundColor Cyan
    Write-Host ""

    if ($PSVersionTable.PSVersion.Major -ge 7) {
        $steps = 12
        for ($i = 0; $i -lt $steps; $i++) {
            $r = [int](255 * $i / ($steps - 1))
            $g = [int](165 * $i / ($steps - 1))
            $b = 0
            Write-Host "$($PSStyle.Background.FromRgb($r, $g, $b))  $($PSStyle.Reset)" -NoNewline
        }
        Write-Host ""
        Write-Host "  Hex example: #FFA500 (orange)" -ForegroundColor DarkGray
    } else {
        Write-Host "  Truecolor preview requires PowerShell 7+." -ForegroundColor DarkGray
    }

    Write-Host ""
}

<#
.SYNOPSIS
Creates a UTF-8 tree.txt file with folders and files.
#>
function make-tree {
    param(
        [string]$Path = ".",
        [string]$OutputFile = "tree.txt"
    )

    $root = Get-Item -LiteralPath $Path

    function Write-Tree {
        param(
            [string]$CurrentPath,
            [string]$Prefix = ""
        )

        $items = Get-ChildItem -LiteralPath $CurrentPath -Force |
            Sort-Object @{ Expression = "PSIsContainer"; Descending = $true }, Name

        for ($i = 0; $i -lt $items.Count; $i++) {
            $item = $items[$i]
            $isLast = $i -eq ($items.Count - 1)

            $branch = if ($isLast) { "+---" } else { "+---" }
            "$Prefix$branch$($item.Name)"

            if ($item.PSIsContainer) {
                $newPrefix = if ($isLast) { "$Prefix    " } else { "$Prefix|   " }
                Write-Tree -CurrentPath $item.FullName -Prefix $newPrefix
            }
        }
    }

    $content = @(
        $root.FullName
        Write-Tree -CurrentPath $root.FullName
    ) -join "`r`n"

    $utf8Bom = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText(
        (Join-Path $root.FullName $OutputFile),
        $content,
        $utf8Bom
    )

    Write-Host "Tree saved to: $(Join-Path $root.FullName $OutputFile)"
}
