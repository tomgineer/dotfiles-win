# Load
oh-my-posh init pwsh --config "C:\Users\tom\AppData\Local\Programs\oh-my-posh\themes\jandedobbeleer.omp.json" | Invoke-Expression

# Remove Aliases
Remove-Item Alias:\dir -ErrorAction SilentlyContinue

# Aliases
function dir { eza --icons --group-directories-first @args }

# Git Functions
function gts { git status }
function gta { git add . }
function gtc { git commit -m "$args" }
function gtp { git push origin main }

# Navigation Functions
function lab { cd D:\powershell }
function ghub {
	Set-Location G:\
	eza --icons --group-directories-first
}

function mir {
    Set-Location D:\powershell\robocopy
	./menu.ps1
}

# Config Functions
function prof { micro $PROFILE }

# ImageMagick
function makeico {
	$input = $args[0]
	$output = [System.IO.Path]::ChangeExtension($input, ".ico")
    magick $input -define icon:auto-resize=256,128,96,64,48,32,24,16 $output
}

# Youtube Downloader
function get-youtube { yt-dlp --no-playlist --merge-output-format mkv $args[0] }
function get-playlist { yt-dlp --yes-playlist --merge-output-format mkv $args[0] }
function get-mp3 { yt-dlp --no-playlist -f bestaudio --extract-audio --audio-format mp3 $args[0] }
