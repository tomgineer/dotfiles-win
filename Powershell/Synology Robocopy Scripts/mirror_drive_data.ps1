# Define NAS connection details
$NAS         = '\\synology'
$user        = 'User'
$passwd      = 'Your Password'

# Define local source and NAS destination directories
$source       = 'D:\'
$destination  = '\\synology\drives\data'

# Directories and files to exclude
$excludeDirs  = @('$RECYCLE.BIN', 'System Volume Information')
$excludeFiles = @('pagefile.sys', 'hiberfil.sys', 'swapfile.sys')

# Define log file path
$timestamp  = Get-Date -Format '(dd.MM.yyyy HH-mm-ss)'
$log = "logs/log_drive_data $timestamp.txt"

# Connect to NAS share with credentials (net use is a legacy cmd utility, works here for quick access)
net use $NAS /user:$user $passwd

# Build Robocopy command arguments as an array
$robocopyArgs = @(
    $source
    $destination
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

# Add excluded directories with full paths based on $source
foreach ($dir in $excludeDirs) {
    $robocopyArgs += '/XD'
    $robocopyArgs += (Join-Path $source $dir)
}

# Add excluded files with full paths based on $source
foreach ($file in $excludeFiles) {
    $robocopyArgs += '/XF'
    $robocopyArgs += (Join-Path $source $file)
}

# Run the Robocopy command with the arguments
robocopy @robocopyArgs
