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
        --js-runtimes node `
        --windows-filenames `
        --no-playlist `
        --cookies "D:\powershell\yt-dlp\cookies.txt" `
        -f "bv*+ba/b" `
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
        --js-runtimes node `
        --windows-filenames `
        --cookies "D:\powershell\yt-dlp\cookies.txt" `
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
        --js-runtimes node `
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
    param (
        [Parameter(Mandatory = $true)]
        [string]$Url
    )

    if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
        Write-Host "yt-dlp was not found in PATH." -ForegroundColor Red
        return
    }

    yt-dlp --skip-download --write-subs --sub-lang en --sub-format srt "$Url"
}