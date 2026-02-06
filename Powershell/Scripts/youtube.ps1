<#
.SYNOPSIS
Downloads one YouTube video with best streams and H.264 preference.
#>
function get-youtube {
    param([string]$url)
    if (-not $url) { Write-Warning 'No URL provided'; return }

    yt-dlp `
        --js-runtimes node `
        --windows-filenames `
        --no-playlist `
        --cookies "D:\powershell\yt-dlp\cookies.txt" `
        -S "codec:h264" `
        -f "bv*+ba/b" `
        "$url"
}

<#
.SYNOPSIS
Downloads a YouTube playlist using yt-dlp with safe Windows naming.
#>
function get-playlist {
    param([string]$url)
    if (-not $url) { Write-Warning 'No URL provided'; return }

    yt-dlp `
        --js-runtimes node `
        --windows-filenames `
        --cookies "D:\powershell\yt-dlp\cookies.txt" `
        -S "codec:h264" `
        "$url"
}

<#
.SYNOPSIS
Downloads audio from one YouTube video and converts it to MP3.
#>
function get-mp3 {
    param([string]$url)
    if (-not $url) { Write-Warning 'No URL provided'; return }

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
