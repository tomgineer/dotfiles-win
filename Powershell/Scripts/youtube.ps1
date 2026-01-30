# youtube.ps1
#
# Download a single YouTube video (no playlists), merging the best available video and audio streams into an MKV file.
# Uses the Node.js JS runtime and browser cookies to reliably pass YouTube’s JavaScript and anti-bot challenges.
# Enforces Windows-safe filenames and prefers H.264 video for maximum playback compatibility.
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

# Download an entire YouTube playlist and merge each video’s best streams into MKV containers.
# Uses Node.js and cookies to avoid age, region, and challenge-related failures during large playlist downloads.
# Applies Windows-safe filenames and H.264 preference to prevent ffmpeg postprocessing errors.
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

# Download a single YouTube video and extract the best available audio track as an MP3 file.
# Uses Node.js and cookies to ensure stable extraction even for restricted or challenge-protected videos.
# Sanitizes filenames for Windows and avoids playlist downloads to prevent accidental batch processing.
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
