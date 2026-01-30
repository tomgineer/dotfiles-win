# mirror.ps1
# Add credentials to Windows Credential Manager (one-time setup):
#   cmdkey /add:bytebunker /user:tom /pass

# ------------------------------------------------------------------------------
# ROBOCOPY MIRROR ENGINE (NAS)
#
# Low-level mirror function for syncing data to the NAS using robocopy /MIR.
#
# - Establishes a temporary connection to the NAS share
# - Performs a destructive mirror (includes deletions on destination)
# - Applies standard system exclusions plus optional extra directories
# - Writes detailed logs for auditing and troubleshooting
#
# WARNING:
# Uses robocopy /MIR. Files deleted at the source will be deleted on the NAS.
# ------------------------------------------------------------------------------
function script:Invoke-RoboMirror {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string]$Destination,

        [Parameter(Mandatory = $true)]
        [string]$LogName,

        [string[]]$ExtraExcludeDirs = @()
    )

    # Define NAS connection details
    $NAS         = '\\bytebunker'
    $User        = 'tom'

    # Read password from env file in the same directory as the script
    $EnvFile = Join-Path $PSScriptRoot 'env'
    $Passwd  = Get-Content -LiteralPath $EnvFile -Raw

    # Log Directory
    $LogDir = 'D:\powershell\.logs'

    # Expanded Directory Exclusions
    $ExcludeDirs  = @(
        '$RECYCLE.BIN',
        'System Volume Information',
        'Temp',
        'Cache',
        'Config.Msi',
        'Package Cache',
        'Windows\Logs'
    )

    # Expanded File Exclusions (Garbage/Lock files)
    $ExcludeFiles = @(
        'pagefile.sys',
        'hiberfil.sys',
        'swapfile.sys',
        '*.tmp',
        '*.log',
        'thumbs.db',
        'desktop.ini',
        '*.lock'
    )

    # Ensure log directory exists
    if (-not (Test-Path -LiteralPath $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir | Out-Null
    }

    # Define log file path
    $timestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
    $log = Join-Path $LogDir "${LogName}_$timestamp.txt"

    # Connect to NAS share with credentials (net use is a legacy cmd utility, works here for quick access)
    net use $NAS /user:$User $Passwd

    # Build Robocopy command arguments as an array
    $robocopyArgs = @(
        $Source
        $Destination
        '/MIR'         # Mirror source to destination (includes deletions)
        '/Z'           # Restartable mode
        '/R:3'         # Retry 3 times on failed copies
        '/W:5'         # Wait 5 seconds between retries
        '/MT:8'        # Use 8 threads (multithreaded copy)
        '/XA:SH'       # Exclude hidden and system files
        '/A-:SH'       # Don't set hidden/system attributes on destination
        '/TEE'         # Output to console and log file
        "/LOG:$log"    # Log file path
    )

    # Process Excluded Directories
    $DirExclusions = @()
    # Add system-style exclusions with full paths
    foreach ($dir in $ExcludeDirs) {
        $DirExclusions += Join-Path $Source $dir
    }

    # Add custom exclusions (like .git)
    if ($ExtraExcludeDirs) {
        $DirExclusions += $ExtraExcludeDirs
    }

    # Wrap paths in double quotes only if they contain spaces
    $DirExclusions = $DirExclusions | ForEach-Object { if ($_ -match ' ') { '"{0}"' -f $_ } else { $_ } }

    # Apply all Directory exclusions under a single /XD flag
    if ($DirExclusions.Count -gt 0) {
        $robocopyArgs += '/XD'
        $robocopyArgs += $DirExclusions
    }

    # Process and apply File exclusions under a single /XF flag
    if ($ExcludeFiles.Count -gt 0) {
        $robocopyArgs += '/XF'
        # Pass the array directly; Robocopy will exclude these filenames
        # wherever they appear within your source directory.
        $robocopyArgs += $ExcludeFiles
    }

    # Display Args
    Write-Host "`n 󰖃 Running Robocopy with arguments:" -ForegroundColor Cyan
    Write-Host "robocopy $($robocopyArgs -join ' ')`n" -ForegroundColor Blue

    robocopy @robocopyArgs
    $rc = $LASTEXITCODE

    if ($rc -ge 8) {
        Write-Error "Robocopy FAILED. Errors occurred during copy. Exit code: $rc`nLog: $log"
    } elseif ($rc -eq 0) {
        Write-Host "Robocopy completed. No changes were needed." -ForegroundColor Green
        Write-Host "Log: $log" -ForegroundColor DarkGray
    } else {
        Write-Host "Robocopy completed successfully with changes." -ForegroundColor Green
        Write-Host "Exit code: $rc | Log: $log" -ForegroundColor DarkGray
    }
}

