# Set the source directory to back up from and the destination
$source       = 'X:\path1'
$destination  = 'X:\path2'

# Define log file path
$timestamp  = Get-Date -Format '(dd.MM.yyyy HH-mm-ss)'
$log = "logs/log_backup $timestamp.txt"


$robocopyArgs = @(
    $source
    $destination
    '/S'           # Copies subdirectories, but not empty ones
    '/Z'           # Restartable mode
    '/R:3'         # Retry 3 times on failed copies
    '/W:5'         # Wait 5 seconds between retries
    '/MT:8'        # Use 8 threads (multithreaded copy)
    '/XA:SH'       # Exclude hidden and system files
    '/A-:SH'       # Don't set hidden/system attributes on destination
    '/TEE'         # Output to console and log file
    "/LOG:$log"    # Log file path
)


# Run the Robocopy command with the arguments
robocopy @robocopyArgs