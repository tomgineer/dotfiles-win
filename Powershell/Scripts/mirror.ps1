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

function script:Invoke-NasCredential {
    $NasServer = 'bytebunker'
    $User      = 'tom'
    $EnvFile   = Join-Path $PSScriptRoot '.env'
    $Passwd    = (Get-Content -LiteralPath $EnvFile -Raw).Trim()

    cmdkey /add:$NasServer /user:$User /pass:$Passwd | Out-Null

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to store credentials for $NasServer as $User. cmdkey exit code: $LASTEXITCODE"
    }
}

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

    # Build Robocopy command arguments as an array
    $robocopyArgs = @(
        $Source
        $Destination
        '/MIR'         # Mirror source to destination (includes deletions)
        '/R:2'         # Retry 2 times on failed copies
        '/W:2'         # Wait 2 seconds between retries
        '/MT:8'        # Use 8 threads (multithreaded copy)
        '/XA:SH'       # Exclude hidden and system files
        '/A-:SH'       # Don't set hidden/system attributes on destination
        '/TEE'         # Output to console and log file
        '/XJD'         # Exclude Junction Points for Directories. (Prevents infinite loops!)
        '/XJF'         # Exclude Junction Points for Files.
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
    Write-Host "`nRunning Robocopy with arguments:" -ForegroundColor Blue
    Write-Host "robocopy $($robocopyArgs -join ' ')`n" -ForegroundColor DarkGray

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

    $commonArgs = @(
        '/R:2'         # Retry 2 times on failed copies
        '/W:2'         # Wait 2 seconds between retries
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

    # Process Excluded Directories (full paths under source)
    $DirExclusions = @()
    foreach ($dir in $ExcludeDirs) {
        $DirExclusions += Join-Path $Source $dir
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
        $robocopyArgs += $ExcludeFiles
    }

    robocopy @robocopyArgs
    $rc = $LASTEXITCODE

    if ($rc -ge 8) {
        Write-Error "Robocopy failed (exit code: $rc). Log: $log"
    } else {
        Write-Host "Robocopy finished (exit code: $rc). Log: $log"
    }
}

<#
.SYNOPSIS
All jobs mirroring data to NAS
#>
function mir-nas {
    Invoke-NasCredential

    $jobs = @(
        @{ Source = 'D:\'; Destination = '\\bytebunker\drives\data'; LogName = 'log_nas_data' }
        @{ Source = 'G:\'; Destination = '\\bytebunker\drives\github'; LogName = 'log_nas_github' }
        @{ Source = 'E:\xampp\htdocs'; Destination = '\\bytebunker\drives\webserver'; LogName = 'log_nas_webserver' }
    )

    foreach ($job in $jobs) {
        $jobLine = "  Running mirror job: $($job.Source) -> $($job.Destination) | 󰧮 $($job.LogName).log "
        $border = ('=' * $jobLine.Length)

        Write-Host ""
        Write-Host $border -ForegroundColor Blue
        Write-Host $jobLine -ForegroundColor White
        Write-Host $border -ForegroundColor Blue

        Invoke-RoboMirror `
            -Source $job.Source `
            -Destination $job.Destination `
            -LogName $job.LogName
    }
}

<#
.SYNOPSIS
All jobs mirroring data to External HDD
#>
function mir-black {
    $jobs = @(
        @{ Mode = 'copy'; Source = 'X:\apps\forge\webui\outputs\txt2img-images'; Destination = 'X:\media\forge'; LogName = 'copy_ai_forge' }
        @{ Mode = 'copy'; Source = 'X:\apps\comfy_ui\ComfyUI\output'; Destination = 'X:\media\comfy_ui'; LogName = 'copy_ai_comfy_ui' }
        @{ Mode = 'copy'; Source = 'X:\apps\wan2gp\outputs'; Destination = 'X:\media\wan'; LogName = 'copy_ai_wan' }
        @{ Mode = 'mirror'; Source = 'D:\'; Destination = 'W:\drives\data'; LogName = 'log_black_data' }
        @{ Mode = 'mirror'; Source = 'G:\'; Destination = 'W:\drives\github'; LogName = 'log_black_github' }
        @{ Mode = 'mirror'; Source = 'M:\'; Destination = 'W:\drives\media'; LogName = 'log_black_media' }
        @{ Mode = 'mirror'; Source = 'E:\xampp\htdocs'; Destination = 'W:\drives\webserver'; LogName = 'log_black_webserver' }
        @{ Mode = 'mirror'; Source = 'X:\'; Destination = 'W:\drives\ai'; LogName = 'log_black_ai' }
    )

    foreach ($job in $jobs) {
        $jobLine = "  Running $($job.Mode) job: $($job.Source) -> $($job.Destination) | 󰧮 $($job.LogName).log "
        $border = ('=' * $jobLine.Length)

        Write-Host ""
        Write-Host $border -ForegroundColor Blue
        Write-Host $jobLine -ForegroundColor White
        Write-Host $border -ForegroundColor Blue

        Invoke-RoboLocal `
            -Mode $job.Mode `
            -Source $job.Source `
            -Destination $job.Destination `
            -LogName $job.LogName
    }
}

<#
.SYNOPSIS
All jobs mirroring data from NAS to External HDD
#>
function mir-backup {
    Invoke-NasCredential

    $jobs = @(
        @{ Mode = 'mirror'; Source = '\\bytebunker\media'; Destination = 'W:\media'; LogName = 'log_backup_media' }
        @{ Mode = 'mirror'; Source = '\\bytebunker\videos'; Destination = 'W:\videos'; LogName = 'log_backup_videos' }
    )

    foreach ($job in $jobs) {
        $jobLine = "  Running $($job.Mode) job: $($job.Source) -> $($job.Destination) | 󰧮 $($job.LogName).log "
        $border = ('=' * $jobLine.Length)

        Write-Host ""
        Write-Host $border -ForegroundColor Blue
        Write-Host $jobLine -ForegroundColor White
        Write-Host $border -ForegroundColor Blue

        Invoke-RoboLocal `
            -Mode $job.Mode `
            -Source $job.Source `
            -Destination $job.Destination `
            -LogName $job.LogName
    }
}

<#
.SYNOPSIS
Mirrors drive D: to the NAS data share.
#>
function mir-data {
    Invoke-NasCredential
    Invoke-RoboMirror `
        -Source 'D:\' `
        -Destination '\\bytebunker\drives\data' `
        -LogName 'log_drive_data'
}

<#
.SYNOPSIS
Mirrors drive G: to the NAS GitHub share.
#>
function mir-github {
    Invoke-NasCredential
    Invoke-RoboMirror `
        -Source 'G:\' `
        -Destination '\\bytebunker\drives\github' `
        -LogName 'log_drive_github' `
        -ExtraExcludeDirs @('snapshots')
}

<#
.SYNOPSIS
Mirrors the local web root to the NAS webserver share.
#>
function mir-webserver {
    Invoke-NasCredential
    Invoke-RoboMirror `
        -Source 'E:\xampp\htdocs' `
        -Destination '\\bytebunker\drives\webserver' `
        -LogName 'log_drive_webserver' `
        -ExtraExcludeDirs @('.git')
}

<#
.SYNOPSIS
Mirrors drive X: to the external hard drive AI folder.
#>
function mir-ai {
    Invoke-RoboMirror `
        -Source 'X:\' `
        -Destination 'W:\drives\ai' `
        -LogName 'log_drive_ai' `
        -ExtraExcludeDirs @('snapshots', 'tmp', 'cache')
}

<#
.SYNOPSIS
Mirrors drive M: to the external hard drive media folder.
#>
function mir-media {
    Invoke-RoboMirror `
        -Source 'M:\' `
        -Destination 'W:\drives\media' `
        -LogName 'log_drive_media'
}

<#
.SYNOPSIS
Mirrors NAS media to the external hard drive media folder.
#>
function mir-nas-media {
    Invoke-NasCredential
    Invoke-RoboMirror `
        -Source '\\bytebunker\media' `
        -Destination 'W:\media' `
        -LogName 'log_drive_nas_media'
}

<#
.SYNOPSIS
Mirrors NAS videos to the external hard drive media folder.
#>
function mir-nas-videos {
    Invoke-NasCredential
    Invoke-RoboMirror `
        -Source '\\bytebunker\videos' `
        -Destination 'W:\videos' `
        -LogName 'log_drive_nas_videos'
}

<#
.SYNOPSIS
Copies AI output folders into the local media library targets.
#>
function mir-ai-media {
    # Forge: txt2img output -> media library
    Invoke-RoboLocal `
        -Mode 'copy' `
        -Source 'X:\apps\forge\webui\outputs\txt2img-images' `
        -Destination 'X:\media\forge' `
        -LogName 'copy_ai_forge'

    # ComfyUI: ComfyUI output -> media library
    Invoke-RoboLocal `
        -Mode 'copy' `
        -Source 'X:\apps\comfy_ui\ComfyUI\output' `
        -Destination 'X:\media\comfy_ui' `
        -LogName 'copy_ai_comfy_ui'

    # WAN: outputs -> media library
    Invoke-RoboLocal `
        -Mode 'copy' `
        -Source 'X:\apps\wan2gp\outputs' `
        -Destination 'X:\media\wan' `
        -LogName 'copy_ai_wan'
}

<#
.SYNOPSIS
Mirrors a custom source path to a custom destination path.
#>
function mir-ext {
    param(
        [string]$Source,

        [string]$Destination,

        [string]$LogName = 'mirror_external'
    )

    if ([string]::IsNullOrWhiteSpace($Source) -or [string]::IsNullOrWhiteSpace($Destination)) {
        Write-Host "Syntax: mir-ext <source> <destination> [log-name]"
        return
    }

    Invoke-NasCredential
    Invoke-RoboLocal `
        -Mode 'mirror' `
        -Source $Source `
        -Destination $Destination `
        -LogName $LogName
}

<#
.SYNOPSIS
Mirrors the PowerShell scripts folder to the dotfiles backup location.
#>
function mir-scripts {
    Invoke-RoboLocal `
        -Mode 'mirror' `
        -Source 'D:\powershell\.scripts' `
        -Destination 'G:\dotfiles-win\Powershell\Scripts' `
        -LogName 'mirror_powershell_scripts'
}

<#
.SYNOPSIS
Shows a menu to run configured mirror jobs.
#>
function mir {
    $groupedOptions = @(
        [PSCustomObject]@{ Header = 'Aggregate Jobs'; Items = @(
            [PSCustomObject]@{ Name = 'mir-nas';        Desc = 'Run all NAS mirror jobs';                                  Action = { mir-nas } }
            [PSCustomObject]@{ Name = 'mir-black';      Desc = 'Run AI copy jobs, then mirror jobs to WD Black';           Action = { mir-black } }
            [PSCustomObject]@{ Name = 'mir-backup';     Desc = 'Mirror NAS media and videos to the external backup drive'; Action = { mir-backup } }
        ) }
        [PSCustomObject]@{ Header = 'Single Jobs'; Items = @(
            [PSCustomObject]@{ Name = 'mir-data';       Desc = 'Mirror D:\ to NAS data share';                             Action = { mir-data } }
            [PSCustomObject]@{ Name = 'mir-github';     Desc = 'Mirror G:\ to NAS GitHub share';                           Action = { mir-github } }
            [PSCustomObject]@{ Name = 'mir-webserver';  Desc = 'Mirror local web root to NAS webserver share';             Action = { mir-webserver } }
            [PSCustomObject]@{ Name = 'mir-ai';         Desc = 'Mirror X:\ to external hard drive AI folder';              Action = { mir-ai } }
            [PSCustomObject]@{ Name = 'mir-media';      Desc = 'Mirror M:\ to external hard drive media folder';           Action = { mir-media } }
            [PSCustomObject]@{ Name = 'mir-nas-media';  Desc = 'Mirror NAS media to the external hard drive';              Action = { mir-nas-media } }
            [PSCustomObject]@{ Name = 'mir-nas-videos'; Desc = 'Mirror NAS videos to the external hard drive';             Action = { mir-nas-videos } }
            [PSCustomObject]@{ Name = 'mir-ai-media';   Desc = 'Copy AI outputs into X:\media without deletions';          Action = { mir-ai-media } }
            [PSCustomObject]@{ Name = 'mir-scripts';    Desc = 'Mirror PowerShell scripts to the dotfiles backup';         Action = { mir-scripts } }
        ) }
    )

    $options = @(
        [PSCustomObject]@{ Name = 'mir-nas';        Desc = 'Run all NAS mirror jobs';                                       Action = { mir-nas } }
        [PSCustomObject]@{ Name = 'mir-black';      Desc = 'Run AI copy jobs, then mirror jobs to WD Black';                Action = { mir-black } }
        [PSCustomObject]@{ Name = 'mir-backup';     Desc = 'Mirror NAS media and videos to the external backup drive';      Action = { mir-backup } }
        [PSCustomObject]@{ Name = 'mir-data';       Desc = 'Mirror D:\ to NAS data share';                                  Action = { mir-data } }
        [PSCustomObject]@{ Name = 'mir-github';     Desc = 'Mirror G:\ to NAS GitHub share';                                Action = { mir-github } }
        [PSCustomObject]@{ Name = 'mir-webserver';  Desc = 'Mirror local web root to NAS webserver share';                  Action = { mir-webserver } }
        [PSCustomObject]@{ Name = 'mir-ai';         Desc = 'Mirror X:\ to external hard drive AI folder';                   Action = { mir-ai } }
        [PSCustomObject]@{ Name = 'mir-media';      Desc = 'Mirror M:\ to external hard drive media folder';                Action = { mir-media } }
        [PSCustomObject]@{ Name = 'mir-nas-media';  Desc = 'Mirror NAS media to the external hard drive';                   Action = { mir-nas-media } }
        [PSCustomObject]@{ Name = 'mir-nas-videos'; Desc = 'Mirror NAS videos to the external hard drive';                  Action = { mir-nas-videos } }
        [PSCustomObject]@{ Name = 'mir-ai-media';   Desc = 'Copy AI outputs into X:\media without deletions';               Action = { mir-ai-media } }
        [PSCustomObject]@{ Name = 'mir-scripts';    Desc = 'Mirror PowerShell scripts to the dotfiles backup';              Action = { mir-scripts } }
    )

    Write-Host ""
    Write-Host "󰑮 Available mirror jobs" -ForegroundColor Cyan
    Write-Host ""

    $menuIndex = 1
    foreach ($group in $groupedOptions) {
        Write-Host $group.Header -ForegroundColor DarkCyan

        foreach ($item in $group.Items) {
            Write-Host (" {0,2}. " -f $menuIndex) -NoNewline -ForegroundColor Gray
            Write-Host ("{0,-26} " -f $item.Name) -NoNewline -ForegroundColor Blue
            Write-Host $item.Desc -ForegroundColor Gray
            $menuIndex++
        }

        Write-Host ""
    }

    Write-Host (" {0,2}. " -f 0) -NoNewline -ForegroundColor Gray
    Write-Host ("{0,-26} " -f 'Cancel') -NoNewline -ForegroundColor Blue
    Write-Host "Exit without running any jobs" -ForegroundColor Gray

    Write-Host ""
    $input = Read-Host "Select a number"

    $choice = -1
    if (-not [int]::TryParse($input, [ref]$choice)) {
        Write-Host "Please enter a number." -ForegroundColor Red
        return
    }

    if ($choice -eq 0) {
        Write-Host ""
        Write-Host "Cancelled." -ForegroundColor DarkGray
        return
    }

    if ($choice -lt 1 -or $choice -gt $options.Count) {
        Write-Host "Invalid choice. Pick 1 to $($options.Count), or 0 to cancel." -ForegroundColor Red
        return
    }

    $selected = $options[$choice - 1]

    Write-Host ""
    Write-Host "Running: $($selected.Name)" -ForegroundColor Cyan
    Write-Host "Info:    $($selected.Desc)" -ForegroundColor DarkGray
    Write-Host ""

    & $selected.Action
}

