# youtube.ps1
#
# Simple yt-dlp helper functions for downloading videos and audio.
# Requires yt-dlp to be installed and available in PATH.

# Download a single YouTube video as MKV (H.264 preferred)
function get-youtube {
    param([string]$url)
    if (-not $url) { Write-Warning 'No URL provided'; return }
    yt-dlp --no-playlist --cookies "D:\powershell\yt-dlp\cookies.txt" --remux-video mkv -S "codec:h264" -f "bv*+ba/b" "$url"
}

# Download an entire playlist as MKV
function get-playlist {
    param([string]$url)
    if (-not $url) { Write-Warning 'No URL provided'; return }
    yt-dlp --yes-playlist --merge-output-format mkv "$url"
}

# Download a single video and extract MP3 audio
function get-mp3 {
    param([string]$url)
    if (-not $url) { Write-Warning 'No URL provided'; return }
    yt-dlp --no-playlist -f bestaudio --extract-audio --audio-format mp3 "$url"
}
