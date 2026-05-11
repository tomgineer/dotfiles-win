<#
.SYNOPSIS
Generates a music.json file from artist and album folders inside the music directory.
#>
function list-music {
    $musicPath = Join-Path (Get-Location) "music"
    $outputFile = Join-Path (Get-Location) "music.json"

    if (-not (Test-Path $musicPath)) {
        Write-Host "The folder 'music' was not found in the current directory." -ForegroundColor Red
        return
    }

    $albums = @()

    Get-ChildItem -Path $musicPath -Directory | ForEach-Object {
        $artistFolder = $_
        $artistName = $artistFolder.Name

        Get-ChildItem -Path $artistFolder.FullName -Directory | ForEach-Object {
            $albumFolder = $_
            $albumName = $albumFolder.Name

            $albums += [PSCustomObject]@{
                artist = $artistName
                album  = $albumName
                format = "CD"
            }
        }
    }

    $albums | ConvertTo-Json -Depth 3 | Set-Content -Path $outputFile -Encoding UTF8

    Write-Host "Created music.json with $($albums.Count) albums." -ForegroundColor Green
}

<#
.SYNOPSIS
Generates a movies.json file from movie folders inside the movies/bluray and movies/dvd directories.
#>
function list-movies {
    $moviesPath = Join-Path (Get-Location) "movies"
    $outputFile = Join-Path (Get-Location) "movies.json"

    if (-not (Test-Path $moviesPath)) {
        Write-Host "The folder 'movies' was not found in the current directory." -ForegroundColor Red
        return
    }

    $movieFolders = @(
        @{
            Path   = Join-Path $moviesPath "bluray"
            Format = "Blu-Ray"
        },
        @{
            Path   = Join-Path $moviesPath "dvd"
            Format = "DVD"
        }
    )

    $movies = @()

    foreach ($movieFolder in $movieFolders) {
        if (-not (Test-Path $movieFolder.Path)) {
            Write-Host "The folder '$($movieFolder.Path)' was not found. Skipping..." -ForegroundColor Yellow
            continue
        }

        Get-ChildItem -Path $movieFolder.Path -Directory | ForEach-Object {
            $movies += [PSCustomObject]@{
                movie  = $_.Name
                format = $movieFolder.Format
            }
        }
    }

    $movies | ConvertTo-Json -Depth 3 | Set-Content -Path $outputFile -Encoding UTF8

    Write-Host "Created movies.json with $($movies.Count) movies." -ForegroundColor Green
}

<#
.SYNOPSIS
Generates a shows.json file from show and season folders inside the shows/bluray and shows/dvd directories.
#>
function list-shows {
    $showsPath = Join-Path (Get-Location) "shows"
    $outputFile = Join-Path (Get-Location) "shows.json"

    if (-not (Test-Path $showsPath)) {
        Write-Host "The folder 'shows' was not found in the current directory." -ForegroundColor Red
        return
    }

    $showFolders = @(
        @{
            Path   = Join-Path $showsPath "bluray"
            Format = "Blu-Ray"
        },
        @{
            Path   = Join-Path $showsPath "dvd"
            Format = "DVD"
        }
    )

    $shows = @()

    foreach ($showFolder in $showFolders) {
        if (-not (Test-Path $showFolder.Path)) {
            Write-Host "The folder '$($showFolder.Path)' was not found. Skipping..." -ForegroundColor Yellow
            continue
        }

        Get-ChildItem -Path $showFolder.Path -Directory | ForEach-Object {
            $seriesFolder = $_
            $showTitle = $seriesFolder.Name

            Get-ChildItem -Path $seriesFolder.FullName -Directory | ForEach-Object {
                $seasonFolder = $_

                $shows += [PSCustomObject]@{
                    show   = $showTitle
                    season = $seasonFolder.Name
                    format = $showFolder.Format
                }
            }
        }
    }

    $shows | ConvertTo-Json -Depth 3 | Set-Content -Path $outputFile -Encoding UTF8

    Write-Host "Created shows.json with $($shows.Count) seasons." -ForegroundColor Green
}

<#
.SYNOPSIS
Runs list-music, list-movies, and list-shows to generate all media JSON files.
#>
function list-all {
    list-music
    list-movies
    list-shows

    Write-Host "Finished generating music.json, movies.json, and shows.json." -ForegroundColor Green
}