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
function gtx {
	git status
	git add .
	git commit -m "Small Fix not worth mentioning.."
	git push origin main
}
function git-restore { git reset --hard}

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

function music {
	Set-Location M:\mp3\renaissance
	eza --icons --group-directories-first
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

function png2ico {
    $pngFiles = Get-ChildItem -Path . -Filter *.png -File
    if ($pngFiles.Count -eq 0) {
        Write-Warning "No PNG files found in the current directory."
        return
    }

    foreach ($file in $pngFiles) {
        $inputFile = $file.FullName
        $outputFile = [System.IO.Path]::ChangeExtension($inputFile, '.ico')
        Write-Host "Converting '$($file.Name)' to '$([System.IO.Path]::GetFileName($outputFile))'..."
        magick "$inputFile" -define icon:auto-resize=256,128,96,64,48,32,24,16 "$outputFile"
    }

    Write-Host "Conversion complete."
}

# Youtube Downloader
function get-youtube {
	param([string]$url)
	if (-not $url) { Write-Warning 'No URL provided'; return }
	yt-dlp --no-playlist --cookies "D:\powershell\yt-dlp\cookies.txt" --remux-video mkv -S "codec:h264" -f "bv*+ba/b" "$url"
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

# Explorer Functions
function open-profile {
	explorer "$HOME\Documents\PowerShell"
}

# File Functions

## Renames all files with the given extension in the current folder using an incremental number and a custom prefix.
## Usage: rename png spaceman
function rename {
	param($Extension, $Prefix)
	$files = Get-ChildItem -Path . -Filter "*.$Extension" -File | Sort-Object Name
	$counter = 1
	foreach ($file in $files) {
		$newName = "$Prefix" + "_" + $counter + "." + $Extension

        if ($file.Name -ne $newName) {
			Write-Host "Renaming '$($file.Name)' to '$newName'"
			Rename-Item -Path $file.FullName -NewName $newName
        }
	$counter++	
	}
}

# Cargo (Rust)
function cr {
	cargo run
}

function cbr {
	cargo build --release	
}

# Mirror To External USB Drive
function mir-ext {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string]$Destination
    )

    # Exclude lists
    $excludeDirs  = @('$RECYCLE.BIN', 'System Volume Information', 'tmp', 'cache')
    $excludeFiles = @('pagefile.sys', 'hiberfil.sys', 'swapfile.sys')

    # Base robocopy args
    $robocopyArgs = @(
        $Source
        $Destination
        '/MIR'
        '/Z'
        '/R:3'
        '/W:5'
        '/MT:8'
        '/XA:SH'
        '/A-:SH'
    )

    # Exclude dirs
    foreach ($dir in $excludeDirs) {
        $robocopyArgs += '/XD'
        $robocopyArgs += (Join-Path $Source $dir)
    }

    # Exclude files
    foreach ($file in $excludeFiles) {
        $robocopyArgs += '/XF'
        $robocopyArgs += (Join-Path $Source $file)
    }

    robocopy @robocopyArgs
}

# Compress current folder (excluding hidden files/folders) into a RAR archive
function rarit {
    $rarExe      = "C:\Program Files\WinRAR\rar.exe"
    $targetDir   = "D:\restore_points"

    if (-not (Test-Path $rarExe)) {
        Write-Error "WinRAR not found at $rarExe"
        return
    }

    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir | Out-Null
    }

    $currentPath = Get-Location
    $folderName  = Split-Path $currentPath -Leaf

    # Suffix: _(dd.mm.yyyy hh-MM-ss)
    $stamp   = Get-Date -Format "dd.MM.yyyy HH-mm-ss"
    $rarName = "${folderName}_($stamp).rar"

    $tmpRar  = Join-Path $currentPath $rarName
    $finalRar = Join-Path $targetDir  $rarName

    # Get non-hidden files & folders from current directory
    $items = Get-ChildItem -Force | Where-Object {
        -not ($_.Attributes -band [System.IO.FileAttributes]::Hidden)
    }

    if (-not $items -or $items.Count -eq 0) {
        Write-Warning "Nothing to compress (no non-hidden items found)."
        return
    }

    Write-Host "Creating archive: $tmpRar" -ForegroundColor Cyan

    & $rarExe a -r -ep1 "$tmpRar" $items.FullName | Out-Null

    if (-not (Test-Path $tmpRar)) {
        Write-Error "Archive creation failed (RAR file not found)."
        return
    }

    Move-Item -Path $tmpRar -Destination $finalRar -Force

    Write-Host "Moved to: $finalRar" -ForegroundColor Green

    explorer $targetDir
}



# Load startup.ps1 from the same directory
. (Join-Path $HOME "Documents\PowerShell\Init_powershell.ps1")
