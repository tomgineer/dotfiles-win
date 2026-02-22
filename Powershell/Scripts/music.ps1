<#
.SYNOPSIS
Splits folder names containing " - " into parent/child structure.
#>
function splitname {
    param (
        [string]$Separator = " - ",
        [string]$Path = "."
    )

    Get-ChildItem -Path $Path -Directory | ForEach-Object {

        if ($_.Name -match [regex]::Escape($Separator)) {

            $parts = $_.Name -split [regex]::Escape($Separator), 2
            $parent = $parts[0].Trim()
            $child  = $parts[1].Trim()

            if ([string]::IsNullOrWhiteSpace($parent) -or
                [string]::IsNullOrWhiteSpace($child)) {
                return
            }

            $parentPath = Join-Path $Path $parent

            if (!(Test-Path $parentPath)) {
                New-Item -ItemType Directory -Path $parentPath | Out-Null
            }

            $destination = Join-Path $parentPath $child

            if (!(Test-Path $destination)) {
                Move-Item $_.FullName $destination
            }
            else {
                Write-Warning "Skipped '$($_.Name)' → destination exists."
            }
        }
    }
}

<#
.SYNOPSIS
Sets the DISCNUMBER tag for all .flac files in the current folder.
#>
function disc-number {
    param(
        [Parameter(Mandatory=$true)]
        [int]$Number
    )

    $files = Get-ChildItem -Filter *.flac -File

    if (-not $files) {
        Write-Host "No FLAC files found in current folder." -ForegroundColor Yellow
        return
    }

    foreach ($file in $files) {
        Write-Host "Setting DISCNUMBER=$Number → $($file.Name)"
        metaflac --remove-tag=DISCNUMBER --set-tag=DISCNUMBER=$Number "$($file.FullName)"
    }

    Write-Host "Done." -ForegroundColor Green
}

<#
.SYNOPSIS
Sets the ARTIST tag for all .flac files in the current folder.
#>
function disc-artist {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Artist
    )

    $files = Get-ChildItem -Filter *.flac -File

    if (-not $files) {
        Write-Host "No FLAC files found in current folder." -ForegroundColor Yellow
        return
    }

    foreach ($file in $files) {
        Write-Host "Setting ARTIST=$Artist → $($file.Name)"
        metaflac --remove-tag=ARTIST --set-tag=ARTIST="$Artist" "$($file.FullName)"
    }

    Write-Host "Done." -ForegroundColor Green
}