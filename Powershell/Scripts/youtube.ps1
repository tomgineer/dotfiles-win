<#
.SYNOPSIS
Downloads one YouTube video with the highest-quality available streams.
#>
function get-youtube {
    param([string]$url)

    if ([string]::IsNullOrWhiteSpace($url)) {
        Write-Host "Syntax: get-youtube <url>"
        return
    }

    yt-dlp `
        --windows-filenames `
        --no-playlist `
        --cookies "D:\powershell\yt-dlp\cookies.txt" `
        -f "bv*+ba/b" `
        --merge-output-format mp4 `
        "$url"
}

<#
.SYNOPSIS
Downloads a YouTube playlist using yt-dlp with safe Windows naming.
#>
function get-playlist {
    param([string]$url)

    if ([string]::IsNullOrWhiteSpace($url)) {
        Write-Host "Syntax: get-playlist <url>"
        return
    }

    yt-dlp `
        --windows-filenames `
        --yes-playlist `
        --cookies "D:\powershell\yt-dlp\cookies.txt" `
        -f "bv*+ba/b" `
        --merge-output-format mp4 `
        "$url"
}

<#
.SYNOPSIS
Downloads audio from one YouTube video and converts it to MP3.
#>
function get-mp3 {
    param([string]$url)

    if ([string]::IsNullOrWhiteSpace($url)) {
        Write-Host "Syntax: get-mp3 <url>"
        return
    }

    yt-dlp `
        --windows-filenames `
        --no-playlist `
        --cookies "D:\powershell\yt-dlp\cookies.txt" `
        -f "bestaudio/best" `
        --extract-audio `
        --audio-format mp3 `
        "$url"
}

<#
.SYNOPSIS
Downloads English SRT subtitles from a YouTube video.
#>
function get-srt {
    param([string]$url)

    if ([string]::IsNullOrWhiteSpace($url)) {
        Write-Host "Syntax: get-srt <url>"
        return
    }

    yt-dlp `
        --windows-filenames `
        --no-playlist `
        --cookies "D:\powershell\yt-dlp\cookies.txt" `
        --skip-download `
        --write-subs `
        --sub-langs "en.*" `
        --sub-format "srt/vtt/best" `
        --convert-subs srt `
        "$url"
}


<#
.SYNOPSIS
Creates a Tomgineer Audio MP4 video from a TXT file and WAV audio.
#>

<#
.SYNOPSIS
Creates a 1920x1080 Tomgineer Audio MP4 using the ImageMagick layout and an animated FFmpeg waveform.
#>
function make-ttv {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Audio,

        [Parameter(Position = 1)]
        [string]$Txt
    )

    $workDir = 'X:\Factory\Text to Video\Work'

    if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
        throw "FFmpeg was not found in PATH."
    }

    if (-not (Get-Command make-ttv-image -ErrorAction SilentlyContinue)) {
        throw "Function make-ttv-image was not found."
    }

    # Resolve audio
    if (-not [IO.Path]::IsPathRooted($Audio)) {
        $Audio = Join-Path $workDir $Audio
    }

    $audioPath = (Resolve-Path -LiteralPath $Audio -ErrorAction Stop).ProviderPath
    $name = [IO.Path]::GetFileNameWithoutExtension($audioPath)

    # Resolve matching TXT
    if (-not $Txt) {
        $Txt = Join-Path $workDir "$name.txt"
    }
    elseif (-not [IO.Path]::IsPathRooted($Txt)) {
        $Txt = Join-Path $workDir $Txt
    }

    $txtPath = (Resolve-Path -LiteralPath $Txt -ErrorAction Stop).ProviderPath
    $layoutName = [IO.Path]::GetFileNameWithoutExtension($txtPath)

    $imagePath = Join-Path $workDir "${layoutName}_layout.png"
    $output = Join-Path $workDir "$name.mp4"

    # Step 1: Generate static layout
    make-ttv-image $txtPath

    if (-not (Test-Path -LiteralPath $imagePath -PathType Leaf)) {
        throw "Layout image was not created: $imagePath"
    }

    # Step 2: Animated waveform over the layout
