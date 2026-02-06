<#
.SYNOPSIS
Jumps to a predefined folder by short name.
#>
function goto {
    param(
        [Parameter(Position = 0)]
        [string]$Target
    )

    $targets = [ordered]@{
        git     = 'G:\'
        power   = 'D:\powershell'
        icons   = 'G:\iconium\png'
        web     = 'E:\xampp\htdocs'
        scripts = 'G:\dotfiles-win'
        home    = 'D:\'
        profile = "$HOME\Documents\PowerShell"
        comfy   = "C:\Users\tom\Documents\ComfyUI\models"
    }

    # No argument: show targets
    if (-not $Target) {
        Write-Host ""
        Write-Host "󰈔 goto targets" -ForegroundColor Cyan
        Write-Host ""

        foreach ($k in $targets.Keys) {
            Write-Host ("  {0,-10} " -f $k) -NoNewline -ForegroundColor Green
            Write-Host $targets[$k] -ForegroundColor DarkGray
        }

        Write-Host ""
        Write-Host "Usage: goto <target>" -ForegroundColor DarkGray
        Write-Host ""
        return
    }

    $key = $Target.ToLower()

    if (-not $targets.Contains($key)) {
        Write-Warning "Unknown target: $Target"
        Write-Host "Run 'goto' to list available targets." -ForegroundColor DarkGray
        return
    }

    Set-Location $targets[$key]

    Clear-Host
    eza --icons --group-directories-first --color=always --git --header
}
