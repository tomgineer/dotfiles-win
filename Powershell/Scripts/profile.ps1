# profile
# Opens the current user profile file ($PROFILE) in Notepad.
function profile {
    notepad $PROFILE
}

# reload
# Reloads the current user profile by dot-sourcing it.
# Useful after editing functions or settings.
function reload {
    . $PROFILE
}

# profile-location
# Opens the PowerShell profile directory in File Explorer.
function profile-location {
    explorer (Split-Path $PROFILE)
}
