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

<#
.SYNOPSIS
Splits folder names containing " - " into parent/child structure.
#>
function splitname {
    param (
        [string]$Separator = " - ",
        [string]$Path = "."
    )

    Get-ChildItem -Path $Path -Directory | ForEach-Object {

        if ($_.Name -match [regex]::Escape($Separator)) {

            $parts = $_.Name -split [regex]::Escape($Separator), 2
            $parent = $parts[0].Trim()
            $child  = $parts[1].Trim()

            if ([string]::IsNullOrWhiteSpace($parent) -or
                [string]::IsNullOrWhiteSpace($child)) {
                return
            }

            $parentPath = Join-Path $Path $parent

            if (!(Test-Path $parentPath)) {
                New-Item -ItemType Directory -Path $parentPath | Out-Null
            }

            $destination = Join-Path $parentPath $child

            if (!(Test-Path $destination)) {
                Move-Item $_.FullName $destination
            }
            else {
                Write-Warning "Skipped '$($_.Name)' → destination exists."
            }
        }
    }
}