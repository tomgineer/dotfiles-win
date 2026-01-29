# git.ps1
#
# Small Git helper functions for daily work.
# Designed to be dot-sourced from the PowerShell profile.
# All functions wrap common git commands with short names.

# git status
function gts {
    git status
}

# git add .
function gta {
    git add .
}

# git commit -m "<message>"
# Accepts quoted or unquoted messages
function gtc {
    if (-not $args) {
        Write-Warning "Commit message required"
        return
    }

    git commit -m ($args -join ' ')
}

# git push origin main
function gtp {
    git push origin main
}

# Quick workflow:
# status -> add -> commit -> push
# Uses a generic commit message
function gtx {
    git status
    git add .
    git commit -m "Small Fix"
    git push origin main
}

# DANGEROUS:
# Resets the current branch to HEAD and discards ALL local changes.
# This cannot be undone.
function git-reset {
    Write-Warning "This will discard ALL local changes (git reset --hard)"
    Write-Warning "Press Ctrl+C to cancel, or Enter to continue..."

    Read-Host | Out-Null

    git reset --hard
}
