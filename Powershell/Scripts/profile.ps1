<#
.SYNOPSIS
Opens the current PowerShell profile file in Notepad++.
#>
function profile {
    notepad++ $PROFILE
}

<#
.SYNOPSIS
Reloads the current PowerShell profile into the active session.
#>
function reload {
    . $PROFILE
}

<#
.SYNOPSIS
Opens the folder that contains the current PowerShell profile.
#>
function profile-location {
    explorer (Split-Path $PROFILE)
}