function mir-data {
    Invoke-RoboMirror `
        -Source 'D:\' `
        -Destination '\\bytebunker\drives\data' `
        -LogName 'log_drive_data'
}

function mir-ai {
    Invoke-RoboMirror `
        -Source 'X:\' `
        -Destination '\\bytebunker\drives\ai' `
        -LogName 'log_drive_ai' `
        -ExtraExcludeDirs @('snapshots', 'tmp', 'cache')
}

function mir-github {
    Invoke-RoboMirror `
        -Source 'G:\' `
        -Destination '\\bytebunker\drives\github' `
        -LogName 'log_drive_github' `
        -ExtraExcludeDirs @('snapshots')
}

function mir-media {
    Invoke-RoboMirror `
        -Source 'M:\' `
        -Destination '\\bytebunker\drives\media' `
        -LogName 'log_drive_media'
}

function mir-webserver {
    Invoke-RoboMirror `
        -Source 'E:\xampp\htdocs' `
        -Destination '\\bytebunker\drives\webserver' `
        -LogName 'log_drive_webserver' `
        -ExtraExcludeDirs @('.git')
}

# ------------------------------------------------------------------------------
# ROBOCOPY LOCAL SYNC / MIRROR ENGINE
#
# Core robocopy wrapper for local filesystem operations.
#
# - Supports copy (non-destructive) and mirror (destructive) modes
# - Used by higher-level helper and menu functions
# - Provides consistent logging, retry logic, and console output
#
# NOTE:
# Mirror mode uses robocopy /MIR and may delete files in the destination.
# ------------------------------------------------------------------------------
function script:Invoke-RoboLocal {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('copy', 'mirror')]
        [string]$Mode, # 'copy' or 'mirror'

        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string]$Destination,

        [Parameter(Mandatory = $true)]
        [string]$LogName,

        [string]$LogDir = 'D:\powershell\.logs'
    )

    if (-not (Test-Path -LiteralPath $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir | Out-Null
    }

    $timestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
    $log = Join-Path $LogDir "${LogName}_$timestamp.txt"

    $commonArgs = @(
        '/Z'           # Restartable mode
        '/R:3'         # Retry 3 times on failed copies
        '/W:5'         # Wait 5 seconds between retries
        '/MT:8'        # Use 8 threads (multithreaded copy)
        '/XA:SH'       # Exclude hidden and system files
        '/A-:SH'       # Don't set hidden/system attributes on destination
        '/TEE'         # Output to console and log file
        "/LOG:$log"    # Log file path
    )

    # Mode-specific options
    $modeArgs = switch ($Mode) {
        'copy'   { @('/S') }     # Copy subdirectories (excluding empty ones)
        'mirror' { @('/MIR') }   # Mirror source to destination
    }

    $robocopyArgs = @(
        $Source
        $Destination
        $modeArgs
        $commonArgs
    )

    robocopy @robocopyArgs
    $rc = $LASTEXITCODE

    if ($rc -ge 8) {
        Write-Error "Robocopy failed (exit code: $rc). Log: $log"
    } else {
        Write-Host "Robocopy finished (exit code: $rc). Log: $log"
    }
}

function mir-ai-media {
    # Forge: txt2img output -> media library
    Invoke-RoboLocal `
        -Mode 'copy' `
        -Source 'X:\apps\forge\webui\outputs\txt2img-images' `
        -Destination 'X:\media\forge' `
        -LogName 'copy_ai_forge'

    # Z-Image: ComfyUI output -> media library
    Invoke-RoboLocal `
        -Mode 'copy' `
        -Source 'X:\apps\comfy_ui\ComfyUI\output\Z-Image' `
        -Destination 'X:\media\z_image' `
        -LogName 'copy_ai_z_image'

    # WAN: outputs -> media library
    Invoke-RoboLocal `
        -Mode 'copy' `
        -Source 'X:\apps\wan2gp\outputs' `
        -Destination 'X:\media\wan' `
        -LogName 'copy_ai_wan'
}

function mir-ext {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string]$Destination,

        [string]$LogName = 'mirror_external'
    )

    Invoke-RoboLocal `
        -Mode 'mirror' `
        -Source $Source `
        -Destination $Destination `
        -LogName $LogName
}

function mir-scripts {
    Invoke-RoboLocal `
        -Mode 'mirror' `
        -Source 'D:\powershell\.scripts' `
        -Destination 'G:\dotfiles-win\Powershell\Scripts' `
        -LogName 'mirror_powershell_scripts'
}

# ------------------------------------------------------------------------------
# MIRROR JOB SELECTOR
#
# Central menu for all mirror operations.
# Run individual jobs or execute all in the defined order.
#
# WARNING:
# Some jobs use /MIR and may delete files on the destination.
# ------------------------------------------------------------------------------
function mir {
    $options = @(
        [PSCustomObject]@{ Name = 'mir-ai-media';   Desc = 'Local sync AI outputs into X:\media (no deletions, local only)';       Action = { mir-ai-media } }
        [PSCustomObject]@{ Name = 'mir-data';       Desc = 'Mirror D:\ to NAS drives\data (includes deletions on destination)';    Action = { mir-data } }
        [PSCustomObject]@{ Name = 'mir-ai';         Desc = 'Mirror X:\ to NAS drives\ai (excludes snapshots/tmp/cache)';           Action = { mir-ai } }
        [PSCustomObject]@{ Name = 'mir-github';     Desc = 'Mirror G:\ to NAS drives\github (excludes snapshots)';                 Action = { mir-github } }
        [PSCustomObject]@{ Name = 'mir-media';      Desc = 'Mirror M:\ to NAS drives\media';                                       Action = { mir-media } }
        [PSCustomObject]@{ Name = 'mir-webserver';  Desc = 'Mirror E:\ to NAS drives\webserver (excludes XAMPP logs/tmp/etc.)';    Action = { mir-webserver } }
    )

    Write-Host ""
    Write-Host "󰑮 Available mirror jobs" -ForegroundColor Cyan
    Write-Host ""

    for ($i = 0; $i -lt $options.Count; $i++) {
        $n = $i + 1
        Write-Host ("{0,2}) " -f $n) -NoNewline -ForegroundColor White
        Write-Host ("{0,-14}  " -f $options[$i].Name) -NoNewline -ForegroundColor Green
        Write-Host $options[$i].Desc -ForegroundColor DarkGray
    }

    $runAllIndex = $options.Count + 1
    Write-Host ""
    Write-Host ("{0,2}) Run All" -f $runAllIndex) -ForegroundColor Cyan
    Write-Host " 0) Exit" -ForegroundColor DarkRed
    Write-Host ""

    $input = Read-Host "Select a number"
    if ($input -eq '0') {
        return
    }

    $choice = 0
    if (-not [int]::TryParse($input, [ref]$choice)) {
        Write-Host "Please enter a number." -ForegroundColor Red
        return
    }

    # Run All
    if ($choice -eq $runAllIndex) {
        Write-Host ""
        Write-Host "Running ALL mirror jobs (in defined order)" -ForegroundColor Cyan
        Write-Host ""

        foreach ($job in $options) {
            Write-Host "Running: $($job.Name)" -ForegroundColor Cyan
            Write-Host "Info:    $($job.Desc)" -ForegroundColor DarkGray
            Write-Host ""
            & $job.Action
        }

        return
    }

    if ($choice -lt 1 -or $choice -gt $options.Count) {
        Write-Host "Invalid choice. Pick 1 to $runAllIndex, or 0 to exit." -ForegroundColor Red
        return
    }

    $selected = $options[$choice - 1]

    Write-Host ""
    Write-Host "Running: $($selected.Name)" -ForegroundColor Cyan
    Write-Host "Info:    $($selected.Desc)" -ForegroundColor DarkGray
    Write-Host ""

    & $selected.Action
}

