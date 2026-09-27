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
        Write-Host "Setting ARTIST and ALBUMARTIST to '$Artist' → $($file.Name)"

        metaflac `
            --remove-tag=ARTIST `
            --remove-tag=ALBUMARTIST `
            --set-tag=ARTIST="$Artist" `
            --set-tag=ALBUMARTIST="$Artist" `
            "$($file.FullName)"
    }

    Write-Host "Done." -ForegroundColor Green
}

<#
.SYNOPSIS
Sets the ARTIST and ALBUM tags for all .flac files in the current folder.
#>
function setmeta {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Artist,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Title
    )

    $files = Get-ChildItem -File -Filter "*.flac"

    if (-not $files) {
        Write-Warning "No FLAC files found in the current folder."
        return
    }

    foreach ($file in $files) {
        metaflac `
            --remove-tag=ARTIST `
            --remove-tag=ALBUM `
            --set-tag="ARTIST=$Artist" `
            --set-tag="ALBUM=$Title" `
            -- $file.FullName
    }

    Write-Host "Metadata updated for $($files.Count) FLAC file(s)."
    Write-Host "Artist: $Artist"
    Write-Host "Album:  $Title"
}

<#
.SYNOPSIS
Renames FLAC files using track titles from tracks.json and updates their TITLE and TRACKNUMBER tags.
#>
function disc-tracks {

    if (-not (Test-Path "tracks.json")) {
        throw "tracks.json not found."
    }

    # Expected tracks.json format:
    # {
    #   "tracks": [
    #     "First Track",
    #     "Second Track",
    #     "Third Track"
    #   ]
    # }

    $tracks = (Get-Content "tracks.json" -Raw -Encoding UTF8 | ConvertFrom-Json).tracks

    Get-ChildItem "*.flac" | ForEach-Object {

        if ($_.BaseName -notmatch '^(\d+)\s*-\s*') {
            Write-Warning "Skipping '$($_.Name)': no track number."
            return
        }

        $number = [int]$Matches[1]
        $title  = $tracks[$number - 1]

        if (-not $title) {
            Write-Warning "No title found for track $number."
            return
        }

        $safeTitle = ($title -replace '[<>:"/\\|?*]', '-').Trim().TrimEnd('.')
        $track     = '{0:D2}' -f $number
        $newName   = "$track - $safeTitle.flac"

        & metaflac `
            "--remove-tag=TITLE" `
            "--remove-tag=TRACKNUMBER" `
            "--set-tag=TITLE=$title" `
            "--set-tag=TRACKNUMBER=$number" `
            $_.FullName

        if ($LASTEXITCODE -ne 0) {
            throw "metaflac failed for '$($_.Name)'."
        }

        Rename-Item -LiteralPath $_.FullName -NewName $newName

        Write-Host "$track - $title"
    }
}