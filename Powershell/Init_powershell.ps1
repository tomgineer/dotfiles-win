function Init-Powershell {
	Write-Host "󰡱 Available Custom Functions" -ForegroundColor Cyan
	
	# List Custom Functions
        $profilePath = $PROFILE
		$functions = Get-Command -CommandType Function |
			Where-Object { $_.ScriptBlock.File -eq $profilePath } |
			Select-Object -ExpandProperty Name |
			Sort-Object

		$functions -join "  "
		Write-Host ""
}

Init-Powershell
