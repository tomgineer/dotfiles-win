<#
.SYNOPSIS
Batch-renames files by extension using a prefix and incrementing number.
#>
function rename {
	param($Extension, $Prefix)
    if ([string]::IsNullOrWhiteSpace($Extension) -or [string]::IsNullOrWhiteSpace($Prefix)) {
        Write-Host "Syntax: rename <extension> <prefix>"
        return
    }

	$files = Get-ChildItem -Path . -Filter "*.$Extension" -File | Sort-Object Name
	$counter = 1
	foreach ($file in $files) {
		$newName = "$Prefix" + "_" + $counter + "." + $Extension

        if ($file.Name -ne $newName) {
			Write-Host "Renaming '$($file.Name)' to '$newName'"
			Rename-Item -Path $file.FullName -NewName $newName
        }
	$counter++
	}
}
