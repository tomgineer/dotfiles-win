# Fancy PowerShell script menu using Nerd Font icons and colors

Clear-Host
Write-Host "`n󱚞  Tom's Robosync: Reloaded " -ForegroundColor Cyan
Write-Host "`nChoose an option:" -ForegroundColor White
Write-Host ""

Write-Host "0.  󰒲  Do Nothing"                 -ForegroundColor DarkGray
Write-Host "1.    Backup Forge Images"        -ForegroundColor Yellow
Write-Host "2.    Mirror Drive AI" -ForegroundColor Green
Write-Host "3.    Mirror Drive Data"          -ForegroundColor Green
Write-Host "4.    Mirror Drive GitHub"        -ForegroundColor Magenta
Write-Host "5.    Mirror Drive Media"         -ForegroundColor Cyan
Write-Host "6.    Mirror Drive Webserver"     -ForegroundColor DarkCyan
Write-Host "7.    Run All Scripts"            -ForegroundColor Red

$choice = Read-Host "`n󰏗 What do you want to do? (0–7)"

switch ($choice) {
    '0' { Write-Host "`n󰒲 Okay. Doing nothing." -ForegroundColor DarkGray }
    '1' { Write-Host "`n▶ Running backup_forge_images.ps1…" -ForegroundColor Yellow; & ".\backup_forge_images.ps1" }
    '2' { Write-Host "`n▶ Running mirror_drive_ai.ps1…" -ForegroundColor Green; & ".\mirror_drive_ai.ps1" }
    '3' { Write-Host "`n▶ Running mirror_drive_data.ps1…" -ForegroundColor Green; & ".\mirror_drive_data.ps1" }
    '4' { Write-Host "`n▶ Running mirror_drive_github.ps1…" -ForegroundColor Magenta; & ".\mirror_drive_github.ps1" }
    '5' { Write-Host "`n▶ Running mirror_drive_media.ps1…" -ForegroundColor Cyan; & ".\mirror_drive_media.ps1" }
    '6' { Write-Host "`n▶ Running mirror_drive_webserver.ps1…" -ForegroundColor DarkCyan; & ".\mirror_drive_webserver.ps1" }
    '7' { Write-Host "`n▶ Running run_all.ps1…" -ForegroundColor Red; & ".\run_all.ps1" }
    default {
        Write-Host "`n Invalid selection." -ForegroundColor Red
    }
}
