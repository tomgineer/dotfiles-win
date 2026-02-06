<#
.SYNOPSIS
Shows the current Git working tree status.
#>
function gts {
    git status
}

<#
.SYNOPSIS
Stages all current changes in the repository.
#>
function gta {
    git add .
}

<#
.SYNOPSIS
Creates a commit using the provided message text.
#>
function gtc {
    if (-not $args) {
        Write-Warning "Commit message required"
        return
    }

    git commit -m ($args -join ' ')
}

<#
.SYNOPSIS
Pushes the current local branch state to origin/main.
#>
function gtp {
    git push origin main
}

<#
.SYNOPSIS
Runs status, add, commit, and push with a default commit message.
#>
function gtx {
    git status
    git add .
    git commit -m "Small Fix"
    git push origin main
}

<#
.SYNOPSIS
Hard-resets the repository to HEAD after a confirmation prompt.
#>
function git-reset {
    Write-Warning "This will discard ALL local changes (git reset --hard)"
    Write-Warning "Press Ctrl+C to cancel, or Enter to continue..."

    Read-Host | Out-Null

    git reset --hard
}
