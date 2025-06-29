# Load 
oh-my-posh init pwsh --config "C:\Users\tom\AppData\Local\Programs\oh-my-posh\themes\jandedobbeleer.omp.json" | Invoke-Expression

# Remove Aliases
Remove-Item Alias:\dir -ErrorAction SilentlyContinue

# Aliases
function dir { eza --icons --group-directories-first @args }

# Git Functions
function gts { git status }
function gta { git add . }
function gtc { git commit -m "$args" }
function gtp { git push origin main }

# Navigation Functions
function lab { cd D:\powershell }
function github { cd G:\ }

# Config Functions
function prof { micro $PROFILE }
