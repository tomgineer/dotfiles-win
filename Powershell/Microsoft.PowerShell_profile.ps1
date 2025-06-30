# Tom's PowerShell Profile
# https://github.com/tomgineer/dotfiles-win

# Load Oh My Posh
oh-my-posh init pwsh --config "C:\Users\tom\AppData\Local\Programs\oh-my-posh\themes\jandedobbeleer.omp.json" | Invoke-Expression

# Remove Aliases
Remove-Item Alias:\dir -ErrorAction SilentlyContinue

# Aliases
function dir { eza --icons --group-directories-first @args }
function cdd { Set-Location .. }
function cdr { Set-Location / }

# Git Functions
function gts { git status }
function gta { git add . }
function gtc { git commit -m "$args" }
function gtp { git push origin main }

# Navigation Functions
function lab {
	Set-Location D:\powershell
	eza --icons --group-directories-first
	Write-Host "Welcome to  D:\powershell`n" -ForegroundColor Cyan
}

function ghub {
	Set-Location G:\
	eza --icons --group-directories-first
	Write-Host "Welcome to my  GitHub Projects`n" -ForegroundColor Cyan
}

function hdocs {
	Set-Location E:\xampp\htdocs
	eza --icons --group-directories-first
	Write-Host "Welcome to my  Web Server`n" -ForegroundColor Cyan
}

function mir {
    Set-Location D:\powershell\robocopy
	./menu.ps1
	Write-Host "Welcome to my  Backup Operations`n" -ForegroundColor Cyan
}

# Config Functions
function prof { micro $PROFILE }

# ImageMagick
function makeico {
	param([string]$inputFile)
	if (-not $inputFile) { Write-Warning 'No input received'; return }
	$outputFile = [System.IO.Path]::ChangeExtension($inputFile, '.ico')
	magick "$inputFile" -define icon:auto-resize=256,128,96,64,48,32,24,16 "$outputFile"
}

# Youtube Downloader
function get-youtube {
	param([string]$url)
	if (-not $url) { Write-Warning 'No URL provided'; return }
	yt-dlp --no-playlist --merge-output-format mkv "$url"
}

function get-playlist {
	param([string]$url)
	if (-not $url) { Write-Warning 'No URL provided'; return }
	yt-dlp --yes-playlist --merge-output-format mkv "$url"
}

function get-mp3 {
	param([string]$url)
	if (-not $url) { Write-Warning 'No URL provided'; return }
	yt-dlp --no-playlist -f bestaudio --extract-audio --audio-format mp3 "$url"
}
