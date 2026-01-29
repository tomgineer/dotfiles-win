# profile.ps1
#
# Helper functions for working with the PowerShell user profile.
#
# Functions:
# - profile            Opens the current user profile file ($PROFILE) in an editor.
#                      Prefers Notepad++ if available, otherwise falls back to Notepad.
# - reload             Reloads the current user profile by dot-sourcing it.
#                      Useful after editing functions or settings.
# - profile-location   Opens the PowerShell profile directory in File Explorer.

function profile {
    # Attempt to locate Notepad++ in PATH
    $npp = (Get-Command notepad++.exe -ErrorAction SilentlyContinue).Source

    if (-not $npp) {
        Write-Warning "notepad++.exe not found in PATH. Using Notepad instead."
        notepad $PROFILE
        return
    }

    # Open profile in Notepad++
    & $npp $PROFILE
}

function reload {
    # Ensure the profile file exists before reloading
    if (-not (Test-Path -LiteralPath $PROFILE)) {
        Write-Warning "Profile file not found: $PROFILE"
        return
    }

    # Reload profile into the current session
    . $PROFILE
    Write-Host "Reloaded profile: $PROFILE"
}

function profile-location {
    # Open the PowerShell profile directory in File Explorer
    explorer "$HOME\Documents\PowerShell"
}
