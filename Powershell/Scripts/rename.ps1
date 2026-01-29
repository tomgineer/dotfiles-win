# rename.ps1
#
# Renames all files with a given extension in the current directory.
# Files are renamed sequentially using an incremental number and a
# user-defined prefix.
#
# Naming format:
#   <Prefix>_<Number>.<Extension>
#
# Example:
#   rename png spaceman
#   Result:
#     spaceman_1.png
#     spaceman_2.png
#     spaceman_3.png
function rename {
	param($Extension, $Prefix)
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