$filter = @"
[0:a]asetpts=PTS-STARTPTS,asplit=2[aud][vis];
[vis]aformat=channel_layouts=mono,volume=2,showwaves=s=1120x300:mode=cline:r=30:colors=0xFF922B:scale=cbrt:draw=full,format=rgba,colorkey=0x000000:0.01:0.0[wave];
[1:v]format=rgba[bg];
[bg][wave]overlay=x=700:y=395:shortest=1:format=auto,format=yuv420p[v]
"@

    Write-Host "TTV: $name" -ForegroundColor Cyan
    Write-Host "Audio: $audioPath"
    Write-Host "Layout: $imagePath"
    Write-Host "Output: $output"

    & ffmpeg -hide_banner -y `
        -i $audioPath `
        -loop 1 -framerate 30 -i $imagePath `
        -filter_complex $filter `
        -map "[v]" -map "[aud]" `
        -c:v libx264 -preset veryfast -crf 20 `
        -pix_fmt yuv420p -r 30 `
        -c:a aac -b:a 192k `
        -shortest `
        -movflags +faststart `
        $output

    if ($LASTEXITCODE -ne 0) {
        throw "FFmpeg failed with exit code $LASTEXITCODE."
    }

    Write-Host "Created: $output" -ForegroundColor Green
}

<#
.SYNOPSIS
Creates a 1920x1080 Tomgineer Audio layout image from a TXT file by drawing the wrapped title and subtitle onto background.png using ImageMagick.
#>
function make-ttv-image {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Txt
    )

    $workDir = 'X:\Factory\Text to Video\Work'
    $fontsDir = 'X:\Factory\Text to Video\Fonts'
    $backgroundPath = 'X:\Factory\Text to Video\Backgrounds\background.png'

    $titleFont = Join-Path $fontsDir 'FiraSansExtraCondensed-ExtraBold.ttf'
    $subtitleFont = Join-Path $fontsDir 'FiraSansExtraCondensed-Medium.ttf'

    if (-not (Get-Command magick -ErrorAction SilentlyContinue)) {
        throw "ImageMagick not found."
    }

    foreach ($path in @($titleFont, $subtitleFont, $backgroundPath)) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Required file not found: $path"
        }
    }

    if ([IO.Path]::IsPathRooted($Txt)) {
        $inputPath = $Txt
    }
    else {
        $inputPath = Join-Path $workDir $Txt
    }

    $txtPath = (Resolve-Path -LiteralPath $inputPath -ErrorAction Stop).ProviderPath
    $name = [IO.Path]::GetFileNameWithoutExtension($txtPath)
    $output = Join-Path $workDir "${name}_layout.png"

    $rawLines = [IO.File]::ReadAllLines($txtPath, [Text.Encoding]::UTF8)
    $lines = @(
        $rawLines |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_.Length -gt 0 }
    )

    if ($lines.Count -lt 2) {
        throw "TXT must contain at least 2 non-empty lines: title and subtitle."
    }

    $title = $lines[0]
    $subtitle = $lines[1]

    $id = [guid]::NewGuid().ToString('N')
    $titleFile = ".ttv_${id}_title.txt"
    $subtitleFile = ".ttv_${id}_subtitle.txt"

    $titlePath = Join-Path $workDir $titleFile
    $subtitlePath = Join-Path $workDir $subtitleFile

    $utf8 = [Text.UTF8Encoding]::new($false)

    $titleFontMagick = $titleFont.Replace('\', '/')
    $subtitleFontMagick = $subtitleFont.Replace('\', '/')
    $backgroundMagick = $backgroundPath.Replace('\', '/')

    Push-Location -LiteralPath $workDir

    try {
        [IO.File]::WriteAllText($titlePath, $title, $utf8)
        [IO.File]::WriteAllText($subtitlePath, $subtitle, $utf8)

        & magick -regard-warnings `
            "$backgroundMagick" `
            -resize "1920x1080^" `
            -gravity center `
            -extent 1920x1080 `
            "(" `
                -background none `
                -fill "#FFFFFF" `
                -font "$titleFontMagick" `
                -gravity center `
                -define caption:max-pointsize=72 `
                -size 1240x170 `
                "caption:@$titleFile" `
            ")" `
            -gravity North `
            -geometry "+285+70" `
            -compose Over -composite `
            "(" `
                -background none `
                -fill "#B8BBC1" `
                -font "$subtitleFontMagick" `
                -gravity center `
                -define caption:max-pointsize=40 `
                -size 1260x125 `
                "caption:@$subtitleFile" `
            ")" `
            -gravity North `
            -geometry "+270+250" `
            -compose Over -composite `
            "$output"

        if ($LASTEXITCODE -ne 0) {
            throw "ImageMagick failed with exit code $LASTEXITCODE."
        }

        if (-not (Test-Path -LiteralPath $output)) {
            throw "Output PNG was not created."
        }

        Write-Host "Created: $output" -ForegroundColor Green
        Write-Host "Background: $backgroundPath" -ForegroundColor DarkGray
        Write-Host "Title: $title" -ForegroundColor Cyan
        Write-Host "Subtitle: $subtitle" -ForegroundColor Cyan
    }
    finally {
        Remove-Item -LiteralPath $titlePath, $subtitlePath -ErrorAction SilentlyContinue
        Pop-Location
    }
}
