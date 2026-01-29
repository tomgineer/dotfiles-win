# mirror.ps1
# Add credentials to Windows Credential Manager (one-time setup):
#   cmdkey /add:bytebunker /user:tom /pass


# Internal helper that mirrors a local source to a NAS destination using Robocopy.
# Uses stored Windows Credential Manager credentials and /MIR (includes deletions).
function script:Invoke-RoboMirror {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string]$Destination,

        [Parameter(Mandatory = $true)]
        [string]$User,

        [Parameter(Mandatory = $true)]
        [string]$LogName,

        [string]$LogDir = 'D:\powershell\robocopy\logs',

        [string[]]$ExcludeDirs = @('$RECYCLE.BIN', 'System Volume Information'),

        [string[]]$ExcludeFiles = @('pagefile.sys', 'hiberfil.sys', 'swapfile.sys'),

        [string[]]$ExtraExcludeDirs = @()
    )

    # Ensure log directory exists
    if (-not (Test-Path -LiteralPath $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir | Out-Null
    }

    $timestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
    $log = Join-Path $LogDir "${LogName}_$timestamp.txt"

    # Connect using stored credentials (no password in script)
    net use $Destination /user:$User | Out-Null

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
        '/TEE'
        "/LOG:$log"
    )

    foreach ($dir in $ExcludeDirs) {
        $robocopyArgs += '/XD'
        $robocopyArgs += (Join-Path $Source $dir)
    }

    foreach ($dir in $ExtraExcludeDirs) {
        $robocopyArgs += '/XD'
        $robocopyArgs += $dir
    }

    foreach ($file in $ExcludeFiles) {
        $robocopyArgs += '/XF'
        $robocopyArgs += (Join-Path $Source $file)
    }

    robocopy @robocopyArgs
    $rc = $LASTEXITCODE

    if ($rc -ge 8) {
        Write-Error "Robocopy failed (exit code: $rc). Log: $log"
    } else {
        Write-Host "Robocopy finished (exit code: $rc). Log: $log"
    }
}

function mir-data {
    Invoke-RoboMirror `
        -Source 'D:\' `
        -Destination '\\bytebunker\drives\data' `
        -User 'tom' `
        -LogName 'log_drive_data'
}

function mir-ai {
    Invoke-RoboMirror `
        -Source 'X:\' `
        -Destination '\\bytebunker\drives\ai' `
        -User 'tom' `
        -LogName 'log_drive_ai' `
        -ExtraExcludeDirs @('snapshots', 'tmp', 'cache')
}

function mir-github {
    Invoke-RoboMirror `
        -Source 'G:\' `
        -Destination '\\bytebunker\drives\github' `
        -User 'tom' `
        -LogName 'log_drive_github' `
        -ExtraExcludeDirs @('snapshots')
}

function mir-media {
    Invoke-RoboMirror `
        -Source 'M:\' `
        -Destination '\\bytebunker\drives\media' `
        -User 'tom' `
        -LogName 'log_drive_media'
}

function mir-webserver {
    Invoke-RoboMirror `
        -Source 'E:\' `
        -Destination '\\bytebunker\drives\webserver' `
        -User 'tom' `
        -LogName 'log_drive_webserver' `
        -ExtraExcludeDirs @(
            'xampp\tmp',
            'xampp\perl\tmp',
            'xampp\apache\logs',
            'xampp\mysql\data\performance_schema'
        )
}

# Internal helper that synchronizes local directories on the same system.
# Uses Robocopy with /S (no deletions) and does not perform any authentication.
function script:Invoke-RoboSyncLocal {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string]$Destination,

        [Parameter(Mandatory = $true)]
        [string]$LogName,

        [string]$LogDir = 'D:\powershell\robocopy\logs'
    )

    if (-not (Test-Path -LiteralPath $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir | Out-Null
    }

    $timestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
    $log = Join-Path $LogDir "${LogName}_$timestamp.txt"

    $robocopyArgs = @(
        $Source
        $Destination
        '/S'           # Copy subdirectories, not empty ones
        '/Z'
        '/R:3'
        '/W:5'
        '/MT:8'
        '/XA:SH'
        '/A-:SH'
        '/TEE'
        "/LOG:$log"
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
    Invoke-RoboSyncLocal `
        -Source 'X:\apps\forge\webui\outputs\txt2img-images' `
        -Destination 'X:\media\forge' `
        -LogName 'sync_ai_forge'

    # Z-Image: ComfyUI output -> media library
    Invoke-RoboSyncLocal `
        -Source 'X:\apps\comfy_ui\ComfyUI\output\Z-Image' `
        -Destination 'X:\media\z_image' `
        -LogName 'sync_ai_z_image'

    # WAN: outputs -> media library
    Invoke-RoboSyncLocal `
        -Source 'X:\apps\wan2gp\outputs' `
        -Destination 'X:\media\wan' `
        -LogName 'sync_ai_wan'
}

# Menu Function
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



