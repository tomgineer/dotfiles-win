# Tom's PowerShell Profile
# https://github.com/tomgineer/dotfiles-win

# Remove built-in dir alias so custom function can be used
if (Test-Path Alias:dir) {
    Remove-Item Alias:dir -Force
}

# Load Oh My Posh
oh-my-posh init pwsh --config "C:\Users\tom\AppData\Local\Programs\oh-my-posh\themes\jandedobbeleer.omp.json" | Invoke-Expression

# Load Scripts
$ScriptRoot = "D:\powershell\.scripts"

if (Test-Path $ScriptRoot) {
    Get-ChildItem $ScriptRoot -Filter *.ps1 -File | ForEach-Object {
        . $_.FullName
    }
}

# Show available custom functions
hero